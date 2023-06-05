// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/memory.dart';
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/time.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/isolated/devfs_web.dart';
import 'package:flutter_tools/src/isolated/resident_web_runner.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:flutter_tools/src/resident_runner.dart';
import 'package:flutter_tools/src/vmservice.dart';
import 'package:test/fake.dart';

import '../src/common.dart';
import '../src/context.dart';
import '../src/test_build_system.dart';

void main() {
  late FakeFlutterDevice mockFlutterDevice;
  late FakeWebDevFS mockWebDevFS;
  late FileSystem fileSystem;

  setUp(() {
    fileSystem = MemoryFileSystem.test();
    mockWebDevFS = FakeWebDevFS();
    final FakeWebDevice mockWebDevice = FakeWebDevice();
    mockFlutterDevice = FakeFlutterDevice(mockWebDevice);
    mockFlutterDevice._devFS = mockWebDevFS;

    fileSystem.file('.packages').writeAsStringSync('\n');
    fileSystem.file('pubspec.yaml').createSync();
    fileSystem.file(fileSystem.path.join('lib', 'main.dart')).createSync(recursive: true);
    fileSystem.file(fileSystem.path.join('web', 'index.html')).createSync(recursive: true);
  });

  testUsingContext('Can successfully run and connect without vmservice', () async {
    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final ResidentWebRunner residentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: project,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      ipv6: true,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      systemClock: SystemClock.fixed(DateTime(0, 0, 0)),
      usage: TestUsage(),
    );

    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    final DebugConnectionInfo debugConnectionInfo = await connectionInfoCompleter.future;

    expect(debugConnectionInfo.wsUri, null);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext('ResidentWebRunner calls appFailedToStart if initial compilation fails', () async {
    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final ResidentWebRunner residentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: project,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      ipv6: true,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      systemClock: SystemClock.fixed(DateTime(0, 0, 0)),
      usage: TestUsage(),
    );

    expect(() => residentWebRunner.run(), throwsToolExit());
    expect(await residentWebRunner.waitForAppToFinish(), 1);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: false)),
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  // Regression test for https://github.com/flutter/flutter/issues/60613
  testUsingContext('ResidentWebRunner calls appFailedToStart if error is thrown during startup', () async {
    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final ResidentWebRunner residentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: project,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      ipv6: true,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      systemClock: SystemClock.fixed(DateTime(0, 0, 0)),
      usage: TestUsage(),
    );

    expect(() async => residentWebRunner.run(), throwsException);
    expect(await residentWebRunner.waitForAppToFinish(), 1);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.error(Exception('foo')),
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Can full restart after attaching', () async {
    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final ResidentWebRunner residentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: project,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      ipv6: true,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      systemClock: SystemClock.fixed(DateTime(0, 0, 0)),
      usage: TestUsage(),
    );
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 0);
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.all(BuildResult(success: true)),
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });

  testUsingContext('Fails on compilation errors in hot restart', () async {
    final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
    final ResidentWebRunner residentWebRunner = ResidentWebRunner(
      mockFlutterDevice,
      flutterProject: project,
      debuggingOptions: DebuggingOptions.disabled(BuildInfo.release),
      ipv6: true,
      fileSystem: fileSystem,
      logger: BufferLogger.test(),
      systemClock: SystemClock.fixed(DateTime(0, 0, 0)),
      usage: TestUsage(),
    );
    final Completer<DebugConnectionInfo> connectionInfoCompleter = Completer<DebugConnectionInfo>();
    unawaited(residentWebRunner.run(
      connectionInfoCompleter: connectionInfoCompleter,
    ));
    await connectionInfoCompleter.future;
    final OperationResult result = await residentWebRunner.restart(fullRestart: true);

    expect(result.code, 1);
    expect(result.message, contains('Failed to recompile application.'));
  }, overrides: <Type, Generator>{
    BuildSystem: () => TestBuildSystem.list(<BuildResult>[
      BuildResult(success: true),
      BuildResult(success: false),
    ]),
    FileSystem: () => fileSystem,
    ProcessManager: () => FakeProcessManager.any(),
  });
}

class FakeWebDevFS extends Fake implements WebDevFS {
  @override
  List<Uri> get sources => <Uri>[];

  @override
  Future<Uri> create() async {
    return Uri.base;
  }
}

// Unfortunately Device, despite not being immutable, has an `operator ==`.
// Until we fix that, we have to also ignore related lints here.
// ignore: avoid_implementing_value_types
class FakeWebDevice extends Fake implements Device {
  @override
  String get name => 'web';

  @override
  Future<bool> stopApp(
    ApplicationPackage? app, {
    String? userIdentifier,
  }) async {
    return true;
  }

  @override
  Future<LaunchResult> startApp(
    ApplicationPackage? package, {
    String? mainPath,
    String? route,
    DebuggingOptions? debuggingOptions,
    Map<String, dynamic>? platformArgs,
    bool prebuiltApplication = false,
    bool ipv6 = false,
    String? userIdentifier,
  }) async {
    return LaunchResult.succeeded();
  }
}

class FakeFlutterDevice extends Fake implements FlutterDevice {
  FakeFlutterDevice(this.device);

  @override
  final FakeWebDevice device;


  DevFS? _devFS;

  @override
  DevFS? get devFS => _devFS;

  @override
  set devFS(DevFS? value) { }

  @override
  FlutterVmService? vmService;
}
