// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:flutter_tools/src/base/io.dart';

import '../src/common.dart';
import 'test_data/multidex_project.dart';
import 'test_driver.dart';
import 'test_utils.dart';

void main() {
  late Directory tempDir;
  late FlutterRunTestDriver flutter;

  setUp(() async {
    tempDir = createResolvedTempDirectorySync('run_test.');
    flutter = FlutterRunTestDriver(tempDir);
  });

  tearDown(() async {
    await flutter.stop();
    tryToDelete(tempDir);
  });

  testWithoutContext('simple build apk succeeds', () async {
    final MultidexProject project = MultidexProject(true);
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
    ], workingDirectory: tempDir.path);

    expect(result, const ProcessResultMatcher(stdoutPattern: 'app-debug.apk'));
  });

  testWithoutContext('simple build apk without FlutterMultiDexApplication fails', () async {
    final MultidexProject project = MultidexProject(false);
    await project.setUpIn(tempDir);
    final String flutterBin = fileSystem.path.join(getFlutterRoot(), 'bin', 'flutter');
    final ProcessResult result = await processManager.run(<String>[
      flutterBin,
      ...getLocalEngineArguments(),
      'build',
      'apk',
      '--debug',
    ], workingDirectory: tempDir.path);

    expect(result, const ProcessResultMatcher(exitCode: 1));
    expect(result.stderr.toString(), contains('Cannot fit requested classes in a single dex file'));
    expect(result.stderr.toString(), contains('The number of method references in a .dex file cannot exceed 64K.'));
  });
}
