// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';
import 'package:process/process.dart';
import 'package:vm_service/vm_service.dart' as vm_service;

import '../application_package.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/io.dart';
import '../base/logger.dart';
import '../base/os.dart';
import '../base/platform.dart';
import '../base/utils.dart';
import '../build_info.dart';
import '../convert.dart';
import '../device.dart';
import '../device_port_forwarder.dart';
import '../globals.dart' as globals;
import '../macos/xcdevice.dart';
import '../mdns_discovery.dart';
import '../project.dart';
import '../protocol_discovery.dart';
import '../vmservice.dart';
import 'application_package.dart';
import 'ios_deploy.dart';
import 'ios_workflow.dart';
import 'iproxy.dart';
import 'mac.dart';

class IOSDevices extends PollingDeviceDiscovery {
  IOSDevices({
    required Platform platform,
    required this.xcdevice,
    required IOSWorkflow iosWorkflow,
    required Logger logger,
  }) : _platform = platform,
       _iosWorkflow = iosWorkflow,
       _logger = logger,
       super('iOS devices');

  final Platform _platform;
  final IOSWorkflow _iosWorkflow;
  final Logger _logger;

  @visibleForTesting
  final XCDevice xcdevice;

  @override
  bool get supportsPlatform => _platform.isMacOS;

  @override
  bool get canListAnything => _iosWorkflow.canListDevices;

  @override
  bool get requiresExtendedWirelessDeviceDiscovery => true;

  StreamSubscription<XCDeviceEventNotification>? _observedDeviceEventsSubscription;

  /// Cache for all devices found by `xcdevice list`, including not connected
  /// devices. Used to minimize the need to call `xcdevice list`.
  ///
  /// Separate from `deviceNotifier` since `deviceNotifier` should only contain
  /// connected devices.
  final Map<String, IOSDevice> _cachedPolledDevices = <String, IOSDevice>{};

  /// Maps device id to a map of the device's observed connections. When the
  /// mapped connection is `true`, that means that observed events indicated
  /// the device is connected via that particular interface.
  ///
  /// The device id must be missing from the map or both interfaces must be
  /// false for the device to be considered disconnected.
  ///
  /// Example:
  /// {
  ///   device-id: {
  ///     usb: false,
  ///     wifi: false,
  ///   },
  /// }
  final Map<String, Map<XCDeviceEventInterface, bool>> _observedConnectionsByDeviceId =
      <String, Map<XCDeviceEventInterface, bool>>{};

  @override
  Future<void> startPolling() async {
    if (!_platform.isMacOS) {
      throw UnsupportedError(
        'Control of iOS devices or simulators only supported on macOS.'
      );
    }
    if (!xcdevice.isInstalled) {
      return;
    }

    deviceNotifier ??= ItemListNotifier<Device>();

    // Start by populating all currently attached devices.
    _updateCachedDevices(await pollingGetDevices());
    _updateNotifierFromCache();

    // cancel any outstanding subscriptions.
    await _observedDeviceEventsSubscription?.cancel();
    _observedDeviceEventsSubscription = xcdevice.observedDeviceEvents()?.listen(
      onDeviceEvent,
      onError: (Object error, StackTrace stack) {
        _logger.printTrace('Process exception running xcdevice observe:\n$error\n$stack');
      }, onDone: () {
        // If xcdevice is killed or otherwise dies, polling will be stopped.
        // No retry is attempted and the polling client will have to restart polling
        // (restart the IDE). Avoid hammering on a process that is
        // continuously failing.
        _logger.printTrace('xcdevice observe stopped');
      },
      cancelOnError: true,
    );
  }

  @visibleForTesting
  Future<void> onDeviceEvent(XCDeviceEventNotification event) async {
    final ItemListNotifier<Device>? notifier = deviceNotifier;
    if (notifier == null) {
      return;
    }
    Device? knownDevice;
    for (final Device device in notifier.items) {
      if (device.id == event.deviceIdentifier) {
        knownDevice = device;
      }
    }

    final Map<XCDeviceEventInterface, bool> deviceObservedConnections =
        _observedConnectionsByDeviceId[event.deviceIdentifier] ??
            <XCDeviceEventInterface, bool>{
              XCDeviceEventInterface.usb: false,
              XCDeviceEventInterface.wifi: false,
            };

    if (event.eventType == XCDeviceEvent.attach) {
      // Update device's observed connections.
      deviceObservedConnections[event.eventInterface] = true;
      _observedConnectionsByDeviceId[event.deviceIdentifier] = deviceObservedConnections;

      // If device was not already in notifier, add it.
      if (knownDevice == null) {
        if (_cachedPolledDevices[event.deviceIdentifier] == null) {
          // If device is not found in cache, there's no way to get details
          // for an individual attached device, so repopulate them all.
          _updateCachedDevices(await pollingGetDevices());
        }
        _updateNotifierFromCache();
      }
    } else {
      // Update device's observed connections.
      deviceObservedConnections[event.eventInterface] = false;
      _observedConnectionsByDeviceId[event.deviceIdentifier] = deviceObservedConnections;

      // If device is in the notifier and does not have other observed
      // connections, remove it.
      if (knownDevice != null &&
          !_deviceHasObservedConnection(deviceObservedConnections)) {
        notifier.removeItem(knownDevice);
      }
    }
  }

