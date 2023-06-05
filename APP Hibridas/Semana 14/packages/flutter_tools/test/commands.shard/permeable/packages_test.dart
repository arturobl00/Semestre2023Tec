// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(gspencergoog): Remove this tag once this test's state leaks/test
// dependencies have been fixed.
// https://github.com/flutter/flutter/issues/85160
// Fails with "flutter test --test-randomize-ordering-seed=1000"
@Tags(<String>['no-shuffle'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:args/command_runner.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/error_handling_io.dart';
import 'package:flutter_tools/src/base/file_system.dart' hide IOSink;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/commands/packages.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/globals.dart' as globals;

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';
import '../../src/test_flutter_command_runner.dart';

void main() {
  late FakeStdio mockStdio;

  setUp(() {
    mockStdio = FakeStdio()..stdout.terminalColumns = 80;
  });

  Cache.disableLocking();
  group('packages get/upgrade', () {
    late Directory tempDir;

    setUp(() {
      tempDir = globals.fs.systemTempDirectory.createTempSync('flutter_tools_packages_test.');
    });

    tearDown(() {
      tryToDelete(tempDir);
    });

    Future<String> createProjectWithPlugin(String plugin, { List<String>? arguments }) async {
      final String projectPath = await createProject(tempDir, arguments: arguments);
      final File pubspec = globals.fs.file(globals.fs.path.join(projectPath, 'pubspec.yaml'));
      String content = await pubspec.readAsString();
      final List<String> contentLines = LineSplitter.split(content).toList();
      final int depsIndex = contentLines.indexOf('dependencies:');
      expect(depsIndex, isNot(-1));
      contentLines.replaceRange(depsIndex, depsIndex + 1, <String>[
        'dependencies:',
        '  $plugin:',
      ]);
      content = contentLines.join('\n');
      await pubspec.writeAsString(content, flush: true);
      return projectPath;
    }

    Future<PackagesCommand> runCommandIn(String projectPath, String verb, { List<String>? args }) async {
      final PackagesCommand command = PackagesCommand();
      final CommandRunner<void> runner = createTestCommandRunner(command);
      await runner.run(<String>[
        'packages',
        verb,
        ...?args,
        '--directory',
        projectPath,
      ]);
      return command;
    }

    void expectExists(String projectPath, String relPath) {
      expect(
        globals.fs.isFileSync(globals.fs.path.join(projectPath, relPath)),
        true,
        reason: '$projectPath/$relPath should exist, but does not',
      );
    }

    void expectContains(String projectPath, String relPath, String substring) {
      expectExists(projectPath, relPath);
      expect(
        globals.fs.file(globals.fs.path.join(projectPath, relPath)).readAsStringSync(),
        contains(substring),
        reason: '$projectPath/$relPath has unexpected content',
      );
    }

    void expectNotExists(String projectPath, String relPath) {
      expect(
        globals.fs.isFileSync(globals.fs.path.join(projectPath, relPath)),
        false,
        reason: '$projectPath/$relPath should not exist, but does',
      );
    }

    void expectNotContains(String projectPath, String relPath, String substring) {
      expectExists(projectPath, relPath);
      expect(
        globals.fs.file(globals.fs.path.join(projectPath, relPath)).readAsStringSync(),
        isNot(contains(substring)),
        reason: '$projectPath/$relPath has unexpected content',
      );
    }

    final List<String> pubOutput = <String>[
      globals.fs.path.join('.dart_tool', 'package_config.json'),
      'pubspec.lock',
    ];

    const List<String> pluginRegistrants = <String>[
      'ios/Runner/GeneratedPluginRegistrant.h',
      'ios/Runner/GeneratedPluginRegistrant.m',
      'android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
    ];

    const List<String> modulePluginRegistrants = <String>[
      '.ios/Flutter/FlutterPluginRegistrant/Classes/GeneratedPluginRegistrant.h',
      '.ios/Flutter/FlutterPluginRegistrant/Classes/GeneratedPluginRegistrant.m',
      '.android/Flutter/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java',
    ];

    const List<String> pluginWitnesses = <String>[
      '.flutter-plugins',
      'ios/Podfile',
    ];

    const List<String> modulePluginWitnesses = <String>[
      '.flutter-plugins',
      '.ios/Podfile',
    ];

    const Map<String, String> pluginContentWitnesses = <String, String>{
      'ios/Flutter/Debug.xcconfig': '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"',
      'ios/Flutter/Release.xcconfig': '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"',
    };

    const Map<String, String> modulePluginContentWitnesses = <String, String>{
      '.ios/Config/Debug.xcconfig': '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.debug.xcconfig"',
      '.ios/Config/Release.xcconfig': '#include? "Pods/Target Support Files/Pods-Runner/Pods-Runner.release.xcconfig"',
    };

    void expectDependenciesResolved(String projectPath) {
      for (final String output in pubOutput) {
        expectExists(projectPath, output);
      }
    }

    void expectZeroPluginsInjected(String projectPath) {
      for (final String registrant in modulePluginRegistrants) {
        expectExists(projectPath, registrant);
      }
      for (final String witness in pluginWitnesses) {
        expectNotExists(projectPath, witness);
      }
      modulePluginContentWitnesses.forEach((String witness, String content) {
        expectNotContains(projectPath, witness, content);
      });
    }

    void expectPluginInjected(String projectPath) {
      for (final String registrant in pluginRegistrants) {
        expectExists(projectPath, registrant);
      }
      for (final String witness in pluginWitnesses) {
        expectExists(projectPath, witness);
      }
      pluginContentWitnesses.forEach((String witness, String content) {
        expectContains(projectPath, witness, content);
      });
    }

    void expectModulePluginInjected(String projectPath) {
      for (final String registrant in modulePluginRegistrants) {
        expectExists(projectPath, registrant);
      }
      for (final String witness in modulePluginWitnesses) {
        expectExists(projectPath, witness);
      }
      modulePluginContentWitnesses.forEach((String witness, String content) {
        expectContains(projectPath, witness, content);
      });
    }

    void removeGeneratedFiles(String projectPath) {
      final Iterable<String> allFiles = <List<String>>[
        pubOutput,
        modulePluginRegistrants,
        pluginWitnesses,
      ].expand<String>((List<String> list) => list);
      for (final String path in allFiles) {
        final File file = globals.fs.file(globals.fs.path.join(projectPath, path));
        ErrorHandlingFileSystem.deleteIfExists(file);
      }
    }

    testUsingContext('get fetches packages and has output from pub', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'get');

      expect(mockStdio.stdout.writes.map(utf8.decode),
        allOf(
          contains(matches(RegExp(r'Resolving dependencies in .+flutter_project\.\.\.'))),
          contains(matches(RegExp(r'\+ flutter 0\.0\.0 from sdk flutter'))),
          contains(matches(RegExp(r'Changed \d+ dependencies in .+flutter_project!'))),
        ),
      );

      expectDependenciesResolved(projectPath);
      expectZeroPluginsInjected(projectPath);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('get --offline fetches packages', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'get', args: <String>['--offline']);

      expectDependenciesResolved(projectPath);
      expectZeroPluginsInjected(projectPath);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('set no plugins as usage value', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      final PackagesCommand command = await runCommandIn(projectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get']! as PackagesGetCommand;

      expect((await getCommand.usageValues).commandPackagesNumberPlugins, 0);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('set the number of plugins as usage value', () async {
      final String projectPath = await createProject(
        tempDir,
        arguments: <String>['--template=plugin', '--no-pub', '--platforms=ios,android,macos,windows'],
      );
      final String exampleProjectPath = globals.fs.path.join(projectPath, 'example');

      final PackagesCommand command = await runCommandIn(exampleProjectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get']! as PackagesGetCommand;

      // A plugin example depends on the plugin itself, and integration_test.
      expect((await getCommand.usageValues).commandPackagesNumberPlugins, 2);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('indicate that the project is not a module in usage value', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub']);
      removeGeneratedFiles(projectPath);

      final PackagesCommand command = await runCommandIn(projectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get']! as PackagesGetCommand;

      expect((await getCommand.usageValues).commandPackagesProjectModule, false);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('indicate that the project is a module in usage value', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      final PackagesCommand command = await runCommandIn(projectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get']! as PackagesGetCommand;

      expect((await getCommand.usageValues).commandPackagesProjectModule, true);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('indicate that Android project reports v1 in usage value', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub']);
      removeGeneratedFiles(projectPath);

      final File androidManifest = globals.fs.file(globals.fs.path.join(
        projectPath,
        'android/app/src/main/AndroidManifest.xml',
      ));
      final String updatedAndroidManifestString =
          androidManifest.readAsStringSync().replaceAll('android:value="2"', 'android:value="1"');

      androidManifest.writeAsStringSync(updatedAndroidManifestString);

      final PackagesCommand command = await runCommandIn(projectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get']! as PackagesGetCommand;

      expect((await getCommand.usageValues).commandPackagesAndroidEmbeddingVersion, 'v1');
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('indicate that Android project reports v2 in usage value', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub']);
      removeGeneratedFiles(projectPath);

      final PackagesCommand command = await runCommandIn(projectPath, 'get');
      final PackagesGetCommand getCommand = command.subcommands['get']! as PackagesGetCommand;

      expect((await getCommand.usageValues).commandPackagesAndroidEmbeddingVersion, 'v2');
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('upgrade fetches packages', () async {
      final String projectPath = await createProject(tempDir,
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'upgrade');

      expectDependenciesResolved(projectPath);
      expectZeroPluginsInjected(projectPath);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('get fetches packages and injects plugin', () async {
      final String projectPath = await createProjectWithPlugin('path_provider',
        arguments: <String>['--no-pub', '--template=module']);
      removeGeneratedFiles(projectPath);

      await runCommandIn(projectPath, 'get');

      expectDependenciesResolved(projectPath);
      expectModulePluginInjected(projectPath);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('get fetches packages and injects plugin in plugin project', () async {
      final String projectPath = await createProject(
        tempDir,
        arguments: <String>['--template=plugin', '--no-pub', '--platforms=ios,android'],
      );
      final String exampleProjectPath = globals.fs.path.join(projectPath, 'example');
      removeGeneratedFiles(projectPath);
      removeGeneratedFiles(exampleProjectPath);

      await runCommandIn(projectPath, 'get');

      expectDependenciesResolved(projectPath);

      await runCommandIn(exampleProjectPath, 'get');

      expectDependenciesResolved(exampleProjectPath);
      expectPluginInjected(exampleProjectPath);
    }, overrides: <Type, Generator>{
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });
  });

  group('packages test/pub', () {
    late FakeProcessManager processManager;
    late FakeStdio mockStdio;

    setUp(() {
      processManager = FakeProcessManager.empty();
      mockStdio = FakeStdio()..stdout.terminalColumns = 80;
    });

    testUsingContext('test without bot', () async {
      Cache.flutterRoot = '';
      globals.fs.directory('/packages/flutter_tools').createSync(recursive: true);
      globals.fs.file('pubspec.yaml').createSync();
      processManager.addCommand(
        const FakeCommand(command: <String>['/bin/cache/dart-sdk/bin/dart', 'pub', '--suppress-analytics', 'run', 'test']),
      );
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'test']);

      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(environment: <String, String>{}),
      ProcessManager: () => processManager,
      Stdio: () => mockStdio,
      BotDetector: () => const FakeBotDetector(false),
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('test with bot', () async {
      Cache.flutterRoot = '';
      globals.fs.file('pubspec.yaml').createSync();
      processManager.addCommand(
        const FakeCommand(command: <String>['/bin/cache/dart-sdk/bin/dart', 'pub', '--suppress-analytics', '--trace', 'run', 'test']),
      );
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', 'test']);

      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(environment: <String, String>{}),
      ProcessManager: () => processManager,
      Stdio: () => mockStdio,
      BotDetector: () => const FakeBotDetector(true),
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('run pass arguments through to pub', () async {
      Cache.flutterRoot = '';
      globals.fs.file('pubspec.yaml').createSync();
      final IOSink stdin = IOSink(StreamController<List<int>>().sink);
      processManager.addCommand(
        FakeCommand(
          command: const <String>[
            '/bin/cache/dart-sdk/bin/dart', 'pub', '--suppress-analytics', 'run', '--foo', 'bar',
          ],
          stdin: stdin,
        ),
      );
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', '--verbose', 'pub', 'run', '--foo', 'bar']);

      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(environment: <String, String>{}),
      ProcessManager: () => processManager,
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('token pass arguments through to pub', () async {
      Cache.flutterRoot = '';
      globals.fs.file('pubspec.yaml').createSync();
      final IOSink stdin = IOSink(StreamController<List<int>>().sink);
      processManager.addCommand(
        FakeCommand(
          command: const <String>[
            '/bin/cache/dart-sdk/bin/dart', 'pub', '--suppress-analytics', 'token', 'list',
          ],
          stdin: stdin,
        ),
      );
      await createTestCommandRunner(PackagesCommand()).run(<String>['packages', '--verbose', 'pub', 'token', 'list']);

      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(environment: <String, String>{}),
      ProcessManager: () => processManager,
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });

    testUsingContext('upgrade does not check for pubspec.yaml if -h/--help is passed', () async {
      Cache.flutterRoot = '';
      processManager.addCommand(
        FakeCommand(
          command: const <String>[
            '/bin/cache/dart-sdk/bin/dart', 'pub', '--suppress-analytics', 'upgrade', '-h',
          ],
          stdin:  IOSink(StreamController<List<int>>().sink),
        ),
      );
      await createTestCommandRunner(PackagesCommand()).run(<String>['pub', 'upgrade', '-h']);

      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      FileSystem: () => MemoryFileSystem.test(),
      Platform: () => FakePlatform(environment: <String, String>{}),
      ProcessManager: () => processManager,
      Stdio: () => mockStdio,
      Pub: () => Pub.test(
        fileSystem: globals.fs,
        logger: globals.logger,
        processManager: globals.processManager,
        usage: globals.flutterUsage,
        botDetector: globals.botDetector,
        platform: globals.platform,
        stdio: mockStdio,
      ),
    });
  });
}
