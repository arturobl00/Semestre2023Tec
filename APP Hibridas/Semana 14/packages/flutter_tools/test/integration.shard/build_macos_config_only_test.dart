// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_utils.dart';

void main() {
  test('flutter build macOS --config only updates generated xcconfig file without performing build', () async {
    final String workingDirectory = fileSystem.path.join(
      getFlutterRoot(),
      'dev',
      'integration_tests',
      'flutter_gallery',
    );
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');

    await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'clean',
    ], workingDirectory: workingDirectory);
    final List<String> buildCommand = <String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'macos',
      '--config-only',
      '--release',
      '--obfuscate',
      '--split-debug-info=info',
    ];
    final ProcessResult firstRunResult = await processManager.run(buildCommand, workingDirectory: workingDirectory);

    printOnFailure('Output of flutter build macOS:');
    final String firstRunStdout = firstRunResult.stdout.toString();
    printOnFailure('First run stdout: $firstRunStdout');
    printOnFailure('First run stderr: ${firstRunResult.stderr}');

    expect(firstRunResult.exitCode, 0);
    expect(firstRunStdout, contains('Running pod install'));

    final File generatedConfig = fileSystem.file(fileSystem.path.join(
      workingDirectory,
      'macos',
      'Flutter',
      'ephemeral',
      'Flutter-Generated.xcconfig',
    ));

    // Config is updated if command succeeded.
    expect(generatedConfig, exists);
    expect(generatedConfig.readAsStringSync(), contains('DART_OBFUSCATION=true'));

    // file that only exists if app was fully built.
    final File frameworkPlist = fileSystem.file(fileSystem.path.join(
      workingDirectory,
      'build',
      'macos',
      'Build',
      'Products',
      'Release',
      'App.framework',
      'Resources',
      'Info.plist'
    ));

    expect(frameworkPlist, isNot(exists));

    // Run again with no changes.
    final ProcessResult secondRunResult = await processManager.run(buildCommand, workingDirectory: workingDirectory);
    final String secondRunStdout = secondRunResult.stdout.toString();
    printOnFailure('Second run stdout: $secondRunStdout');
    printOnFailure('Second run stderr: ${secondRunResult.stderr}');

    expect(secondRunResult.exitCode, 0);
  }, skip: !platform.isMacOS); // [intended] macOS builds only work on macos.
}
