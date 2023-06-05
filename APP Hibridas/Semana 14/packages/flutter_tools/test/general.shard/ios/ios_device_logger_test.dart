// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/async_guard.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/ios_deploy.dart';
import 'package:flutter_tools/src/ios/mac.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';
import 'package:vm_service/vm_service.dart';

import '../../src/common.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fake_vm_services.dart';

void main() {
  late FakeProcessManager processManager;
  late Artifacts artifacts;
  late Cache fakeCache;
  late BufferLogger logger;
  late String ideviceSyslogPath;

  setUp(() {
    processManager = FakeProcessManager.empty();
    fakeCache = Cache.test(processManager: FakeProcessManager.any());
    artifacts = Artifacts.test();
    logger = BufferLogger.test();
    ideviceSyslogPath = artifacts.getHostArtifact(HostArtifact.idevicesyslog).path;
  });

  group('syslog stream', () {
    testWithoutContext('decodeSyslog decodes a syslog-encoded line', () {
      final String decoded = decodeSyslog(
          r'I \M-b\M^]\M-$\M-o\M-8\M^O syslog '
          r'\M-B\M-/\134_(\M-c\M^C\M^D)_/\M-B\M-/ \M-l\M^F\240!');

      expect(decoded, r'I ❤️ syslog ¯\_(ツ)_/¯ 솠!');
    });

    testWithoutContext('decodeSyslog passes through un-decodeable lines as-is', () {
      final String decoded = decodeSyslog(r'I \M-b\M^O syslog!');

      expect(decoded, r'I \M-b\M^O syslog!');
    });

    testWithoutContext('IOSDeviceLogReader suppresses non-Flutter lines from output with syslog', () async {
      processManager.addCommand(
        FakeCommand(
            command: <String>[
              ideviceSyslogPath, '-u', '1234',
            ],
            stdout: '''
Runner(Flutter)[297] <Notice>: A is for ari
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestaltSupport.m:153: pid 123 (Runner) does not have sandbox access for frZQaeyWLUvLjeuEK43hmg and IS NOT appropriately entitled
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt MobileGestalt.c:550: no access to InverseDeviceID (see <rdar://problem/11744455>)
Runner(Flutter)[297] <Notice>: I is for ichigo
Runner(UIKit)[297] <Notice>: E is for enpitsu"
'''
        ),
      );
      final DeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
      );
      final List<String> lines = await logReader.logLines.toList();

      expect(lines, <String>['A is for ari', 'I is for ichigo']);
    });

    testWithoutContext('IOSDeviceLogReader includes multi-line Flutter logs in the output with syslog', () async {
      processManager.addCommand(
        FakeCommand(
            command: <String>[
              ideviceSyslogPath, '-u', '1234',
            ],
            stdout: '''
Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with another Flutter message following it.
Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with a non-Flutter log message following it.
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt
'''
        ),
      );
      final DeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
      );
      final List<String> lines = await logReader.logLines.toList();

      expect(lines, <String>[
        'This is a multi-line message,',
        '  with another Flutter message following it.',
        'This is a multi-line message,',
        '  with a non-Flutter log message following it.',
      ]);
    });

    testWithoutContext('includes multi-line Flutter logs in the output', () async {
      processManager.addCommand(
        FakeCommand(
          command: <String>[
            ideviceSyslogPath, '-u', '1234',
          ],
          stdout: '''
Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with another Flutter message following it.
Runner(Flutter)[297] <Notice>: This is a multi-line message,
  with a non-Flutter log message following it.
Runner(libsystem_asl.dylib)[297] <Notice>: libMobileGestalt
''',
        ),
      );

      final DeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
      );
      final List<String> lines = await logReader.logLines.toList();

      expect(lines, <String>[
        'This is a multi-line message,',
        '  with another Flutter message following it.',
        'This is a multi-line message,',
        '  with a non-Flutter log message following it.',
      ]);
    });
  });

  group('VM service', () {
    testWithoutContext('IOSDeviceLogReader can listen to VM Service logs', () async {
      final Event stdoutEvent = Event(
        kind: 'Stdout',
        timestamp: 0,
        bytes: base64.encode(utf8.encode('  This is a message ')),
      );
      final Event stderrEvent = Event(
        kind: 'Stderr',
        timestamp: 0,
        bytes: base64.encode(utf8.encode('  And this is an error ')),
      );
      final FlutterVmService vmService = FakeVmServiceHost(requests: <VmServiceExpectation>[
        const FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{
          'streamId': 'Debug',
        }),
        const FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{
          'streamId': 'Stdout',
        }),
        const FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{
          'streamId': 'Stderr',
        }),
        FakeVmServiceStreamResponse(event: stdoutEvent, streamId: 'Stdout'),
        FakeVmServiceStreamResponse(event: stderrEvent, streamId: 'Stderr'),
      ]).vmService;
      final DeviceLogReader logReader = IOSDeviceLogReader.test(
        useSyslog: false,
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
      );
      logReader.connectedVMService = vmService;

      // Wait for stream listeners to fire.
      await expectLater(logReader.logLines, emitsInAnyOrder(<Matcher>[
        equals('  This is a message '),
        equals('  And this is an error '),
      ]));
    });

    testWithoutContext('IOSDeviceLogReader ignores VM Service logs when attached to debugger', () async {
      final Event stdoutEvent = Event(
        kind: 'Stdout',
        timestamp: 0,
        bytes: base64.encode(utf8.encode('  This is a message ')),
      );
      final Event stderrEvent = Event(
        kind: 'Stderr',
        timestamp: 0,
        bytes: base64.encode(utf8.encode('  And this is an error ')),
      );
      final FlutterVmService vmService = FakeVmServiceHost(requests: <VmServiceExpectation>[
        const FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{
          'streamId': 'Debug',
        }),
        const FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{
          'streamId': 'Stdout',
        }),
        const FakeVmServiceRequest(method: 'streamListen', args: <String, Object>{
          'streamId': 'Stderr',
        }),
        FakeVmServiceStreamResponse(event: stdoutEvent, streamId: 'Stdout'),
        FakeVmServiceStreamResponse(event: stderrEvent, streamId: 'Stderr'),
      ]).vmService;
      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        useSyslog: false,
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
      );
      logReader.connectedVMService = vmService;

      final FakeIOSDeployDebugger iosDeployDebugger = FakeIOSDeployDebugger();
      iosDeployDebugger.debuggerAttached = true;

      final Stream<String> debuggingLogs = Stream<String>.fromIterable(<String>[
        'Message from debugger',
      ]);
      iosDeployDebugger.logLines = debuggingLogs;
      logReader.debuggerStream = iosDeployDebugger;

      // Wait for stream listeners to fire.
      await expectLater(logReader.logLines, emitsInAnyOrder(<Matcher>[
        equals('Message from debugger'),
      ]));
    });
  });

  group('debugger stream', () {
    testWithoutContext('IOSDeviceLogReader removes metadata prefix from lldb output', () async {
      final Stream<String> debuggingLogs = Stream<String>.fromIterable(<String>[
        '2020-09-15 19:15:10.931434-0700 Runner[541:226276] Did finish launching.',
        '2020-09-15 19:15:10.931434-0700 Runner[541:226276] [Category] Did finish launching from logging category.',
        'stderr from dart',
        '',
      ]);

      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
        useSyslog: false,
      );
      final FakeIOSDeployDebugger iosDeployDebugger = FakeIOSDeployDebugger();
      iosDeployDebugger.logLines = debuggingLogs;
      logReader.debuggerStream = iosDeployDebugger;
      final Future<List<String>> logLines = logReader.logLines.toList();

      expect(await logLines, <String>[
        'Did finish launching.',
        '[Category] Did finish launching from logging category.',
        'stderr from dart',
        '',
      ]);
    });

    testWithoutContext('errors on debugger stream closes log stream', () async {
      final Stream<String> debuggingLogs = Stream<String>.error('ios-deploy error');
      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
        useSyslog: false,
      );
      final Completer<void> streamComplete = Completer<void>();
      final FakeIOSDeployDebugger iosDeployDebugger = FakeIOSDeployDebugger();
      iosDeployDebugger.logLines = debuggingLogs;
      logReader.logLines.listen(null, onError: (Object error) => streamComplete.complete());
      logReader.debuggerStream = iosDeployDebugger;

      await streamComplete.future;
    });

    testWithoutContext('detaches debugger', () async {
      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
        useSyslog: false,
      );
      final FakeIOSDeployDebugger iosDeployDebugger = FakeIOSDeployDebugger();
      logReader.debuggerStream = iosDeployDebugger;

      logReader.dispose();
      expect(iosDeployDebugger.detached, true);
    });

    testWithoutContext('Does not throw if debuggerStream set after logReader closed', () async {
      final Stream<String> debuggingLogs = Stream<String>.fromIterable(<String>[
        '2020-09-15 19:15:10.931434-0700 Runner[541:226276] Did finish launching.',
        '2020-09-15 19:15:10.931434-0700 Runner[541:226276] [Category] Did finish launching from logging category.',
        'stderr from dart',
        '',
      ]);

      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
        useSyslog: false,
      );
      Object? exception;
      StackTrace? trace;
      await asyncGuard(
          () async {
            await logReader.linesController.close();
            final FakeIOSDeployDebugger iosDeployDebugger = FakeIOSDeployDebugger();
            iosDeployDebugger.logLines = debuggingLogs;
            logReader.debuggerStream = iosDeployDebugger;
            await logReader.logLines.drain<void>();
          },
          onError: (Object err, StackTrace stackTrace) {
            exception = err;
            trace = stackTrace;
          }
      );
      expect(
        exception,
        isNull,
        reason: trace.toString(),
      );
    });
  });

  group('both syslog and debugger stream', () {

    testWithoutContext('useBothLogDeviceReaders is true when CI option is true and sdk is at least 16', () {
      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
        usingCISystem: true,
        majorSdkVersion: 16,
      );

      expect(logReader.useBothLogDeviceReaders, isTrue);
    });

    testWithoutContext('useBothLogDeviceReaders is false when sdk is less than 16', () {
      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
        usingCISystem: true,
        majorSdkVersion: 15,
      );

      expect(logReader.useBothLogDeviceReaders, isFalse);
    });

    testWithoutContext('useBothLogDeviceReaders is false when CI option is false', () {
      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
        majorSdkVersion: 16,
      );

      expect(logReader.useBothLogDeviceReaders, isFalse);
    });

    testWithoutContext('syslog only sends flutter messages to stream when useBothLogDeviceReaders is true', () async {
      processManager.addCommand(
        FakeCommand(
            command: <String>[
              ideviceSyslogPath, '-u', '1234',
            ],
            stdout: '''
Runner(Flutter)[297] <Notice>: A is for ari
Runner(Flutter)[297] <Notice>: I is for ichigo
May 30 13:56:28 Runner(Flutter)[2037] <Notice>: flutter: The Dart VM service is listening on http://127.0.0.1:63098/35ZezGIQLnw=/
May 30 13:56:28 Runner(Flutter)[2037] <Notice>: flutter: This is a test
May 30 13:56:28 Runner(Flutter)[2037] <Notice>: [VERBOSE-2:FlutterDarwinContextMetalImpeller.mm(39)] Using the Impeller rendering backend.
'''
        ),
      );
      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
        usingCISystem: true,
        majorSdkVersion: 16,
      );
      final List<String> lines = await logReader.logLines.toList();

      expect(logReader.useBothLogDeviceReaders, isTrue);
      expect(processManager, hasNoRemainingExpectations);
      expect(lines, <String>[
        'flutter: The Dart VM service is listening on http://127.0.0.1:63098/35ZezGIQLnw=/',
        'flutter: This is a test'
      ]);
    });

    testWithoutContext('IOSDeviceLogReader uses both syslog and ios-deploy debugger', () async {
      processManager.addCommand(
        FakeCommand(
            command: <String>[
              ideviceSyslogPath, '-u', '1234',
            ],
            stdout: '''
May 30 13:56:28 Runner(Flutter)[2037] <Notice>: flutter: The Dart VM service is listening on http://127.0.0.1:63098/35ZezGIQLnw=/
May 30 13:56:28 Runner(Flutter)[2037] <Notice>: flutter: Check for duplicate
May 30 13:56:28 Runner(Flutter)[2037] <Notice>: [VERBOSE-2:FlutterDarwinContextMetalImpeller.mm(39)] Using the Impeller rendering backend.
'''
        ),
      );

      final Stream<String> debuggingLogs = Stream<String>.fromIterable(<String>[
        '2023-06-01 12:49:01.445093-0500 Runner[2225:533240] flutter: Check for duplicate',
        '(lldb) 2023-05-30 13:48:52.461894-0500 Runner[2019:1101495] [VERBOSE-2:FlutterDarwinContextMetalImpeller.mm(39)] Using the Impeller rendering backend.',
      ]);

      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
        usingCISystem: true,
        majorSdkVersion: 16,
      );
      final FakeIOSDeployDebugger iosDeployDebugger = FakeIOSDeployDebugger();
      iosDeployDebugger.logLines = debuggingLogs;
      logReader.debuggerStream = iosDeployDebugger;
      final Future<List<String>> logLines = logReader.logLines.toList();
      final List<String> lines = await logLines;

      expect(logReader.useBothLogDeviceReaders, isTrue);
      expect(processManager, hasNoRemainingExpectations);
      expect(lines.length, 3);
      expect(lines, containsAll(<String>[
        '(lldb) 2023-05-30 13:48:52.461894-0500 Runner[2019:1101495] [VERBOSE-2:FlutterDarwinContextMetalImpeller.mm(39)] Using the Impeller rendering backend.',
        'flutter: The Dart VM service is listening on http://127.0.0.1:63098/35ZezGIQLnw=/',
        'flutter: Check for duplicate',
      ]));

    });

    testWithoutContext('IOSDeviceLogReader only uses ios-deploy debugger when useBothLogDeviceReaders is false', () async {
      final Stream<String> debuggingLogs = Stream<String>.fromIterable(<String>[
        '(lldb) 2023-05-30 13:48:52.461894-0500 Runner[2019:1101495] [VERBOSE-2:FlutterDarwinContextMetalImpeller.mm(39)] Using the Impeller rendering backend.',
        '',
      ]);

      final IOSDeviceLogReader logReader = IOSDeviceLogReader.test(
        iMobileDevice: IMobileDevice(
          artifacts: artifacts,
          processManager: processManager,
          cache: fakeCache,
          logger: logger,
        ),
        majorSdkVersion: 16,
      );
      final FakeIOSDeployDebugger iosDeployDebugger = FakeIOSDeployDebugger();
      iosDeployDebugger.logLines = debuggingLogs;
      logReader.debuggerStream = iosDeployDebugger;
      final Future<List<String>> logLines = logReader.logLines.toList();
      final List<String> lines = await logLines;

      expect(logReader.useBothLogDeviceReaders, isFalse);
      expect(processManager, hasNoRemainingExpectations);
      expect(
        lines.contains(
          '(lldb) 2023-05-30 13:48:52.461894-0500 Runner[2019:1101495] [VERBOSE-2:FlutterDarwinContextMetalImpeller.mm(39)] Using the Impeller rendering backend.',
        ),
        isTrue,
      );
    });
  });
}

class FakeIOSDeployDebugger extends Fake implements IOSDeployDebugger {
  bool detached = false;

  @override
  bool debuggerAttached = false;

  @override
  Stream<String> logLines = const Stream<String>.empty();

  @override
  void detach() {
    detached = true;
  }
}
