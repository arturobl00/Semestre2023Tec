// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/terminal.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:flutter_tools/src/runner/flutter_command_runner.dart';
import 'package:flutter_tools/src/version.dart';

import '../../src/context.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';
import 'utils.dart';

const String _kFlutterRoot = '/flutter/flutter';
const String _kProjectRoot = '/project';

void main() {
  group('FlutterCommandRunner', () {
    late MemoryFileSystem fileSystem;
    late Platform platform;

    setUpAll(() {
      Cache.disableLocking();
    });

    setUp(() {
      fileSystem = MemoryFileSystem.test();
      fileSystem.directory(_kFlutterRoot).createSync(recursive: true);
      fileSystem.directory(_kProjectRoot).createSync(recursive: true);
      fileSystem.currentDirectory = _kProjectRoot;

      platform = FakePlatform(
        environment: <String, String>{
          'FLUTTER_ROOT': _kFlutterRoot,
        },
        version: '1 2 3 4 5',
      );
    });

    group('run', () {
      testUsingContext('checks that Flutter installation is up-to-date', () async {
        final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
        final FakeFlutterVersion version = globals.flutterVersion as FakeFlutterVersion;

        await runner.run(<String>['dummy']);

        expect(version.didCheckFlutterVersionFreshness, true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
        FlutterVersion: () => FakeFlutterVersion(),
        BotDetector: () => const FakeBotDetector(false),
        OutputPreferences: () => OutputPreferences.test(),
      });

      testUsingContext('does not check that Flutter installation is up-to-date with --machine flag', () async {
        final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
        final FakeFlutterVersion version = globals.flutterVersion as FakeFlutterVersion;

        await runner.run(<String>['dummy', '--machine', '--version']);

        expect(version.didCheckFlutterVersionFreshness, false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
        FlutterVersion: () => FakeFlutterVersion(),
        OutputPreferences: () => OutputPreferences.test(),
      });

      testUsingContext('does not check that Flutter installation is up-to-date with CI=true in environment', () async {
        final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
        final FakeFlutterVersion version = globals.flutterVersion as FakeFlutterVersion;

        await runner.run(<String>['dummy', '--version']);

        expect(version.didCheckFlutterVersionFreshness, false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
        BotDetector: () => const FakeBotDetector(true),
      }, initializeFlutterRoot: false);

      testUsingContext('checks that Flutter installation is up-to-date with CI=true and --machine when explicit --version-check', () async {
        final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
        final FakeFlutterVersion version = globals.flutterVersion as FakeFlutterVersion;

        await runner.run(<String>['dummy', '--version', '--machine', '--version-check']);

         expect(version.didCheckFlutterVersionFreshness, true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
        BotDetector: () => const FakeBotDetector(true),
      }, initializeFlutterRoot: false);

      testUsingContext('checks that Flutter installation is up-to-date if shell completion to terminal', () async {
        final FlutterCommand command = DummyFlutterCommand(name: 'bash-completion');
        final FlutterCommandRunner runner = createTestCommandRunner(command) as FlutterCommandRunner;
        final FakeFlutterVersion version = globals.flutterVersion as FakeFlutterVersion;

        await runner.run(<String>['bash-completion']);

        expect(version.didCheckFlutterVersionFreshness, true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
        FlutterVersion: () => FakeFlutterVersion(),
        BotDetector: () => const FakeBotDetector(false),
        Stdio: () => FakeStdio(hasFakeTerminal: true),
      });

      testUsingContext('does not check that Flutter installation is up-to-date if redirecting shell completion', () async {
        final FlutterCommand command = DummyFlutterCommand(name: 'bash-completion');
        final FlutterCommandRunner runner = createTestCommandRunner(command) as FlutterCommandRunner;
        final FakeFlutterVersion version = globals.flutterVersion as FakeFlutterVersion;

        await runner.run(<String>['bash-completion']);

        expect(version.didCheckFlutterVersionFreshness, false);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
        FlutterVersion: () => FakeFlutterVersion(),
        BotDetector: () => const FakeBotDetector(false),
        Stdio: () => FakeStdio(hasFakeTerminal: false),
      });

      testUsingContext('Fetches tags when --version is used', () async {
        final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
        final FakeFlutterVersion version = globals.flutterVersion as FakeFlutterVersion;

        await runner.run(<String>['--version']);

        expect(version.didFetchTagsAndUpdate, true);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
        FlutterVersion: () => FakeFlutterVersion(),
        OutputPreferences: () => OutputPreferences.test(),
      });

    testUsingContext("Doesn't crash on invalid .packages file", () async {
      final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
      fileSystem.file('pubspec.yaml').createSync();
      fileSystem.file('.packages')
        ..createSync()
        ..writeAsStringSync('Not a valid package');

      await runner.run(<String>['dummy']);

    }, overrides: <Type, Generator>{
      FileSystem: () => fileSystem,
      ProcessManager: () => FakeProcessManager.any(),
      Platform: () => platform,
      OutputPreferences: () => OutputPreferences.test(),
    });

    group('getRepoPackages', () {
      late String? oldFlutterRoot;

      setUp(() {
        oldFlutterRoot = Cache.flutterRoot;
        Cache.flutterRoot = _kFlutterRoot;
        fileSystem.directory(fileSystem.path.join(_kFlutterRoot, 'examples'))
            .createSync(recursive: true);
        fileSystem.directory(fileSystem.path.join(_kFlutterRoot, 'packages'))
            .createSync(recursive: true);
        fileSystem.directory(fileSystem.path.join(_kFlutterRoot, 'dev', 'tools', 'aatool'))
            .createSync(recursive: true);

        fileSystem.file(fileSystem.path.join(_kFlutterRoot, 'dev', 'tools', 'pubspec.yaml'))
            .createSync();
        fileSystem.file(fileSystem.path.join(_kFlutterRoot, 'dev', 'tools', 'aatool', 'pubspec.yaml'))
            .createSync();
      });

      tearDown(() {
        Cache.flutterRoot = oldFlutterRoot;
      });

      testUsingContext('', () {
        final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
        final List<String> packagePaths = runner.getRepoPackages()
          .map((Directory d) => d.path).toList();
        expect(packagePaths, <String>[
          fileSystem.directory(fileSystem.path.join(_kFlutterRoot, 'dev', 'tools', 'aatool')).path,
          fileSystem.directory(fileSystem.path.join(_kFlutterRoot, 'dev', 'tools')).path,
        ]);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Platform: () => platform,
        FlutterVersion: () => FakeFlutterVersion(),
        OutputPreferences: () => OutputPreferences.test(),
      });
    });

    group('wrapping', () {
      testUsingContext('checks that output wrapping is turned on when writing to a terminal', () async {
        final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
        final FakeFlutterCommand fakeCommand = FakeFlutterCommand();
        runner.addCommand(fakeCommand);
        await runner.run(<String>['fake']);
        expect(fakeCommand.preferences.wrapText, isTrue);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => FakeStdio(hasFakeTerminal: true),
        OutputPreferences: () => OutputPreferences.test(),
      }, initializeFlutterRoot: false);

      testUsingContext('checks that output wrapping is turned off when not writing to a terminal', () async {
        final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
        final FakeFlutterCommand fakeCommand = FakeFlutterCommand();
        runner.addCommand(fakeCommand);
        await runner.run(<String>['fake']);
        expect(fakeCommand.preferences.wrapText, isFalse);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => FakeStdio(hasFakeTerminal: false),
        OutputPreferences: () => OutputPreferences.test(),
      }, initializeFlutterRoot: false);

      testUsingContext('checks that output wrapping is turned off when set on the command line and writing to a terminal', () async {
        final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
        final FakeFlutterCommand fakeCommand = FakeFlutterCommand();
        runner.addCommand(fakeCommand);
        await runner.run(<String>['--no-wrap', 'fake']);
        expect(fakeCommand.preferences.wrapText, isFalse);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => FakeStdio(hasFakeTerminal: true),
        OutputPreferences: () => OutputPreferences.test(),
      }, initializeFlutterRoot: false);

      testUsingContext('checks that output wrapping is turned on when set on the command line, but not writing to a terminal', () async {
        final FlutterCommandRunner runner = createTestCommandRunner(DummyFlutterCommand()) as FlutterCommandRunner;
        final FakeFlutterCommand fakeCommand = FakeFlutterCommand();
        runner.addCommand(fakeCommand);
        await runner.run(<String>['--wrap', 'fake']);
        expect(fakeCommand.preferences.wrapText, isTrue);
      }, overrides: <Type, Generator>{
        FileSystem: () => fileSystem,
        ProcessManager: () => FakeProcessManager.any(),
        Stdio: () => FakeStdio(hasFakeTerminal: false),
        OutputPreferences: () => OutputPreferences.test(),
      }, initializeFlutterRoot: false);
    });
  });
  });
}

class FakeFlutterCommand extends FlutterCommand {
  late OutputPreferences preferences;

  @override
  Future<FlutterCommandResult> runCommand() {
    preferences = globals.outputPreferences;
    return Future<FlutterCommandResult>.value(const FlutterCommandResult(ExitStatus.success));
  }

  @override
  String get description => '';

  @override
  String get name => 'fake';
}

class FakeStdio extends Stdio {
  FakeStdio({required this.hasFakeTerminal});

  final bool hasFakeTerminal;

  @override
  bool get hasTerminal => hasFakeTerminal;

  @override
  int? get terminalColumns => hasFakeTerminal ? 80 : null;

  @override
  int? get terminalLines => hasFakeTerminal ? 24 : null;
  @override
  bool get supportsAnsiEscapes => hasFakeTerminal;
}