  /// Adds or updates devices in cache. Does not remove devices from cache.
  void _updateCachedDevices(List<Device> devices) {
    for (final Device device in devices) {
      if (device is! IOSDevice) {
        continue;
      }
      _cachedPolledDevices[device.id] = device;
    }
  }

  /// Updates notifier with devices found in the cache that are determined
  /// to be connected.
  void _updateNotifierFromCache() {
    final ItemListNotifier<Device>? notifier = deviceNotifier;
    if (notifier == null) {
      return;
    }
    // Device is connected if it has either an observed usb or wifi connection
    // or it has not been observed but was found as connected in the cache.
    final List<Device> connectedDevices = _cachedPolledDevices.values.where((Device device) {
      final Map<XCDeviceEventInterface, bool>? deviceObservedConnections =
          _observedConnectionsByDeviceId[device.id];
      return (deviceObservedConnections != null &&
              _deviceHasObservedConnection(deviceObservedConnections)) ||
          (deviceObservedConnections == null && device.isConnected);
    }).toList();

    notifier.updateWithNewList(connectedDevices);
  }

  bool _deviceHasObservedConnection(
    Map<XCDeviceEventInterface, bool> deviceObservedConnections,
  ) {
    return (deviceObservedConnections[XCDeviceEventInterface.usb] ?? false) ||
        (deviceObservedConnections[XCDeviceEventInterface.wifi] ?? false);
  }

  @override
  Future<void> stopPolling() async {
    await _observedDeviceEventsSubscription?.cancel();
  }

  @override
  Future<List<Device>> pollingGetDevices({ Duration? timeout }) async {
    if (!_platform.isMacOS) {
      throw UnsupportedError(
        'Control of iOS devices or simulators only supported on macOS.'
      );
    }

    return xcdevice.getAvailableIOSDevices(timeout: timeout);
  }

  Future<Device?> waitForDeviceToConnect(
    IOSDevice device,
    Logger logger,
  ) async {
    final XCDeviceEventNotification? eventDetails =
        await xcdevice.waitForDeviceToConnect(device.id);

    if (eventDetails != null) {
      device.isConnected = true;
      device.connectionInterface = eventDetails.eventInterface.connectionInterface;
      return device;
    }
    return null;
  }

  void cancelWaitForDeviceToConnect() {
    xcdevice.cancelWaitForDeviceToConnect();
  }

  @override
  Future<List<String>> getDiagnostics() async {
    if (!_platform.isMacOS) {
      return const <String>[
        'Control of iOS devices or simulators only supported on macOS.',
      ];
    }

    return xcdevice.getDiagnostics();
  }

  @override
  List<String> get wellKnownIds => const <String>[];
}

class IOSDevice extends Device {
  IOSDevice(super.id, {
    required FileSystem fileSystem,
    required this.name,
    required this.cpuArchitecture,
    required this.connectionInterface,
    required this.isConnected,
    required this.devModeEnabled,
    String? sdkVersion,
    required Platform platform,
    required IOSDeploy iosDeploy,
    required IMobileDevice iMobileDevice,
    required IProxy iProxy,
    required Logger logger,
  })
    : _sdkVersion = sdkVersion,
      _iosDeploy = iosDeploy,
      _iMobileDevice = iMobileDevice,
      _iproxy = iProxy,
      _fileSystem = fileSystem,
      _logger = logger,
      _platform = platform,
        super(
          category: Category.mobile,
          platformType: PlatformType.ios,
          ephemeral: true,
      ) {
    if (!_platform.isMacOS) {
      assert(false, 'Control of iOS devices or simulators only supported on Mac OS.');
      return;
    }
  }

  final String? _sdkVersion;
  final IOSDeploy _iosDeploy;
  final FileSystem _fileSystem;
  final Logger _logger;
  final Platform _platform;
  final IMobileDevice _iMobileDevice;
  final IProxy _iproxy;

  /// May be 0 if version cannot be parsed.
  int get majorSdkVersion {
    final String? majorVersionString = _sdkVersion?.split('.').first.trim();
    return majorVersionString != null ? int.tryParse(majorVersionString) ?? 0 : 0;
  }

  @override
  final String name;

  @override
  bool supportsRuntimeMode(BuildMode buildMode) => buildMode != BuildMode.jitRelease;

  final DarwinArch cpuArchitecture;

