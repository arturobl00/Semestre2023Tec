// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:package_config/package_config.dart';
import 'package:process/process.dart';

import '../artifacts.dart';
import '../base/common.dart';
import '../base/config.dart';
import '../base/file_system.dart';
import '../base/logger.dart';
import '../base/platform.dart';
import '../build_info.dart';
import '../bundle.dart';
import '../cache.dart';
import '../compile.dart';
import '../dart/language_version.dart';
import '../web/bootstrap.dart';
import '../web/memory_fs.dart';
import 'test_config.dart';

/// A web compiler for the test runner.
class WebTestCompiler {
  WebTestCompiler({
    required FileSystem fileSystem,
    required Logger logger,
    required Artifacts artifacts,
    required Platform platform,
    required ProcessManager processManager,
    required Config config,
  }) : _logger = logger,
       _fileSystem = fileSystem,
       _artifacts = artifacts,
       _platform = platform,
       _processManager = processManager,
       _config = config;

  final Logger _logger;
  final FileSystem _fileSystem;
  final Artifacts _artifacts;
  final Platform _platform;
  final ProcessManager _processManager;
  final Config _config;

  Future<WebMemoryFS> initialize({
    required Directory projectDirectory,
    required String testOutputDir,
    required List<String> testFiles,
    required BuildInfo buildInfo,
  }) async {
    LanguageVersion languageVersion = LanguageVersion(2, 8);
    late final String platformDillName;

    // TODO(zanderso): to support autodetect this would need to partition the source code into
    // a sound and unsound set and perform separate compilations
    final List<String> extraFrontEndOptions = List<String>.of(buildInfo.extraFrontEndOptions);
    if (buildInfo.nullSafetyMode == NullSafetyMode.unsound || buildInfo.nullSafetyMode == NullSafetyMode.autodetect) {
      platformDillName = 'ddc_outline.dill';
      if (!extraFrontEndOptions.contains('--no-sound-null-safety')) {
        extraFrontEndOptions.add('--no-sound-null-safety');
      }
    } else if (buildInfo.nullSafetyMode == NullSafetyMode.sound) {
      languageVersion = currentLanguageVersion(_fileSystem, Cache.flutterRoot!);
      platformDillName = 'ddc_outline_sound.dill';
      if (!extraFrontEndOptions.contains('--sound-null-safety')) {
        extraFrontEndOptions.add('--sound-null-safety');
      }
    }

    final String platformDillPath = _fileSystem.path.join(
      getWebPlatformBinariesDirectory(_artifacts, buildInfo.webRenderer).path,
      platformDillName
    );

    final Directory outputDirectory = _fileSystem.directory(testOutputDir)
      ..createSync(recursive: true);
    final List<File> generatedFiles = <File>[];
    for (final String testFilePath in testFiles) {
      final List<String> relativeTestSegments = _fileSystem.path.split(
        _fileSystem.path.relative(testFilePath, from: projectDirectory.childDirectory('test').path));
      final File generatedFile = _fileSystem.file(
        _fileSystem.path.join(outputDirectory.path, '${relativeTestSegments.join('_')}.test.dart'));
      generatedFile
        ..createSync(recursive: true)
        ..writeAsStringSync(generateTestEntrypoint(
            relativeTestPath: relativeTestSegments.join('/'),
            absolutePath: testFilePath,
            testConfigPath: findTestConfigFile(_fileSystem.file(testFilePath), _logger)?.path,
            languageVersion: languageVersion,
        ));
      generatedFiles.add(generatedFile);
    }
    // Generate a fake main file that imports all tests to be executed. This will force
    // each of them to be compiled.
    final StringBuffer buffer = StringBuffer('// @dart=${languageVersion.major}.${languageVersion.minor}\n');
    for (final File generatedFile in generatedFiles) {
      buffer.writeln('import "${_fileSystem.path.basename(generatedFile.path)}";');
    }
    buffer.writeln('void main() {}');
    _fileSystem.file(_fileSystem.path.join(outputDirectory.path, 'main.dart'))
      ..createSync()
      ..writeAsStringSync(buffer.toString());

    final String cachedKernelPath = getDefaultCachedKernelPath(
      trackWidgetCreation: buildInfo.trackWidgetCreation,
      dartDefines: buildInfo.dartDefines,
      extraFrontEndOptions: extraFrontEndOptions,
      fileSystem: _fileSystem,
      config: _config,
    );
    final ResidentCompiler residentCompiler = ResidentCompiler(
      _artifacts.getHostArtifact(HostArtifact.flutterWebSdk).path,
      buildMode: buildInfo.mode,
      trackWidgetCreation: buildInfo.trackWidgetCreation,
      fileSystemRoots: <String>[
        projectDirectory.childDirectory('test').path,
        testOutputDir,
      ],
      // Override the filesystem scheme so that the frontend_server can find
      // the generated entrypoint code.
      fileSystemScheme: 'org-dartlang-app',
      initializeFromDill: cachedKernelPath,
      targetModel: TargetModel.dartdevc,
      extraFrontEndOptions: extraFrontEndOptions,
      platformDill: _fileSystem.file(platformDillPath).absolute.uri.toString(),
      dartDefines: buildInfo.dartDefines,
      librariesSpec: _artifacts.getHostArtifact(HostArtifact.flutterWebLibrariesJson).uri.toString(),
      packagesPath: buildInfo.packagesPath,
      artifacts: _artifacts,
      processManager: _processManager,
      logger: _logger,
      platform: _platform,
      fileSystem: _fileSystem,
    );

    final CompilerOutput? output = await residentCompiler.recompile(
      Uri.parse('org-dartlang-app:///main.dart'),
      <Uri>[],
      outputPath: outputDirectory.childFile('out').path,
      packageConfig: buildInfo.packageConfig,
      fs: _fileSystem,
      projectRootPath: projectDirectory.absolute.path,
    );
    if (output == null || output.errorCount > 0) {
      throwToolExit('Failed to compile');
    }
    // Cache the output kernel file to speed up subsequent compiles.
    _fileSystem.file(cachedKernelPath).parent.createSync(recursive: true);
    _fileSystem.file(output.outputFilename).copySync(cachedKernelPath);

    final File codeFile = outputDirectory.childFile('${output.outputFilename}.sources');
    final File manifestFile = outputDirectory.childFile('${output.outputFilename}.json');
    final File sourcemapFile = outputDirectory.childFile('${output.outputFilename}.map');
    final File metadataFile = outputDirectory.childFile('${output.outputFilename}.metadata');
    return WebMemoryFS()
      ..write(codeFile, manifestFile, sourcemapFile, metadataFile);
  }
}
