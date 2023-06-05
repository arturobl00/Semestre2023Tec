// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:args/args.dart';

import '../base/common.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../build_system/build_system.dart';
import '../cache.dart';
import '../dart/generate_synthetic_packages.dart';
import '../dart/pub.dart';
import '../flutter_plugins.dart';
import '../globals.dart' as globals;
import '../plugins.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart';

/// The function signature of the [print] function.
typedef PrintFn = void Function(Object?);

class PackagesCommand extends FlutterCommand {
  PackagesCommand({
    PrintFn usagePrintFn = print,
  }) : _usagePrintFn = usagePrintFn
  {
    addSubcommand(PackagesGetCommand('get', "Get the current package's dependencies.", PubContext.pubGet));
    addSubcommand(PackagesGetCommand('upgrade', "Upgrade the current package's dependencies to latest versions.", PubContext.pubUpgrade));
    addSubcommand(PackagesGetCommand('add', 'Add a dependency to pubspec.yaml.', PubContext.pubAdd));
    addSubcommand(PackagesGetCommand('remove', 'Removes a dependency from the current package.', PubContext.pubRemove));
    addSubcommand(PackagesTestCommand());
    addSubcommand(PackagesForwardCommand('publish', 'Publish the current package to pub.dartlang.org.', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('downgrade', 'Downgrade packages in a Flutter project.', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('deps', 'Print package dependencies.')); // path to package can be specified with --directory argument
    addSubcommand(PackagesForwardCommand('run', 'Run an executable from a package.', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('cache', 'Work with the Pub system cache.'));
    addSubcommand(PackagesForwardCommand('version', 'Print Pub version.'));
    addSubcommand(PackagesForwardCommand('uploader', 'Manage uploaders for a package on pub.dev.'));
    addSubcommand(PackagesForwardCommand('login', 'Log into pub.dev.'));
    addSubcommand(PackagesForwardCommand('logout', 'Log out of pub.dev.'));
    addSubcommand(PackagesForwardCommand('global', 'Work with Pub global packages.'));
    addSubcommand(PackagesForwardCommand('outdated', 'Analyze dependencies to find which ones can be upgraded.', requiresPubspec: true));
    addSubcommand(PackagesForwardCommand('token', 'Manage authentication tokens for hosted pub repositories.'));
    addSubcommand(PackagesPassthroughCommand());
  }

  final PrintFn _usagePrintFn;

  @override
  final String name = 'pub';

  @override
  List<String> get aliases => const <String>['packages'];

  @override
  final String description = 'Commands for managing Flutter packages.';

  @override
  String get category => FlutterCommandCategory.project;

  @override
  Future<FlutterCommandResult> runCommand() async => FlutterCommandResult.fail();

  @override
  void printUsage() => _usagePrintFn(usage);
}

class PackagesTestCommand extends FlutterCommand {
  PackagesTestCommand() {
    requiresPubspecYaml();
  }

  @override
  String get name => 'test';

  @override
  String get description {
    return 'Run the "test" package.\n'
           'This is similar to "flutter test", but instead of hosting the tests in the '
           'flutter environment it hosts the tests in a pure Dart environment. The main '
           'differences are that the "dart:ui" library is not available and that tests '
           'run faster. This is helpful for testing libraries that do not depend on any '
           'packages from the Flutter SDK. It is equivalent to "pub run test".';
  }

  @override
  String get invocation {
    return '${runner!.executableName} pub test [<tests...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    await pub.batch(<String>['run', 'test', ...argResults!.rest], context: PubContext.runTest);
    return FlutterCommandResult.success();
  }
}

class PackagesForwardCommand extends FlutterCommand {
  PackagesForwardCommand(this._commandName, this._description, {bool requiresPubspec = false}) {
    if (requiresPubspec) {
      requiresPubspecYaml();
    }
  }

  PubContext context = PubContext.pubForward;

  @override
  ArgParser argParser = ArgParser.allowAnything();

  final String _commandName;
  final String _description;

  @override
  String get name => _commandName;

  @override
  String get description {
    return '$_description\n'
           'This runs the "pub" tool in a Flutter context.';
  }

  @override
  String get invocation {
    return '${runner!.executableName} pub $_commandName [<arguments...>]';
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    final List<String> subArgs = argResults!.rest.toList()
      ..removeWhere((String arg) => arg == '--');
    await pub.interactively(
      <String>[ _commandName, ...subArgs],
      context: context,
      command: _commandName,
    );
    return FlutterCommandResult.success();
  }
}

class PackagesPassthroughCommand extends FlutterCommand {
  @override
  ArgParser argParser = ArgParser.allowAnything();

  @override
  String get name => 'pub';

  @override
  String get description {
    return 'Pass the remaining arguments to Dart\'s "pub" tool.\n'
           'This runs the "pub" tool in a Flutter context.';
  }

  @override
  String get invocation {
    return '${runner!.executableName} packages pub [<arguments...>]';
  }

  static final PubContext _context = PubContext.pubPassThrough;

  @override
  Future<FlutterCommandResult> runCommand() async {
    await pub.interactively(
      command: 'pub',
      argResults!.rest,
      context: _context,
    );
    return FlutterCommandResult.success();
  }
}

/// Represents the pub sub-commands that makes package-resolutions.
class PackagesGetCommand extends FlutterCommand {
  PackagesGetCommand(this._commandName, this._description, this._context);

  @override
  ArgParser argParser = ArgParser.allowAnything();

  final String _commandName;
  final String _description;
  final PubContext _context;

  FlutterProject? _rootProject;

  @override
  String get name => _commandName;

  @override
  String get description {
    return '$_description\n'
           'This runs the "pub" tool in a Flutter context.';
  }

  @override
  String get invocation {
    return '${runner!.executableName} pub $_commandName [<arguments...>]';
  }

  /// An [ArgParser] that accepts all options and flags that the
  ///
  /// `pub get`
  /// `pub upgrade`
  /// `pub downgrade`
  /// `pub add`
  /// `pub remove`
  ///
  /// commands accept.
  ArgParser get _permissiveArgParser {
    final ArgParser argParser = ArgParser();
    argParser.addOption('directory', abbr: 'C');
    argParser.addFlag('offline');
    argParser.addFlag('dry-run', abbr: 'n');
    argParser.addFlag('help', abbr: 'h');
    argParser.addFlag('enforce-lockfile');
    argParser.addFlag('precompile');
    argParser.addFlag('major-versions');
    argParser.addFlag('null-safety');
    argParser.addFlag('example', defaultsTo: true);
    argParser.addOption('sdk');
    argParser.addOption('path');
    argParser.addOption('hosted-url');
    argParser.addOption('git-url');
    argParser.addOption('git-ref');
    argParser.addOption('git-path');
    argParser.addFlag('dev');
    argParser.addFlag('verbose', abbr: 'v');
    return argParser;
  }

  @override
  Future<FlutterCommandResult> runCommand() async {
    List<String> rest = argResults!.rest;
    bool isHelp = false;
    bool example = true;
    bool exampleWasParsed = false;
    String? directoryOption;
    bool dryRun = false;
    try {
      final ArgResults results = _permissiveArgParser.parse(rest);
      isHelp = results['help'] as bool;
      directoryOption = results['directory'] as String?;
      example = results['example'] as bool;
      exampleWasParsed = results.wasParsed('example');
      dryRun = results['dry-run'] as bool;
    } on ArgParserException {
      // Let pub give the error message.
    }
    String? target;
    FlutterProject? rootProject;

    if (!isHelp) {
      if (directoryOption == null &&
          rest.length == 1 &&
          // Anything that looks like an argument should not be interpreted as
          // a directory.
          !rest.single.startsWith('-') &&
          ((rest.single.contains('/') || rest.single.contains(r'\')) ||
            name == 'get')) {
        // For historical reasons, if there is one argument to the command and it contains
        // a multiple-component path (i.e. contains a slash) then we use that to determine
        // to which project we're applying the command.
        target = findProjectRoot(globals.fs, rest.single);

        globals.printWarning('''
  Using a naked argument for directory is deprecated and will stop working in a future Flutter release.

  Use --directory instead.''');
        if (target == null) {
          throwToolExit('Expected to find project root in ${rest.single}.');
        }
        rest = <String>[];
      } else {
        target = findProjectRoot(globals.fs, directoryOption);
        if (target == null) {
          if (directoryOption == null) {
            throwToolExit('Expected to find project root in current working directory.');
          } else {
            throwToolExit('Expected to find project root in $directoryOption.');
          }
        }
      }

      rootProject = FlutterProject.fromDirectory(globals.fs.directory(target));
      _rootProject = rootProject;

      if (rootProject.manifest.generateSyntheticPackage) {
        final Environment environment = Environment(
          artifacts: globals.artifacts!,
          logger: globals.logger,
          cacheDir: globals.cache.getRoot(),
          engineVersion: globals.flutterVersion.engineRevision,
          fileSystem: globals.fs,
          flutterRootDir: globals.fs.directory(Cache.flutterRoot),
          outputDir: globals.fs.directory(getBuildDirectory()),
          processManager: globals.processManager,
          platform: globals.platform,
          usage: globals.flutterUsage,
          projectDir: rootProject.directory,
          generateDartPluginRegistry: true,
        );

        await generateLocalizationsSyntheticPackage(
          environment: environment,
          buildSystem: globals.buildSystem,
        );
      }
    }
    final String? relativeTarget = target == null ? null : globals.fs.path.relative(target);

    final List<String> subArgs = rest.toList()..removeWhere((String arg) => arg == '--');
    final Stopwatch timer = Stopwatch()..start();
    try {
      await pub.interactively(
        <String>[
          name,
          ...subArgs,
          // `dart pub get` and friends defaults to `--no-example`.
          if (!exampleWasParsed && target != null) '--example',
          if (directoryOption == null && relativeTarget != null) ...<String>['--directory', relativeTarget],
        ],
        project: rootProject,
        context: _context,
        command: name,
        touchesPackageConfig: !(isHelp || dryRun),
      );
      globals.flutterUsage.sendTiming('pub', 'get', timer.elapsed, label: 'success');
    // Not limiting to catching Exception because the exception is rethrown.
    } catch (_) { // ignore: avoid_catches_without_on_clauses
      globals.flutterUsage.sendTiming('pub', 'get', timer.elapsed, label: 'failure');
      rethrow;
    }

    if (rootProject != null) {
      // We need to regenerate the platform specific tooling for both the project
      // itself and example(if present).
      await rootProject.regeneratePlatformSpecificTooling();
      if (example && rootProject.hasExampleApp && rootProject.example.pubspecFile.existsSync()) {
        final FlutterProject exampleProject = rootProject.example;
        await exampleProject.regeneratePlatformSpecificTooling();
      }
    }

    return FlutterCommandResult.success();
  }

  /// The pub packages usage values are incorrect since these are calculated/sent
  /// before pub get completes. This needs to be performed after dependency resolution.
  @override
  Future<CustomDimensions> get usageValues async {
    final FlutterProject? rootProject = _rootProject;
    if (rootProject == null) {
      return const CustomDimensions();
    }

    int numberPlugins;
    // Do not send plugin analytics if pub has not run before.
    final bool hasPlugins = rootProject.flutterPluginsDependenciesFile.existsSync()
      && rootProject.packageConfigFile.existsSync();
    if (hasPlugins) {
      // Do not fail pub get if package config files are invalid before pub has
      // had a chance to run.
      final List<Plugin> plugins = await findPlugins(rootProject, throwOnError: false);
      numberPlugins = plugins.length;
    } else {
      numberPlugins = 0;
    }

    return CustomDimensions(
      commandPackagesNumberPlugins: numberPlugins,
      commandPackagesProjectModule: rootProject.isModule,
      commandPackagesAndroidEmbeddingVersion: rootProject.android.getEmbeddingVersion().toString().split('.').last,
    );
  }
}