  @override
  /// The [connectionInterface] provided from `XCDevice.getAvailableIOSDevices`
  /// may not be accurate. Sometimes if it doesn't have a long enough time
  /// to connect, wireless devices will have an interface of `usb`/`attached`.
  /// This may change after waiting for the device to connect in
  /// `waitForDeviceToConnect`.
  DeviceConnectionInterface connectionInterface;

  @override
  bool isConnected;

  final Map<IOSApp?, DeviceLogReader> _logReaders = <IOSApp?, DeviceLogReader>{};

  DevicePortForwarder? _portForwarder;

  bool devModeEnabled = false;

  @visibleForTesting
  IOSDeployDebugger? iosDeployDebugger;

  @override
  Future<bool> get isLocalEmulator async => false;

  @override
  Future<String?> get emulatorId async => null;

  @override
  bool get supportsStartPaused => false;

  @override
  Future<bool> isAppInstalled(
    ApplicationPackage app, {
    String? userIdentifier,
  }) async {
    bool result;
    try {
      result = await _iosDeploy.isAppInstalled(
        bundleId: app.id,
        deviceId: id,
      );
    } on ProcessException catch (e) {
      _logger.printError(e.message);
      return false;
    }
    return result;
  }

  @override
  Future<bool> isLatestBuildInstalled(ApplicationPackage app) async => false;

  @override
  Future<bool> installApp(
    covariant IOSApp app, {
    String? userIdentifier,
  }) async {
    final Directory bundle = _fileSystem.directory(app.deviceBundlePath);
    if (!bundle.existsSync()) {
      _logger.printError('Could not find application bundle at ${bundle.path}; have you run "flutter build ios"?');
      return false;
    }

    int installationResult;
    try {
      installationResult = await _iosDeploy.installApp(
        deviceId: id,
        bundlePath: bundle.path,
        appDeltaDirectory: app.appDeltaDirectory,
        launchArguments: <String>[],
        interfaceType: connectionInterface,
      );
    } on ProcessException catch (e) {
      _logger.printError(e.message);
      return false;
    }
    if (installationResult != 0) {
      _logger.printError('Could not install ${bundle.path} on $id.');
      _logger.printError('Try launching Xcode and selecting "Product > Run" to fix the problem:');
      _logger.printError('  open ios/Runner.xcworkspace');
      _logger.printError('');
      return false;
    }
    return true;
  }

  @override
  Future<bool> uninstallApp(
    ApplicationPackage app, {
    String? userIdentifier,
  }) async {
    int uninstallationResult;
    try {
      uninstallationResult = await _iosDeploy.uninstallApp(
        deviceId: id,
        bundleId: app.id,
      );
    } on ProcessException catch (e) {
      _logger.printError(e.message);
      return false;
    }
    if (uninstallationResult != 0) {
      _logger.printError('Could not uninstall ${app.id} on $id.');
      return false;
    }
    return true;
  }

  @override
  // 32-bit devices are not supported.
  bool isSupported() => cpuArchitecture == DarwinArch.arm64;

