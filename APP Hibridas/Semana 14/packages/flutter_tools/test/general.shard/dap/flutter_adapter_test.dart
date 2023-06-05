// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:dds/dap.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/debug_adapters/flutter_adapter.dart';
import 'package:flutter_tools/src/debug_adapters/flutter_adapter_args.dart';
import 'package:flutter_tools/src/globals.dart' as globals show platform;
import 'package:test/fake.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'mocks.dart';

void main() {
  // Use the real platform as a base so that Windows bots test paths.
  final FakePlatform platform = FakePlatform.fromPlatform(globals.platform);
  final FileSystemStyle fsStyle = platform.isWindows ? FileSystemStyle.windows : FileSystemStyle.posix;
  final String flutterRoot = platform.isWindows
                                ? r'C:\fake\flutter'
                                : '/fake/flutter';

  group('flutter adapter', () {
    final String expectedFlutterExecutable = platform.isWindows
        ? r'C:\fake\flutter\bin\flutter.bat'
        : '/fake/flutter/bin/flutter';

    setUpAll(() {
      Cache.flutterRoot = flutterRoot;
    });

    group('launchRequest', () {
      test('runs "flutter run" with --machine', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, containsAllInOrder(<String>['run', '--machine']));
      });

      test('includes env variables', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          env: <String, String>{
            'MY_TEST_ENV': 'MY_TEST_VALUE',
          },
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.env!['MY_TEST_ENV'], 'MY_TEST_VALUE');
      });

      test('does not record the VMs PID for terminating', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        // Trigger a fake debuggerConnected with a pid that we expect the
        // adapter _not_ to record, because it may be on another device.
        await adapter.debuggerConnected(_FakeVm(pid: 123));

        // Ensure the VM's pid was not recorded.
        expect(adapter.pidsToTerminate, isNot(contains(123)));
      });


      group('supportsRestartRequest', () {
        void testRestartSupport(bool supportsRestart) {
          test('notifies client for supportsRestart: $supportsRestart', () async {
            final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
              fileSystem: MemoryFileSystem.test(style: fsStyle),
              platform: platform,
              supportsRestart: supportsRestart,
            );

            final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
              cwd: '/project',
              program: 'foo.dart',
            );

            // Listen for a Capabilities event that modifies 'supportsRestartRequest'.
            final Future<CapabilitiesEventBody> capabilitiesUpdate = adapter
                .dapToClientMessages
                .where((Map<String, Object?> message) => message['event'] == 'capabilities')
                .map((Map<String, Object?> message) => message['body'] as Map<String, Object?>?)
                .where((Map<String, Object?>? body) => body != null).cast<Map<String, Object?>>()
                .map(CapabilitiesEventBody.fromJson)
                .firstWhere((CapabilitiesEventBody body) => body.capabilities.supportsRestartRequest != null);

            await adapter.configurationDoneRequest(MockRequest(), null, () {});
            final Completer<void> launchCompleter = Completer<void>();
            await adapter.launchRequest(MockRequest(), args, launchCompleter.complete);
            await launchCompleter.future;

            // Ensure the Capabilities update has the expected value.
            expect((await capabilitiesUpdate).capabilities.supportsRestartRequest, supportsRestart);
          });
        }

        testRestartSupport(true);
        testRestartSupport(false);
      });

      test('calls "app.stop" on terminateRequest', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> launchCompleter = Completer<void>();
        await adapter.launchRequest(MockRequest(), args, launchCompleter.complete);
        await launchCompleter.future;

        final Completer<void> terminateCompleter = Completer<void>();
        await adapter.terminateRequest(MockRequest(), TerminateArguments(restart: false), terminateCompleter.complete);
        await terminateCompleter.future;

        expect(adapter.dapToFlutterRequests, contains('app.stop'));
      });

      test('does not call "app.stop" on terminateRequest if app was not started', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
          simulateAppStarted: false,
        );

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> launchCompleter = Completer<void>();
        await adapter.launchRequest(MockRequest(), args, launchCompleter.complete);
        await launchCompleter.future;

        final Completer<void> terminateCompleter = Completer<void>();
        await adapter.terminateRequest(MockRequest(), TerminateArguments(restart: false), terminateCompleter.complete);
        await terminateCompleter.future;

        expect(adapter.dapToFlutterRequests, isNot(contains('app.stop')));
      });

      test('includes Dart Debug extension progress update', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
          preAppStart: (MockFlutterDebugAdapter adapter) {
            adapter.simulateRawStdout('Waiting for connection from Dart debug extension…');
          }
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        // Begin listening for progress events up until `progressEnd` (but don't await yet).
        final Future<List<List<Object?>>> progressEventsFuture =
            adapter.dapToClientProgressEvents
              .takeWhile((Map<String, Object?> message) => message['event'] != 'progressEnd')
              .map((Map<String, Object?> message) => <Object?>[message['event'], (message['body']! as Map<String, Object?>)['message']])
              .toList();

        // Initialize with progress support.
        await adapter.initializeRequest(
          MockRequest(),
          InitializeRequestArguments(adapterID: 'test', supportsProgressReporting: true, ),
          (_) {},
        );
        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        // Ensure we got the expected events prior to the
        final List<List<Object?>> progressEvents = await progressEventsFuture;
        expect(progressEvents, containsAllInOrder(<List<String>>[
          <String>['progressStart', 'Launching…'],
          <String>['progressUpdate', 'Please click the Dart Debug extension button in the spawned browser window'],
          // progressEnd isn't included because we used takeWhile to stop when it arrived above.
        ]));
      });
    });

    group('attachRequest', () {
      test('runs "flutter attach" with --machine', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterAttachRequestArguments args = FlutterAttachRequestArguments(
          cwd: '/project',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.attachRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, containsAllInOrder(<String>['attach', '--machine']));
      });

      test('runs "flutter attach" with program if passed in', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterAttachRequestArguments args =
            FlutterAttachRequestArguments(
          cwd: '/project',
          program: 'program/main.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.attachRequest(
            MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(
            adapter.processArgs,
            containsAllInOrder(<String>[
              'attach',
              '--machine',
              '--target',
              'program/main.dart'
            ]));
      });

      test('does not record the VMs PID for terminating', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterAttachRequestArguments args = FlutterAttachRequestArguments(
          cwd: '/project',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.attachRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        // Trigger a fake debuggerConnected with a pid that we expect the
        // adapter _not_ to record, because it may be on another device.
        await adapter.debuggerConnected(_FakeVm(pid: 123));

        // Ensure the VM's pid was not recorded.
        expect(adapter.pidsToTerminate, isNot(contains(123)));
      });

      test('calls "app.detach" on terminateRequest', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );

        final FlutterAttachRequestArguments args = FlutterAttachRequestArguments(
          cwd: '/project',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> attachCompleter = Completer<void>();
        await adapter.attachRequest(MockRequest(), args, attachCompleter.complete);
        await attachCompleter.future;

        final Completer<void> terminateCompleter = Completer<void>();
        await adapter.terminateRequest(MockRequest(), TerminateArguments(restart: false), terminateCompleter.complete);
        await terminateCompleter.future;

        expect(adapter.dapToFlutterRequests, contains('app.detach'));
      });
    });

    group('forwards events', () {
      test('app.webLaunchUrl', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );

        // Start listening for the forwarded event (don't await it yet, it won't
        // be triggered until the call below).
        final Future<Map<String, Object?>> forwardedEvent = adapter.dapToClientMessages
            .firstWhere((Map<String, Object?> data) => data['event'] == 'flutter.forwardedEvent');

        // Simulate Flutter asking for a URL to be launched.
        adapter.simulateStdoutMessage(<String, Object?>{
          'event': 'app.webLaunchUrl',
          'params': <String, Object?>{
            'url': 'http://localhost:123/',
            'launched': false,
          }
        });

        // Wait for the forwarded event.
        final Map<String, Object?> message = await forwardedEvent;
        // Ensure the body of the event matches the original event sent by Flutter.
        expect(message['body'], <String, Object?>{
          'event': 'app.webLaunchUrl',
          'params': <String, Object?>{
            'url': 'http://localhost:123/',
            'launched': false,
          }
        });
      });
    });

    group('handles reverse requests', () {
      test('app.exposeUrl', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );

        // Pretend to be the client, handling any reverse-requests for exposeUrl
        // and mapping the host to 'mapped-host'.
        adapter.exposeUrlHandler = (String url) => Uri.parse(url).replace(host: 'mapped-host').toString();

        // Simulate Flutter asking for a URL to be exposed.
        const int requestId = 12345;
        adapter.simulateStdoutMessage(<String, Object?>{
          'id': requestId,
          'method': 'app.exposeUrl',
          'params': <String, Object?>{
            'url': 'http://localhost:123/',
          }
        });

        // Allow the handler to be processed.
        await pumpEventQueue(times: 5000);

        final Map<String, Object?> message = adapter.dapToFlutterMessages.singleWhere((Map<String, Object?> data) => data['id'] == requestId);
        expect(message['result'], 'http://mapped-host:123/');
      });
    });

    group('--start-paused', () {
      test('is passed for debug mode', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, contains('--start-paused'));
      });

      test('is not passed for noDebug mode', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          noDebug: true,
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, isNot(contains('--start-paused')));
      });

      test('is not passed if toolArgs contains --profile', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          toolArgs: <String>['--profile'],
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, isNot(contains('--start-paused')));
      });

      test('is not passed if toolArgs contains --release', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final Completer<void> responseCompleter = Completer<void>();

        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          toolArgs: <String>['--release'],
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.processArgs, isNot(contains('--start-paused')));
      });
    });

    test('includes toolArgs', () async {
      final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
        fileSystem: MemoryFileSystem.test(style: fsStyle),
        platform: platform,
      );
      final Completer<void> responseCompleter = Completer<void>();

      final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
        cwd: '/project',
        program: 'foo.dart',
        toolArgs: <String>['tool_arg'],
        noDebug: true,
      );

      await adapter.configurationDoneRequest(MockRequest(), null, () {});
      await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
      await responseCompleter.future;

      expect(adapter.executable, equals(expectedFlutterExecutable));
      expect(adapter.processArgs, contains('tool_arg'));
    });

    group('maps org-dartlang-sdk paths', () {
      late FileSystem fs;
      late FlutterDebugAdapter adapter;
      setUp(() {
        fs = MemoryFileSystem.test(style: fsStyle);
        adapter = MockFlutterDebugAdapter(
          fileSystem: fs,
          platform: platform,
        );
      });

      test('dart:ui URI to file path', () async {
        expect(
          adapter.convertOrgDartlangSdkToPath(Uri.parse('org-dartlang-sdk:///flutter/lib/ui/ui.dart')),
          fs.path.join(flutterRoot, 'bin', 'cache', 'pkg', 'sky_engine', 'lib', 'ui', 'ui.dart'),
        );
      });

      test('dart:ui file path to URI', () async {
        expect(
          adapter.convertPathToOrgDartlangSdk(fs.path.join(flutterRoot, 'bin', 'cache', 'pkg', 'sky_engine', 'lib', 'ui', 'ui.dart')),
          Uri.parse('org-dartlang-sdk:///flutter/lib/ui/ui.dart'),
        );
      });

      test('dart:core URI to file path', () async {
        expect(
          adapter.convertOrgDartlangSdkToPath(Uri.parse('org-dartlang-sdk:///third_party/dart/sdk/lib/core/core.dart')),
          fs.path.join(flutterRoot, 'bin', 'cache', 'pkg', 'sky_engine', 'lib', 'core', 'core.dart'),
        );
      });

      test('dart:core file path to URI', () async {
        expect(
          adapter.convertPathToOrgDartlangSdk(fs.path.join(flutterRoot, 'bin', 'cache', 'pkg', 'sky_engine', 'lib', 'core', 'core.dart')),
          Uri.parse('org-dartlang-sdk:///third_party/dart/sdk/lib/core/core.dart'),
        );
      });
    });

    group('includes customTool', () {
      test('with no args replaced', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          customTool: '/custom/flutter',
          noDebug: true,
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> responseCompleter = Completer<void>();
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.executable, equals('/custom/flutter'));
        // args should be in-tact
        expect(adapter.processArgs, contains('--machine'));
      });

      test('with all args replaced', () async {
        final MockFlutterDebugAdapter adapter = MockFlutterDebugAdapter(
          fileSystem: MemoryFileSystem.test(style: fsStyle),
          platform: platform,
        );
        final FlutterLaunchRequestArguments args = FlutterLaunchRequestArguments(
          cwd: '/project',
          program: 'foo.dart',
          customTool: '/custom/flutter',
          customToolReplacesArgs: 9999, // replaces all built-in args
          noDebug: true,
          toolArgs: <String>['tool_args'], // should still be in args
        );

        await adapter.configurationDoneRequest(MockRequest(), null, () {});
        final Completer<void> responseCompleter = Completer<void>();
        await adapter.launchRequest(MockRequest(), args, responseCompleter.complete);
        await responseCompleter.future;

        expect(adapter.executable, equals('/custom/flutter'));
        // normal built-in args are replaced by customToolReplacesArgs, but
        // user-provided toolArgs are not.
        expect(adapter.processArgs, isNot(contains('--machine')));
        expect(adapter.processArgs, contains('tool_args'));
      });
    });
  });
}

class _FakeVm extends Fake implements VM {
  _FakeVm({this.pid = 1});

  @override
  final int pid;
}
