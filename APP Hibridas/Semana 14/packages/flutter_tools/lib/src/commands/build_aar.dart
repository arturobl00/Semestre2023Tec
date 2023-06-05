// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../android/android_builder.dart';
import '../android/android_sdk.dart';
import '../android/gradle_utils.dart';
import '../base/common.dart';
import '../base/file_system.dart';
import '../base/os.dart';
import '../build_info.dart';
import '../cache.dart';
import '../project.dart';
import '../reporting/reporting.dart';
import '../runner/flutter_command.dart' show FlutterCommandResult;
import 'build.dart';

class BuildAarCommand extends BuildSubCommand {
  BuildAarCommand({
    required super.logger,
    required AndroidSdk? androidSdk,
    required FileSystem fileSystem,
    required bool verboseHelp,
  }): _androidSdk = androidSdk,
      _fileSystem = fileSystem,
      super(verboseHelp: verboseHelp) {
    argParser
      ..addFlag(
        'debug',
        defaultsTo: true,
        help: 'Build a debug version of the current project.',
      )
      ..addFlag(
        'profile',
        defaultsTo: true,
        help: 'Build a version of the current project specialized for performance profiling.',
      )
      ..addFlag(
        'release',
        defaultsTo: true,
        help: 'Build a release version of the current project.',
      );
    addTreeShakeIconsFlag();
    usesFlavorOption();
    usesBuildNumberOption();
    usesOutputDir();
    usesPubOption();
    addSplitDebugInfoOption();
    addDartObfuscationOption();
    usesDartDefineOption();
    usesExtraDartFlagOptions(verboseHelp: verboseHelp);
    usesTrackWidgetCreation(verboseHelp: false);
    addNullSafetyModeOptions(hide: !verboseHelp);
    addEnableExperimentation(hide: !verboseHelp);
    addAndroidSpecificBuildOptions(hide: !verboseHelp);
    argParser
      .addMultiOption(
        'target-platform',
        defaultsTo: <String>['android-arm', 'android-arm64', 'android-x64'],
        allowed: <String>['android-arm', 'android-arm64', 'android-x86', 'android-x64'],
        help: 'The target platform for which the project is compiled.',
      );
  }
  final AndroidSdk? _androidSdk;
  final FileSystem _fileSystem;

  @override
  final String name = 'aar';

  @override
  bool get reportNullSafety => false;

  @override
  Future<Set<DevelopmentArtifact>> get requiredArtifacts async => <DevelopmentArtifact>{
    DevelopmentArtifact.androidGenSnapshot,
  };

  @override
  Future<CustomDimensions> get usageValues async {
    final FlutterProject flutterProject = _getProject();

    String projectType;
    if (flutterProject.manifest.isModule) {
      projectType = 'module';
    } else if (flutterProject.manifest.isPlugin) {
      projectType = 'plugin';
    } else {
      projectType = 'app';
    }

    return CustomDimensions(
      commandBuildAarProjectType: projectType,
      commandBuildAarTargetPlatform: stringsArg('target-platform').join(','),
    );
  }

  @override
  final String description = 'Build a repository containing an AAR and a POM file.\n\n'
      'By default, AARs are built for `release`, `debug` and `profile`.\n'
      'The POM file is used to include the dependencies that the AAR was compiled against.\n'
      'To learn more about how to use these artifacts, see: https://flutter.dev/go/build-aar\n'
      'This command assumes that the entrypoint is "lib/main.dart". '
      'This cannot currently be configured.';

  @override
  Future<FlutterCommandResult> runCommand() async {
    if (_androidSdk == null) {
      exitWithNoSdkMessage();
    }
    final Set<AndroidBuildInfo> androidBuildInfo = <AndroidBuildInfo>{};

    final Iterable<AndroidArch> targetArchitectures =
        stringsArg('target-platform').map<AndroidArch>(getAndroidArchForName);

    final String? buildNumberArg = stringArg('build-number');
    final String buildNumber = argParser.options.containsKey('build-number')
      && buildNumberArg != null
      && buildNumberArg.isNotEmpty
      ? buildNumberArg
      : '1.0';

    final File targetFile = _fileSystem.file(_fileSystem.path.join('lib', 'main.dart'));
    for (final String buildMode in const <String>['debug', 'profile', 'release']) {
      if (boolArg(buildMode)) {
        androidBuildInfo.add(
          AndroidBuildInfo(
            await getBuildInfo(
              forcedBuildMode: BuildMode.fromCliName(buildMode),
              forcedTargetFile: targetFile,
            ),
            targetArchs: targetArchitectures,
          )
        );
      }
    }
    if (androidBuildInfo.isEmpty) {
      throwToolExit('Please specify a build mode and try again.');
    }

    displayNullSafetyMode(androidBuildInfo.first.buildInfo);
    await androidBuilder?.buildAar(
      project: _getProject(),
      target: targetFile.path,
      androidBuildInfo: androidBuildInfo,
      outputDirectoryPath: stringArg('output'),
      buildNumber: buildNumber,
    );
    return FlutterCommandResult.success();
  }

  /// Returns the [FlutterProject] which is determined from the remaining command-line
  /// argument if any or the current working directory.
  FlutterProject _getProject() {
    final List<String> remainingArguments = argResults!.rest;
    if (remainingArguments.isEmpty) {
      return FlutterProject.current();
    }
    final File mainFile = _fileSystem.file(remainingArguments.first);
    final String path;
    if (!mainFile.existsSync()) {
      final Directory pathProject = _fileSystem.directory(remainingArguments.first);
      if (!pathProject.existsSync()) {
        throwToolExit('${remainingArguments.first} does not exist');
      }
      path = pathProject.path;
    } else {
      path = mainFile.parent.path;
    }
    final String? projectRoot = findProjectRoot(_fileSystem, path);
    if (projectRoot == null) {
      throwToolExit('${mainFile.parent.path} is not a valid flutter project');
    }
    return FlutterProject.fromDirectory(_fileSystem.directory(projectRoot));
  }
}