  @override
  Future<LaunchResult> startApp(
    IOSApp package, {
    String? mainPath,
    String? route,
    required DebuggingOptions debuggingOptions,
    Map<String, Object?> platformArgs = const <String, Object?>{},
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
    @visibleForTesting Duration? discoveryTimeout,
  }) async {
    String? packageId;
    if (isWirelesslyConnected &&
        debuggingOptions.debuggingEnabled &&
        debuggingOptions.disablePortPublication) {
      throwToolExit('Cannot start app on wirelessly tethered iOS device. Try running again with the --publish-port flag');
    }
    if (!prebuiltApplication) {
      _logger.printTrace('Building ${package.name} for $id');

      // Step 1: Build the precompiled/DBC application if necessary.
      final XcodeBuildResult buildResult = await buildXcodeProject(
          app: package as BuildableIOSApp,
          buildInfo: debuggingOptions.buildInfo,
          targetOverride: mainPath,
          activeArch: cpuArchitecture,
          deviceID: id,
      );
      if (!buildResult.success) {
        _logger.printError('Could not build the precompiled application for the device.');
        await diagnoseXcodeBuildFailure(buildResult, globals.flutterUsage, _logger);
        _logger.printError('');
        return LaunchResult.failed();
      }
      packageId = buildResult.xcodeBuildExecution?.buildSettings[IosProject.kProductBundleIdKey];
    }

    packageId ??= package.id;

    // Step 2: Check that the application exists at the specified path.
    final Directory bundle = _fileSystem.directory(package.deviceBundlePath);
    if (!bundle.existsSync()) {
      _logger.printError('Could not find the built application bundle at ${bundle.path}.');
      return LaunchResult.failed();
    }

    // Step 3: Attempt to install the application on the device.
    final List<String> launchArguments = debuggingOptions.getIOSLaunchArguments(
      EnvironmentType.physical,
      route,
      platformArgs,
      ipv6: ipv6,
      interfaceType: connectionInterface,
    );
    Status startAppStatus = _logger.startProgress(
      'Installing and launching...',
    );
    try {
      ProtocolDiscovery? vmServiceDiscovery;
      int installationResult = 1;
      if (debuggingOptions.debuggingEnabled) {
        _logger.printTrace('Debugging is enabled, connecting to vmService');
        final DeviceLogReader deviceLogReader = getLogReader(
          app: package,
          usingCISystem: debuggingOptions.usingCISystem,
        );

        // If the device supports syslog reading, prefer launching the app without
        // attaching the debugger to avoid the overhead of the unnecessary extra running process.
        if (majorSdkVersion >= IOSDeviceLogReader.minimumUniversalLoggingSdkVersion) {
          iosDeployDebugger = _iosDeploy.prepareDebuggerForLaunch(
            deviceId: id,
            bundlePath: bundle.path,
            appDeltaDirectory: package.appDeltaDirectory,
            launchArguments: launchArguments,
            interfaceType: connectionInterface,
            uninstallFirst: debuggingOptions.uninstallFirst,
          );
          if (deviceLogReader is IOSDeviceLogReader) {
            deviceLogReader.debuggerStream = iosDeployDebugger;
          }
        }
        // Don't port foward if debugging with a wireless device.
        vmServiceDiscovery = ProtocolDiscovery.vmService(
          deviceLogReader,
          portForwarder: isWirelesslyConnected ? null : portForwarder,
          hostPort: debuggingOptions.hostVmServicePort,
          devicePort: debuggingOptions.deviceVmServicePort,
          ipv6: ipv6,
          logger: _logger,
        );
      }
      if (iosDeployDebugger == null) {
        installationResult = await _iosDeploy.launchApp(
          deviceId: id,
          bundlePath: bundle.path,
          appDeltaDirectory: package.appDeltaDirectory,
          launchArguments: launchArguments,
          interfaceType: connectionInterface,
          uninstallFirst: debuggingOptions.uninstallFirst,
        );
      } else {
        installationResult = await iosDeployDebugger!.launchAndAttach() ? 0 : 1;
      }
      if (installationResult != 0) {
        _logger.printError('Could not run ${bundle.path} on $id.');
        _logger.printError('Try launching Xcode and selecting "Product > Run" to fix the problem:');
        _logger.printError('  open ios/Runner.xcworkspace');
        _logger.printError('');
        await dispose();
        return LaunchResult.failed();
      }

      if (!debuggingOptions.debuggingEnabled) {
        return LaunchResult.succeeded();
      }

      _logger.printTrace('Application launched on the device. Waiting for Dart VM Service url.');

      final int defaultTimeout = isWirelesslyConnected ? 45 : 30;
      final Timer timer = Timer(discoveryTimeout ?? Duration(seconds: defaultTimeout), () {
        _logger.printError('The Dart VM Service was not discovered after $defaultTimeout seconds. This is taking much longer than expected...');

        // If debugging with a wireless device and the timeout is reached, remind the
        // user to allow local network permissions.
        if (isWirelesslyConnected) {
          _logger.printError(
            '\nClick "Allow" to the prompt asking if you would like to find and connect devices on your local network. '
            'This is required for wireless debugging. If you selected "Don\'t Allow", '
            'you can turn it on in Settings > Your App Name > Local Network. '
            "If you don't see your app in the Settings, uninstall the app and rerun to see the prompt again."
          );
        } else {
          iosDeployDebugger?.checkForSymbolsFiles(_fileSystem);
          iosDeployDebugger?.pauseDumpBacktraceResume();
        }
      });

      Uri? localUri;
      if (isWirelesslyConnected) {
        // Wait for Dart VM Service to start up.
        final Uri? serviceURL = await vmServiceDiscovery?.uri;
        if (serviceURL == null) {
          await iosDeployDebugger?.stopAndDumpBacktrace();
          await dispose();
          return LaunchResult.failed();
        }

        // If Dart VM Service URL with the device IP is not found within 5 seconds,
        // change the status message to prompt users to click Allow. Wait 5 seconds because it
        // should only show this message if they have not already approved the permissions.
        // MDnsVmServiceDiscovery usually takes less than 5 seconds to find it.
        final Timer mDNSLookupTimer = Timer(const Duration(seconds: 5), () {
          startAppStatus.stop();
          startAppStatus = _logger.startProgress(
            'Waiting for approval of local network permissions...',
          );
        });

        // Get Dart VM Service URL with the device IP as the host.
        localUri = await MDnsVmServiceDiscovery.instance!.getVMServiceUriForLaunch(
          packageId,
          this,
          usesIpv6: ipv6,
          deviceVmservicePort: serviceURL.port,
          useDeviceIPAsHost: true,
        );

        mDNSLookupTimer.cancel();
      } else {
        localUri = await vmServiceDiscovery?.uri;
      }
      timer.cancel();
      if (localUri == null) {
        await iosDeployDebugger?.stopAndDumpBacktrace();
        await dispose();
        return LaunchResult.failed();
      }
      return LaunchResult.succeeded(vmServiceUri: localUri);
    } on ProcessException catch (e) {
      await iosDeployDebugger?.stopAndDumpBacktrace();
      _logger.printError(e.message);
      await dispose();
      return LaunchResult.failed();
    } finally {
      startAppStatus.stop();
    }
  }

