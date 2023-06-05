// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../base/utils.dart';

abstract class WebCompilerConfig {
  const WebCompilerConfig();

  /// Returns `true` if `this` represents configuration for the Wasm compiler.
  ///
  /// Otherwise, `false`–represents the JavaScript compiler.
  bool get isWasm;

  Map<String, String> toBuildSystemEnvironment();

  Map<String, Object> get buildEventAnalyticsValues => <String, Object>{
        'wasm-compile': isWasm,
      };
}

/// Configuration for the Dart-to-Javascript compiler (dart2js).
class JsCompilerConfig extends WebCompilerConfig {
  const JsCompilerConfig({
    required this.csp,
    required this.dumpInfo,
    required this.nativeNullAssertions,
    required this.optimizationLevel,
    required this.noFrequencyBasedMinification,
    required this.sourceMaps,
  });

  /// Instantiates [JsCompilerConfig] suitable for the `flutter run` command.
  const JsCompilerConfig.run({required bool nativeNullAssertions})
      : this(
          csp: false,
          dumpInfo: false,
          nativeNullAssertions: nativeNullAssertions,
          noFrequencyBasedMinification: false,
          optimizationLevel: kDart2jsDefaultOptimizationLevel,
          sourceMaps: true,
        );

  /// Creates a new [JsCompilerConfig] from build system environment values.
  ///
  /// Should correspond exactly with [toBuildSystemEnvironment].
  factory JsCompilerConfig.fromBuildSystemEnvironment(
          Map<String, String> defines) =>
      JsCompilerConfig(
        csp: defines[kCspMode] == 'true',
        dumpInfo: defines[kDart2jsDumpInfo] == 'true',
        nativeNullAssertions: defines[kNativeNullAssertions] == 'true',
        optimizationLevel: defines[kDart2jsOptimization] ?? kDart2jsDefaultOptimizationLevel,
        noFrequencyBasedMinification: defines[kDart2jsNoFrequencyBasedMinification] == 'true',
        sourceMaps: defines[kSourceMapsEnabled] == 'true',
      );

  /// The default optimization level for dart2js.
  ///
  /// Maps to [kDart2jsOptimization].
  static const String kDart2jsDefaultOptimizationLevel = 'O4';

  /// Build environment flag for [optimizationLevel].
  static const String kDart2jsOptimization = 'Dart2jsOptimization';

  /// Build environment flag for [dumpInfo].
  static const String kDart2jsDumpInfo = 'Dart2jsDumpInfo';

  /// Build environment flag for [noFrequencyBasedMinification].
  static const String kDart2jsNoFrequencyBasedMinification =
      'Dart2jsNoFrequencyBasedMinification';

  /// Build environment flag for [csp].
  static const String kCspMode = 'cspMode';

  /// Build environment flag for [sourceMaps].
  static const String kSourceMapsEnabled = 'SourceMaps';

  /// Build environment flag for [nativeNullAssertions].
  static const String kNativeNullAssertions = 'NativeNullAssertions';

  /// Whether to disable dynamic generation code to satisfy CSP policies.
  final bool csp;

  /// If `--dump-info` should be passed to the compiler.
  final bool dumpInfo;

  /// Whether native null assertions are enabled.
  final bool nativeNullAssertions;

  // If `--no-frequency-based-minification` should be passed to dart2js
  // TODO(kevmoo): consider renaming this to be "positive". Double negatives are confusing.
  final bool noFrequencyBasedMinification;

  /// The compiler optimization level.
  ///
  /// Valid values are O1 (lowest, profile default) to O4 (highest, release default).
  // TODO(kevmoo): consider storing this as an [int] and validating it!
  final String optimizationLevel;

  /// `true` if the JavaScript compiler build should output source maps.
  final bool sourceMaps;

  @override
  bool get isWasm => false;

  @override
  Map<String, String> toBuildSystemEnvironment() => <String, String>{
        kCspMode: csp.toString(),
        kDart2jsDumpInfo: dumpInfo.toString(),
        kNativeNullAssertions: nativeNullAssertions.toString(),
        kDart2jsNoFrequencyBasedMinification: noFrequencyBasedMinification.toString(),
        kDart2jsOptimization: optimizationLevel,
        kSourceMapsEnabled: sourceMaps.toString(),
      };

  /// Arguments to use in both phases: full JS compile and CFE-only.
  List<String> toSharedCommandOptions() => <String>[
        if (nativeNullAssertions) '--native-null-assertions',
        if (!sourceMaps) '--no-source-maps',
      ];

  /// Arguments to use in the full JS compile, but not CFE-only.
  ///
  /// Includes the contents of [toSharedCommandOptions].
  List<String> toCommandOptions() => <String>[
        ...toSharedCommandOptions(),
        '-$optimizationLevel',
        if (dumpInfo) '--dump-info',
        if (noFrequencyBasedMinification) '--no-frequency-based-minification',
        if (csp) '--csp',
      ];
}

/// Configuration for the Wasm compiler.
class WasmCompilerConfig extends WebCompilerConfig {
  const WasmCompilerConfig({
    required this.omitTypeChecks,
    required this.wasmOpt,
  });

  /// Creates a new [WasmCompilerConfig] from build system environment values.
  ///
  /// Should correspond exactly with [toBuildSystemEnvironment].
  factory WasmCompilerConfig.fromBuildSystemEnvironment(
          Map<String, String> defines) =>
      WasmCompilerConfig(
        omitTypeChecks: defines[kOmitTypeChecks] == 'true',
        wasmOpt: WasmOptLevel.values.byName(defines[kRunWasmOpt]!),
      );

  /// Build environment for [omitTypeChecks].
  static const String kOmitTypeChecks = 'WasmOmitTypeChecks';

  /// Build environment for [wasmOpt].
  static const String kRunWasmOpt = 'RunWasmOpt';

  /// If `omit-type-checks` should be passed to `dart2wasm`.
  final bool omitTypeChecks;

  /// Run wasm-opt on the resulting module.
  final WasmOptLevel wasmOpt;

  @override
  bool get isWasm => true;

  bool get runWasmOpt => wasmOpt == WasmOptLevel.full || wasmOpt == WasmOptLevel.debug;

  @override
  Map<String, String> toBuildSystemEnvironment() => <String, String>{
    kOmitTypeChecks: omitTypeChecks.toString(),
    kRunWasmOpt: wasmOpt.name,
  };

  List<String> toCommandOptions() => <String>[
    if (omitTypeChecks) '--omit-type-checks',
  ];

  @override
  Map<String, Object> get buildEventAnalyticsValues => <String, Object>{
    ...super.buildEventAnalyticsValues,
    ...toBuildSystemEnvironment(),
  };
}

enum WasmOptLevel implements CliEnum {
  full,
  debug,
  none;

  static const WasmOptLevel defaultValue = WasmOptLevel.full;

  @override
  String get cliName => name;

  @override
  String get helpText => switch (this) {
    WasmOptLevel.none => 'wasm-opt is not run. Fastest build; bigger, slower output.',
    WasmOptLevel.debug => 'Similar to `${WasmOptLevel.full.name}`, but member names are preserved. Debugging is easier, but size is a bit bigger.',
    WasmOptLevel.full => 'wasm-opt is run. Build time is slower, but output is smaller and faster.',
  };
}
