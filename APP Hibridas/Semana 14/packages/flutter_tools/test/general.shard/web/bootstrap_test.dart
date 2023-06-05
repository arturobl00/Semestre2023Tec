// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/web/bootstrap.dart';
import 'package:package_config/package_config.dart';

import '../../src/common.dart';

void main() {
  test('generateBootstrapScript embeds urls correctly', () {
    final String result = generateBootstrapScript(
      requireUrl: 'require.js',
      mapperUrl: 'mapper.js',
    );
    // require js source is interpolated correctly.
    expect(result, contains('"requireJs": "require.js"'));
    expect(result, contains('requireEl.src = getTTScriptUrl("requireJs");'));
    // stack trace mapper source is interpolated correctly.
    expect(result, contains('"mapper": "mapper.js"'));
    expect(result, contains('mapperEl.src = getTTScriptUrl("mapper");'));
    // data-main is set to correct bootstrap module.
    expect(result, contains('requireEl.setAttribute("data-main", "main_module.bootstrap");'));
  });

  test('generateBootstrapScript includes loading indicator', () {
    final String result = generateBootstrapScript(
      requireUrl: 'require.js',
      mapperUrl: 'mapper.js',
    );
    expect(result, contains('"flutter-loader"'));
    expect(result, contains('"indeterminate"'));
  });

  // https://github.com/flutter/flutter/issues/107742
  test('generateBootstrapScript loading indicator does not trigger scrollbars', () {
    final String result = generateBootstrapScript(
      requireUrl: 'require.js',
      mapperUrl: 'mapper.js',
    );

    // See: https://regexr.com/6q0ft
    final RegExp regex = RegExp(r'(?:\.flutter-loader\s*\{)[^}]+(?:overflow\:\s*hidden;)[^}]+}');

    expect(result, matches(regex), reason: '.flutter-loader must have overflow: hidden');
  });

  // https://github.com/flutter/flutter/issues/82524
  test('generateMainModule removes timeout from requireJS', () {
    final String result = generateMainModule(
      entrypoint: 'foo/bar/main.js',
      nullAssertions: false,
      nativeNullAssertions: false,
    );

    // See: https://regexr.com/6q0kp
    final RegExp regex = RegExp(
      r'(?:require\.config\(\{)(?:.|\s(?!\}\);))*'
        r'(?:waitSeconds\:\s*0[,]?)'
      r'(?:(?!\}\);).|\s)*\}\);');

    expect(result, matches(regex), reason: 'require.config must have a waitSeconds: 0 config entry');
  });

  test('generateMainModule embeds urls correctly', () {
    final String result = generateMainModule(
      entrypoint: 'foo/bar/main.js',
      nullAssertions: false,
      nativeNullAssertions: false,
    );
    // bootstrap main module has correct defined module.
    expect(result, contains('define("main_module.bootstrap", ["foo/bar/main.js", "dart_sdk"], '
      'function(app, dart_sdk) {'));
  });

  test('generateMainModule can set bootstrap name', () {
    final String result = generateMainModule(
      entrypoint: 'foo/bar/main.js',
      nullAssertions: false,
      nativeNullAssertions: false,
      bootstrapModule: 'foo_module.bootstrap',
    );
    // bootstrap main module has correct defined module.
    expect(result, contains('define("foo_module.bootstrap", ["foo/bar/main.js", "dart_sdk"], '
      'function(app, dart_sdk) {'));
  });

  test('generateMainModule includes null safety switches', () {
    final String result = generateMainModule(
      entrypoint: 'foo/bar/main.js',
      nullAssertions: true,
      nativeNullAssertions: true,
    );

    expect(result, contains('''dart_sdk.dart.nonNullAsserts(true);'''));
    expect(result, contains('''dart_sdk.dart.nativeNonNullAsserts(true);'''));
  });

  test('generateMainModule can disable null safety switches', () {
    final String result = generateMainModule(
      entrypoint: 'foo/bar/main.js',
      nullAssertions: false,
      nativeNullAssertions: false,
    );

    expect(result, contains('''dart_sdk.dart.nonNullAsserts(false);'''));
    expect(result, contains('''dart_sdk.dart.nativeNonNullAsserts(false);'''));
  });

  test('generateTestBootstrapFileContents embeds urls correctly', () {
    final String result = generateTestBootstrapFileContents('foo.dart.js', 'require.js', 'mapper.js');

    expect(result, contains('el.setAttribute("data-main", \'foo.dart.js\');'));
  });

  test('generateTestEntrypoint does not generate test config wrappers when testConfigPath is not passed', () {
    final String result = generateTestEntrypoint(
      relativeTestPath: 'relative_path.dart',
      absolutePath: 'absolute_path.dart',
      testConfigPath: null,
      languageVersion: LanguageVersion(2, 8),
    );

    expect(result, isNot(contains('test_config.testExecutable')));
  });

  test('generateTestEntrypoint generates test config wrappers when testConfigPath is passed', () {
    final String result = generateTestEntrypoint(
      relativeTestPath: 'relative_path.dart',
      absolutePath: 'absolute_path.dart',
      testConfigPath: 'test_config_path.dart',
      languageVersion: LanguageVersion(2, 8),
    );

    expect(result, contains('test_config.testExecutable'));
  });

  test('generateTestEntrypoint embeds urls correctly', () {
    final String result = generateTestEntrypoint(
      relativeTestPath: 'relative_path.dart',
      absolutePath: '/test/absolute_path.dart',
      testConfigPath: null,
      languageVersion: LanguageVersion(2, 8),
    );

    expect(result, contains("Uri.parse('file:///test/absolute_path.dart')"));
  });
}