  @override
  Future<bool> stopApp(
    ApplicationPackage? app, {
    String? userIdentifier,
  }) async {
    // If the debugger is not attached, killing the ios-deploy process won't stop the app.
    final IOSDeployDebugger? deployDebugger = iosDeployDebugger;
    if (deployDebugger != null && deployDebugger.debuggerAttached) {
      return deployDebugger.exit();
    }
    return false;
  }

  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  Future<String> get sdkNameAndVersion async => 'iOS ${_sdkVersion ?? 'unknown version'}';

  @override
  DeviceLogReader getLogReader({
    covariant IOSApp? app,
    bool includePastLogs = false,
    bool usingCISystem = false,
  }) {
    assert(!includePastLogs, 'Past log reading not supported on iOS devices.');
    return _logReaders.putIfAbsent(app, () => IOSDeviceLogReader.create(
      device: this,
      app: app,
      iMobileDevice: _iMobileDevice,
      usingCISystem: usingCISystem,
    ));
  }

  @visibleForTesting
  void setLogReader(IOSApp app, DeviceLogReader logReader) {
    _logReaders[app] = logReader;
  }

  @override
  DevicePortForwarder get portForwarder => _portForwarder ??= IOSDevicePortForwarder(
    logger: _logger,
    iproxy: _iproxy,
    id: id,
    operatingSystemUtils: globals.os,
  );

  @visibleForTesting
  set portForwarder(DevicePortForwarder forwarder) {
    _portForwarder = forwarder;
  }

  @override
  void clearLogs() { }

  @override
  bool get supportsScreenshot => _iMobileDevice.isInstalled;

  @override
  Future<void> takeScreenshot(File outputFile) async {
    await _iMobileDevice.takeScreenshot(outputFile, id, connectionInterface);
  }

  @override
  bool isSupportedForProject(FlutterProject flutterProject) {
    return flutterProject.ios.existsSync();
  }

  @override
  Future<void> dispose() async {
    for (final DeviceLogReader logReader in _logReaders.values) {
      logReader.dispose();
    }
    _logReaders.clear();
    await _portForwarder?.dispose();
  }
}

/// Decodes a vis-encoded syslog string to a UTF-8 representation.
///
/// Apple's syslog logs are encoded in 7-bit form. Input bytes are encoded as follows:
/// 1. 0x00 to 0x19: non-printing range. Some ignored, some encoded as <...>.
/// 2. 0x20 to 0x7f: as-is, with the exception of 0x5c (backslash).
/// 3. 0x5c (backslash): octal representation \134.
/// 4. 0x80 to 0x9f: \M^x (using control-character notation for range 0x00 to 0x40).
/// 5. 0xa0: octal representation \240.
/// 6. 0xa1 to 0xf7: \M-x (where x is the input byte stripped of its high-order bit).
/// 7. 0xf8 to 0xff: unused in 4-byte UTF-8.
///
/// See: [vis(3) manpage](https://www.freebsd.org/cgi/man.cgi?query=vis&sektion=3)
String decodeSyslog(String line) {
  // UTF-8 values for \, M, -, ^.
  const int kBackslash = 0x5c;
  const int kM = 0x4d;
  const int kDash = 0x2d;
  const int kCaret = 0x5e;

  // Mask for the UTF-8 digit range.
  const int kNum = 0x30;

  // Returns true when `byte` is within the UTF-8 7-bit digit range (0x30 to 0x39).
  bool isDigit(int byte) => (byte & 0xf0) == kNum;

  // Converts a three-digit ASCII (UTF-8) representation of an octal number `xyz` to an integer.
  int decodeOctal(int x, int y, int z) => (x & 0x3) << 6 | (y & 0x7) << 3 | z & 0x7;

  try {
    final List<int> bytes = utf8.encode(line);
    final List<int> out = <int>[];
    for (int i = 0; i < bytes.length;) {
      if (bytes[i] != kBackslash || i > bytes.length - 4) {
        // Unmapped byte: copy as-is.
        out.add(bytes[i++]);
      } else {
        // Mapped byte: decode next 4 bytes.
        if (bytes[i + 1] == kM && bytes[i + 2] == kCaret) {
          // \M^x form: bytes in range 0x80 to 0x9f.
          out.add((bytes[i + 3] & 0x7f) + 0x40);
        } else if (bytes[i + 1] == kM && bytes[i + 2] == kDash) {
          // \M-x form: bytes in range 0xa0 to 0xf7.
          out.add(bytes[i + 3] | 0x80);
        } else if (bytes.getRange(i + 1, i + 3).every(isDigit)) {
          // \ddd form: octal representation (only used for \134 and \240).
          out.add(decodeOctal(bytes[i + 1], bytes[i + 2], bytes[i + 3]));
        } else {
          // Unknown form: copy as-is.
          out.addAll(bytes.getRange(0, 4));
        }
        i += 4;
      }
    }
    return utf8.decode(out);
  } on Exception {
    // Unable to decode line: return as-is.
    return line;
  }
}

class IOSDeviceLogReader extends DeviceLogReader {
  IOSDeviceLogReader._(
    this._iMobileDevice,
    this._majorSdkVersion,
    this._deviceId,
    this.name,
    String appName,
    bool usingCISystem,
  ) : // Match for lines for the runner in syslog.
      //
      // iOS 9 format:  Runner[297] <Notice>:
      // iOS 10 format: Runner(Flutter)[297] <Notice>:
      _runnerLineRegex = RegExp(appName + r'(\(Flutter\))?\[[\d]+\] <[A-Za-z]+>: '),
      _usingCISystem = usingCISystem;

  /// Create a new [IOSDeviceLogReader].
  factory IOSDeviceLogReader.create({
    required IOSDevice device,
    IOSApp? app,
    required IMobileDevice iMobileDevice,
    bool usingCISystem = false,
  }) {
    final String appName = app?.name?.replaceAll('.app', '') ?? '';
    return IOSDeviceLogReader._(
      iMobileDevice,
      device.majorSdkVersion,
      device.id,
      device.name,
      appName,
      usingCISystem,
    );
  }

  /// Create an [IOSDeviceLogReader] for testing.
  factory IOSDeviceLogReader.test({
    required IMobileDevice iMobileDevice,
    bool useSyslog = true,
    bool usingCISystem = false,
    int? majorSdkVersion,
  }) {
    final int sdkVersion;
    if (majorSdkVersion != null) {
      sdkVersion = majorSdkVersion;
    } else {
      sdkVersion = useSyslog ? 12 : 13;
    }
    return IOSDeviceLogReader._(
      iMobileDevice, sdkVersion, '1234', 'test', 'Runner', usingCISystem);
  }

  @override
  final String name;
  final int _majorSdkVersion;
  final String _deviceId;
  final IMobileDevice _iMobileDevice;
  final bool _usingCISystem;

  // Matches a syslog line from the runner.
  RegExp _runnerLineRegex;

  // Similar to above, but allows ~arbitrary components instead of "Runner"
  // and "Flutter". The regex tries to strike a balance between not producing
  // false positives and not producing false negatives.
  final RegExp _anyLineRegex = RegExp(r'\w+(\([^)]*\))?\[\d+\] <[A-Za-z]+>: ');

  // Logging from native code/Flutter engine is prefixed by timestamp and process metadata:
  // 2020-09-15 19:15:10.931434-0700 Runner[541:226276] Did finish launching.
  // 2020-09-15 19:15:10.931434-0700 Runner[541:226276] [Category] Did finish launching.
  //
  // Logging from the dart code has no prefixing metadata.
  final RegExp _debuggerLoggingRegex = RegExp(r'^\S* \S* \S*\[[0-9:]*] (.*)');

  @visibleForTesting
  late final StreamController<String> linesController = StreamController<String>.broadcast(
    onListen: _listenToSysLog,
    onCancel: dispose,
  );

  // Sometimes (race condition?) we try to send a log after the controller has
  // been closed. See https://github.com/flutter/flutter/issues/99021 for more
  // context.
  void _addToLinesController(String message, IOSDeviceLogSource source) {
    if (!linesController.isClosed) {
      if (_excludeLog(message, source)) {
        return;
      }
      linesController.add(message);
    }
  }

  /// Used to track messages prefixed with "flutter:" when [useBothLogDeviceReaders]
  /// is true.
  final List<String> _streamFlutterMessages = <String>[];

  /// When using both `idevicesyslog` and `ios-deploy`, exclude logs with the
  /// "flutter:" prefix if they have already been added to the stream. This is
  /// to prevent duplicates from being printed.
  ///
  /// If a message does not have the prefix, exclude it if the message's
  /// source is `idevicesyslog`. This is done because `ios-deploy` and
  /// `idevicesyslog` often have different prefixes on non-flutter messages
  /// and are often not critical for CI tests.
  bool _excludeLog(String message, IOSDeviceLogSource source) {
    if (!useBothLogDeviceReaders) {
      return false;
    }
    if (message.startsWith('flutter:')) {
      if (_streamFlutterMessages.contains(message)) {
        return true;
      }
      _streamFlutterMessages.add(message);
    } else if (source == IOSDeviceLogSource.idevicesyslog) {
      return true;
    }
    return false;
  }

  final List<StreamSubscription<void>> _loggingSubscriptions = <StreamSubscription<void>>[];

  @override
  Stream<String> get logLines => linesController.stream;

  @override
  FlutterVmService? get connectedVMService => _connectedVMService;
  FlutterVmService? _connectedVMService;

  @override
  set connectedVMService(FlutterVmService? connectedVmService) {
    if (connectedVmService != null) {
      _listenToUnifiedLoggingEvents(connectedVmService);
    }
    _connectedVMService = connectedVmService;
  }

  static const int minimumUniversalLoggingSdkVersion = 13;

  /// Listen to Dart VM for logs on iOS 13 or greater.
  ///
  /// Only send logs to stream if [_iosDeployDebugger] is null or
  /// the [_iosDeployDebugger] debugger is not attached.
  Future<void> _listenToUnifiedLoggingEvents(FlutterVmService connectedVmService) async {
    if (_majorSdkVersion < minimumUniversalLoggingSdkVersion) {
      return;
    }
    try {
      // The VM service will not publish logging events unless the debug stream is being listened to.
      // Listen to this stream as a side effect.
      unawaited(connectedVmService.service.streamListen('Debug'));

      await Future.wait(<Future<void>>[
        connectedVmService.service.streamListen(vm_service.EventStreams.kStdout),
        connectedVmService.service.streamListen(vm_service.EventStreams.kStderr),
      ]);
    } on vm_service.RPCError {
      // Do nothing, since the tool is already subscribed.
    }

    void logMessage(vm_service.Event event) {
      if (_iosDeployDebugger != null && _iosDeployDebugger!.debuggerAttached) {
        // Prefer the more complete logs from the attached debugger.
        return;
      }
      final String message = processVmServiceMessage(event);
      if (message.isNotEmpty) {
        _addToLinesController(message, IOSDeviceLogSource.unifiedLogging);
      }
    }

    _loggingSubscriptions.addAll(<StreamSubscription<void>>[
      connectedVmService.service.onStdoutEvent.listen(logMessage),
      connectedVmService.service.onStderrEvent.listen(logMessage),
    ]);
  }

  /// Log reader will listen to [debugger.logLines] and will detach debugger on dispose.
  IOSDeployDebugger? get debuggerStream => _iosDeployDebugger;

  /// Send messages from ios-deploy debugger stream to device log reader stream.
  set debuggerStream(IOSDeployDebugger? debugger) {
    // Logging is gathered from syslog on iOS earlier than 13.
    if (_majorSdkVersion < minimumUniversalLoggingSdkVersion) {
      return;
    }
    _iosDeployDebugger = debugger;
    if (debugger == null) {
      return;
    }
    // Add the debugger logs to the controller created on initialization.
    _loggingSubscriptions.add(debugger.logLines.listen(
      (String line) => _addToLinesController(
        _debuggerLineHandler(line),
        IOSDeviceLogSource.iosDeploy,
      ),
      onError: linesController.addError,
      onDone: linesController.close,
      cancelOnError: true,
    ));
  }
  IOSDeployDebugger? _iosDeployDebugger;

  // Strip off the logging metadata (leave the category), or just echo the line.
  String _debuggerLineHandler(String line) => _debuggerLoggingRegex.firstMatch(line)?.group(1) ?? line;

  /// Use both logs from `idevicesyslog` and `ios-deploy` when debugging from CI system
  /// since sometimes `ios-deploy` does not return the device logs:
  /// https://github.com/flutter/flutter/issues/121231
  @visibleForTesting
  bool get useBothLogDeviceReaders {
    return _usingCISystem && _majorSdkVersion >= 16;
  }

  /// Start and listen to idevicesyslog to get device logs for iOS versions
  /// prior to 13 or if [useBothLogDeviceReaders] is true.
  void _listenToSysLog() {
    // Syslog stopped working on iOS 13 (https://github.com/flutter/flutter/issues/41133).
    // However, from at least iOS 16, it has began working again. It's unclear
    // why it started working again so only use syslogs for iOS versions prior
    // to 13 unless [useBothLogDeviceReaders] is true.
    if (!useBothLogDeviceReaders && _majorSdkVersion >= minimumUniversalLoggingSdkVersion) {
      return;
    }
    _iMobileDevice.startLogger(_deviceId).then<void>((Process process) {
      process.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(_newSyslogLineHandler());
      process.stderr.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen(_newSyslogLineHandler());
      process.exitCode.whenComplete(() {
        if (!linesController.hasListener) {
          return;
        }
        // When using both log readers, do not close the stream on exit.
        // This is to allow ios-deploy to be the source of authority to close
        // the stream.
        if (useBothLogDeviceReaders && debuggerStream != null) {
          return;
        }
        linesController.close();
      });
      assert(idevicesyslogProcess == null);
      idevicesyslogProcess = process;
    });
  }

  @visibleForTesting
  Process? idevicesyslogProcess;

  // Returns a stateful line handler to properly capture multiline output.
  //
  // For multiline log messages, any line after the first is logged without
  // any specific prefix. To properly capture those, we enter "printing" mode
  // after matching a log line from the runner. When in printing mode, we print
  // all lines until we find the start of another log message (from any app).
  void Function(String line) _newSyslogLineHandler() {
    bool printing = false;

    return (String line) {
      if (printing) {
        if (!_anyLineRegex.hasMatch(line)) {
          _addToLinesController(decodeSyslog(line), IOSDeviceLogSource.idevicesyslog);
          return;
        }

        printing = false;
      }

      final Match? match = _runnerLineRegex.firstMatch(line);

      if (match != null) {
        final String logLine = line.substring(match.end);
        // Only display the log line after the initial device and executable information.
        _addToLinesController(decodeSyslog(logLine), IOSDeviceLogSource.idevicesyslog);
        printing = true;
      }
    };
  }

  @override
  void dispose() {
    for (final StreamSubscription<void> loggingSubscription in _loggingSubscriptions) {
      loggingSubscription.cancel();
    }
    idevicesyslogProcess?.kill();
    _iosDeployDebugger?.detach();
  }
}

enum IOSDeviceLogSource {
  /// Gets logs from ios-deploy debugger.
  iosDeploy,
  /// Gets logs from idevicesyslog.
  idevicesyslog,
  /// Gets logs from the Dart VM Service.
  unifiedLogging,
}

/// A [DevicePortForwarder] specialized for iOS usage with iproxy.
class IOSDevicePortForwarder extends DevicePortForwarder {

  /// Create a new [IOSDevicePortForwarder].
  IOSDevicePortForwarder({
    required Logger logger,
    required String id,
    required IProxy iproxy,
    required OperatingSystemUtils operatingSystemUtils,
  }) : _logger = logger,
       _id = id,
       _iproxy = iproxy,
       _operatingSystemUtils = operatingSystemUtils;

  /// Create a [IOSDevicePortForwarder] for testing.
  ///
  /// This specifies the path to iproxy as 'iproxy` and the dyLdLibEntry as
  /// 'DYLD_LIBRARY_PATH: /path/to/libs'.
  ///
  /// The device id may be provided, but otherwise defaults to '1234'.
  factory IOSDevicePortForwarder.test({
    required ProcessManager processManager,
    required Logger logger,
    String? id,
    required OperatingSystemUtils operatingSystemUtils,
  }) {
    return IOSDevicePortForwarder(
      logger: logger,
      iproxy: IProxy.test(
        logger: logger,
        processManager: processManager,
      ),
      id: id ?? '1234',
      operatingSystemUtils: operatingSystemUtils,
    );
  }

  final Logger _logger;
  final String _id;
  final IProxy _iproxy;
  final OperatingSystemUtils _operatingSystemUtils;

  @override
  List<ForwardedPort> forwardedPorts = <ForwardedPort>[];

  @visibleForTesting
  void addForwardedPorts(List<ForwardedPort> ports) {
    ports.forEach(forwardedPorts.add);
  }

  static const Duration _kiProxyPortForwardTimeout = Duration(seconds: 1);

  @override
  Future<int> forward(int devicePort, { int? hostPort }) async {
    final bool autoselect = hostPort == null || hostPort == 0;
    if (autoselect) {
      final int freePort = await _operatingSystemUtils.findFreePort();
      // Dynamic port range 49152 - 65535.
      hostPort = freePort == 0 ? 49152 : freePort;
    }

    Process? process;

    bool connected = false;
    while (!connected) {
      _logger.printTrace('Attempting to forward device port $devicePort to host port $hostPort');
      process = await _iproxy.forward(devicePort, hostPort!, _id);
      // TODO(ianh): This is a flaky race condition, https://github.com/libimobiledevice/libimobiledevice/issues/674
      connected = !await process.stdout.isEmpty.timeout(_kiProxyPortForwardTimeout, onTimeout: () => false);
      if (!connected) {
        process.kill();
        if (autoselect) {
          hostPort += 1;
          if (hostPort > 65535) {
            throw Exception('Could not find open port on host.');
          }
        } else {
          throw Exception('Port $hostPort is not available.');
        }
      }
    }
    assert(connected);
    assert(process != null);

    final ForwardedPort forwardedPort = ForwardedPort.withContext(
      hostPort!, devicePort, process,
    );
    _logger.printTrace('Forwarded port $forwardedPort');
    forwardedPorts.add(forwardedPort);
    return hostPort;
  }

  @override
  Future<void> unforward(ForwardedPort forwardedPort) async {
    if (!forwardedPorts.remove(forwardedPort)) {
      // Not in list. Nothing to remove.
      return;
    }

    _logger.printTrace('Un-forwarding port $forwardedPort');
    forwardedPort.dispose();
  }

  @override
  Future<void> dispose() async {
    for (final ForwardedPort forwardedPort in forwardedPorts) {
      forwardedPort.dispose();
    }
  }
}
