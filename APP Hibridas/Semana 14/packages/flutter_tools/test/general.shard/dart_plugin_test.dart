// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:flutter_tools/src/dart/package_map.dart';
import 'package:flutter_tools/src/flutter_manifest.dart';
import 'package:flutter_tools/src/flutter_plugins.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/plugins.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:package_config/package_config.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/fake.dart';
import 'package:yaml/yaml.dart';

import '../src/common.dart';
import '../src/context.dart';

void main() {
  group('Dart plugin registrant', () {
    late FileSystem fs;
    late FakeFlutterProject flutterProject;
    late FakeFlutterManifest flutterManifest;

    setUp(() async {
      fs = MemoryFileSystem.test();
      final Directory directory = fs.currentDirectory.childDirectory('app');
      flutterManifest = FakeFlutterManifest();
      flutterProject = FakeFlutterProject()
        ..manifest = flutterManifest
        ..directory = directory
        ..flutterPluginsFile = directory.childFile('.flutter-plugins')
        ..flutterPluginsDependenciesFile = directory.childFile('.flutter-plugins-dependencies')
        ..dartPluginRegistrant = directory.childFile('dart_plugin_registrant.dart');
      flutterProject.directory.childFile('.packages').createSync(recursive: true);
    });

    group('resolvePlatformImplementation', () {
      testWithoutContext('selects uncontested implementation from direct dependency', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_linux',
          'url_launcher_macos',
        };
        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_macos',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'macos': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginMacOS',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);

        expect(resolutions.length, equals(2));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_linux',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
        expect(resolutions[1].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_macos',
            'dartClass': 'UrlLauncherPluginMacOS',
            'platform': 'macos',
          })
        );
      });

      testWithoutContext('selects uncontested implementation from transitive dependency', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_macos',
        };
        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher_macos',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'macos': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginMacOS',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'transitive_dependency_plugin',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'windows': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginWindows',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);

        expect(resolutions.length, equals(2));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_macos',
            'dartClass': 'UrlLauncherPluginMacOS',
            'platform': 'macos',
          })
        );
        expect(resolutions[1].toMap(), equals(
          <String, String>{
            'pluginName': 'transitive_dependency_plugin',
            'dartClass': 'UrlLauncherPluginWindows',
            'platform': 'windows',
          })
        );
      });

      testWithoutContext('selects inline implementation on mobile', () async {
        final Set<String> directDependencies = <String>{};

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'android': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherAndroid',
                },
                'ios': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherIos',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(2));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher',
            'dartClass': 'UrlLauncherAndroid',
            'platform': 'android',
          })
        );
        expect(resolutions[1].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher',
            'dartClass': 'UrlLauncherIos',
            'platform': 'ios',
          })
        );
      });

      // See https://github.com/flutter/flutter/issues/87862 for details.
      testWithoutContext('does not select inline implementation on desktop for '
      'missing min Flutter SDK constraint', () async {
        final Set<String> directDependencies = <String>{};

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherLinux',
                },
                'macos': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherMacOS',
                },
                'windows': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherWindows',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(0));
      });

      // See https://github.com/flutter/flutter/issues/87862 for details.
      testWithoutContext('does not select inline implementation on desktop for '
      'min Flutter SDK constraint < 2.11', () async {
        final Set<String> directDependencies = <String>{};

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherLinux',
                },
                'macos': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherMacOS',
                },
                'windows': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherWindows',
                },
              },
            }),
            VersionConstraint.parse('>=2.10.0'),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(0));
      });

      testWithoutContext('selects inline implementation on desktop for '
      'min Flutter SDK requirement of at least 2.11', () async {
        final Set<String> directDependencies = <String>{};

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherLinux',
                },
                'macos': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherMacOS',
                },
                'windows': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherWindows',
                },
              },
            }),
            VersionConstraint.parse('>=2.11.0'),
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(3));
        expect(
          resolutions.map((PluginInterfaceResolution resolution) => resolution.toMap()),
          containsAll(<Map<String, String>>[
            <String, String>{
              'pluginName': 'url_launcher',
              'dartClass': 'UrlLauncherLinux',
              'platform': 'linux',
            },
            <String, String>{
              'pluginName': 'url_launcher',
              'dartClass': 'UrlLauncherMacOS',
              'platform': 'macos',
            },
            <String, String>{
              'pluginName': 'url_launcher',
              'dartClass': 'UrlLauncherWindows',
              'platform': 'windows',
            },
          ])
        );
      });

      testWithoutContext('selects default implementation', () async {
        final Set<String> directDependencies = <String>{};

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          // Include three possible implementations, one before and one after
          // to ensure that the selection is working as intended, not just by
          // coincidence of order.
          Plugin.fromYaml(
            'another_url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UnofficialUrlLauncherPluginLinux',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'yet_another_url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UnofficialUrlLauncherPluginLinux2',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_linux',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      testWithoutContext('selects default implementation if interface is direct dependency', () async {
        final Set<String> directDependencies = <String>{'url_launcher'};

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'url_launcher_linux',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      testWithoutContext('selects user selected implementation despites default implementation', () async {
        final Set<String> directDependencies = <String>{
          'user_selected_url_launcher_implementation',
          'url_launcher',
        };

        final List<PluginInterfaceResolution> resolutions = resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'default_package': 'url_launcher_linux',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'url_launcher_linux',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
          Plugin.fromYaml(
            'user_selected_url_launcher_implementation',
            '',
            YamlMap.wrap(<String, dynamic>{
              'implements': 'url_launcher',
              'platforms': <String, dynamic>{
                'linux': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginLinux',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ]);
        expect(resolutions.length, equals(1));
        expect(resolutions[0].toMap(), equals(
          <String, String>{
            'pluginName': 'user_selected_url_launcher_implementation',
            'dartClass': 'UrlLauncherPluginLinux',
            'platform': 'linux',
          })
        );
      });

      testUsingContext('provides error when user selected multiple implementations', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_linux_1',
          'url_launcher_linux_2',
        };
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux_1',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              null,
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_linux_2',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              null,
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);

        },
        throwsToolExit(
          message: 'Please resolve the errors',
        ));

        expect(
          testLogger.errorText,
          'Plugin url_launcher:linux has conflicting direct dependency implementations:\n'
          '  url_launcher_linux_1\n'
          '  url_launcher_linux_2\n'
          'To fix this issue, remove all but one of these dependencies from pubspec.yaml.'
          '\n\n'
        );
      });

      testUsingContext('provides all errors when user selected multiple implementations', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_linux_1',
          'url_launcher_linux_2',
          'url_launcher_windows_1',
          'url_launcher_windows_2',
        };
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux_1',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              null,
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_linux_2',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux',
                  },
                },
              }),
              null,
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_windows_1',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'windows': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginWindows1',
                  },
                },
              }),
              null,
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_windows_2',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'windows': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginWindows2',
                  },
                },
              }),
              null,
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);
        },
        throwsToolExit(
          message: 'Please resolve the errors',
        ));

        expect(
          testLogger.errorText,
          'Plugin url_launcher:linux has conflicting direct dependency implementations:\n'
          '  url_launcher_linux_1\n'
          '  url_launcher_linux_2\n'
          'To fix this issue, remove all but one of these dependencies from pubspec.yaml.'
          '\n\n'
          'Plugin url_launcher:windows has conflicting direct dependency implementations:\n'
          '  url_launcher_windows_1\n'
          '  url_launcher_windows_2\n'
          'To fix this issue, remove all but one of these dependencies from pubspec.yaml.'
          '\n\n'
        );
      });

      testUsingContext('provides error when user needs to select among multiple implementations', () async {
        final Set<String> directDependencies = <String>{};
        expect(() {
          resolvePlatformImplementation(<Plugin>[
            Plugin.fromYaml(
              'url_launcher_linux_1',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux1',
                  },
                },
              }),
              null,
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
            Plugin.fromYaml(
              'url_launcher_linux_2',
              '',
              YamlMap.wrap(<String, dynamic>{
                'implements': 'url_launcher',
                'platforms': <String, dynamic>{
                  'linux': <String, dynamic>{
                    'dartPluginClass': 'UrlLauncherPluginLinux2',
                  },
                },
              }),
              null,
              <String>[],
              fileSystem: fs,
              appDependencies: directDependencies,
            ),
          ]);
        },
        throwsToolExit(
          message: 'Please resolve the errors',
        ));

        expect(
          testLogger.errorText,
          'Plugin url_launcher:linux has multiple possible implementations:\n'
          '  url_launcher_linux_1\n'
          '  url_launcher_linux_2\n'
          'To fix this issue, add one of these dependencies to pubspec.yaml.'
          '\n\n'
        );
      });
    });

    group('generateMainDartWithPluginRegistrant', () {
      testUsingContext('Generates new entrypoint', () async {
        flutterProject.isModule = true;

        createFakeDartPlugins(
          flutterProject,
          flutterManifest,
          fs,
          <String, String>{
            'url_launcher_android': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        android:
          dartPluginClass: AndroidPlugin
''',
          'url_launcher_ios': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        ios:
          dartPluginClass: IosPlugin
''',
          'url_launcher_macos': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        macos:
          dartPluginClass: MacOSPlugin
''',
         'url_launcher_linux': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        linux:
          dartPluginClass: LinuxPlugin
''',
         'url_launcher_windows': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        windows:
          dartPluginClass: WindowsPlugin
''',
         'awesome_macos': '''
  flutter:
    plugin:
      implements: awesome
      platforms:
        macos:
          dartPluginClass: AwesomeMacOS
''',
          });

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart');
        mainFile.writeAsStringSync('''
// @dart = 2.8
void main() {
}
''');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await generateMainDartWithPluginRegistrant(
          flutterProject,
          packageConfig,
          'package:app/main.dart',
          mainFile,
          throwOnPluginPubspecError: true,
        );
        expect(flutterProject.dartPluginRegistrant.readAsStringSync(),
          '//\n'
          '// Generated file. Do not edit.\n'
          '// This file is generated from template in file `flutter_tools/lib/src/flutter_plugins.dart`.\n'
          '//\n'
          '\n'
          '// @dart = 2.8\n'
          '\n'
          "import 'dart:io'; // flutter_ignore: dart_io_import.\n"
          "import 'package:url_launcher_android/url_launcher_android.dart';\n"
          "import 'package:url_launcher_ios/url_launcher_ios.dart';\n"
          "import 'package:url_launcher_linux/url_launcher_linux.dart';\n"
          "import 'package:awesome_macos/awesome_macos.dart';\n"
          "import 'package:url_launcher_macos/url_launcher_macos.dart';\n"
          "import 'package:url_launcher_windows/url_launcher_windows.dart';\n"
          '\n'
          "@pragma('vm:entry-point')\n"
          'class _PluginRegistrant {\n'
          '\n'
          "  @pragma('vm:entry-point')\n"
          '  static void register() {\n'
          '    if (Platform.isAndroid) {\n'
          '      try {\n'
          '        AndroidPlugin.registerWith();\n'
          '      } catch (err) {\n'
          '        print(\n'
          "          '`url_launcher_android` threw an error: \$err. '\n"
          "          'The app may not function as expected until you remove this plugin from pubspec.yaml'\n"
          '        );\n'
          '      }\n'
          '\n'
          '    } else if (Platform.isIOS) {\n'
          '      try {\n'
          '        IosPlugin.registerWith();\n'
          '      } catch (err) {\n'
          '        print(\n'
          "          '`url_launcher_ios` threw an error: \$err. '\n"
          "          'The app may not function as expected until you remove this plugin from pubspec.yaml'\n"
          '        );\n'
          '      }\n'
          '\n'
          '    } else if (Platform.isLinux) {\n'
          '      try {\n'
          '        LinuxPlugin.registerWith();\n'
          '      } catch (err) {\n'
          '        print(\n'
          "          '`url_launcher_linux` threw an error: \$err. '\n"
          "          'The app may not function as expected until you remove this plugin from pubspec.yaml'\n"
          '        );\n'
          '      }\n'
          '\n'
          '    } else if (Platform.isMacOS) {\n'
          '      try {\n'
          '        AwesomeMacOS.registerWith();\n'
          '      } catch (err) {\n'
          '        print(\n'
          "          '`awesome_macos` threw an error: \$err. '\n"
          "          'The app may not function as expected until you remove this plugin from pubspec.yaml'\n"
          '        );\n'
          '      }\n'
          '\n'
          '      try {\n'
          '        MacOSPlugin.registerWith();\n'
          '      } catch (err) {\n'
          '        print(\n'
          "          '`url_launcher_macos` threw an error: \$err. '\n"
          "          'The app may not function as expected until you remove this plugin from pubspec.yaml'\n"
          '        );\n'
          '      }\n'
          '\n'
          '    } else if (Platform.isWindows) {\n'
          '      try {\n'
          '        WindowsPlugin.registerWith();\n'
          '      } catch (err) {\n'
          '        print(\n'
          "          '`url_launcher_windows` threw an error: \$err. '\n"
          "          'The app may not function as expected until you remove this plugin from pubspec.yaml'\n"
          '        );\n'
          '      }\n'
          '\n'
          '    }\n'
          '  }\n'
          '}\n'
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Plugin without platform support throws tool exit', () async {
        flutterProject.isModule = false;

        createFakeDartPlugins(
          flutterProject,
          flutterManifest,
          fs,
          <String, String>{
            'url_launcher_macos': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        macos:
          invalid:
''',
          });

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart')..writeAsStringSync('');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await expectLater(
          generateMainDartWithPluginRegistrant(
            flutterProject,
            packageConfig,
            'package:app/main.dart',
            mainFile,
            throwOnPluginPubspecError: true,
          ), throwsToolExit(message:
            'Invalid plugin specification url_launcher_macos.\n'
            'Invalid "macos" plugin specification.'
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Plugin with platform support without dart plugin class throws tool exit', () async {
        flutterProject.isModule = false;

        createFakeDartPlugins(
          flutterProject,
          flutterManifest,
          fs,
          <String, String>{
            'url_launcher_macos': '''
  flutter:
    plugin:
      implements: url_launcher
''',
          });

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart')..writeAsStringSync('');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await expectLater(
          generateMainDartWithPluginRegistrant(
            flutterProject,
            packageConfig,
            'package:app/main.dart',
            mainFile,
            throwOnPluginPubspecError: true,
          ), throwsToolExit(message:
            'Invalid plugin specification url_launcher_macos.\n'
            'Cannot find the `flutter.plugin.platforms` key in the `pubspec.yaml` file. '
            'An instruction to format the `pubspec.yaml` can be found here: '
            'https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms'
          ),
        );
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Does not show error messages if throwOnPluginPubspecError is false', () async {
        final Set<String> directDependencies = <String>{
          'url_launcher_windows',
        };
        resolvePlatformImplementation(<Plugin>[
          Plugin.fromYaml(
            'url_launcher_windows',
            '',
            YamlMap.wrap(<String, dynamic>{
              'platforms': <String, dynamic>{
                'windows': <String, dynamic>{
                  'dartPluginClass': 'UrlLauncherPluginWindows',
                },
              },
            }),
            null,
            <String>[],
            fileSystem: fs,
            appDependencies: directDependencies,
          ),
        ],
          throwOnPluginPubspecError: false,
        );
        expect(testLogger.errorText, '');
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Does not create new entrypoint if there are no platform resolutions', () async {
        flutterProject.isModule = false;

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart')..writeAsStringSync('');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await generateMainDartWithPluginRegistrant(
          flutterProject,
          packageConfig,
          'package:app/main.dart',
          mainFile,
          throwOnPluginPubspecError: true,
        );
        expect(flutterProject.dartPluginRegistrant.existsSync(), isFalse);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });

      testUsingContext('Deletes new entrypoint if there are no platform resolutions', () async {
        flutterProject.isModule = false;

        createFakeDartPlugins(
          flutterProject,
          flutterManifest,
          fs,
          <String, String>{
            'url_launcher_macos': '''
  flutter:
    plugin:
      implements: url_launcher
      platforms:
        macos:
          dartPluginClass: MacOSPlugin
''',
          });

        final Directory libDir = flutterProject.directory.childDirectory('lib');
        libDir.createSync(recursive: true);

        final File mainFile = libDir.childFile('main.dart')..writeAsStringSync('');
        final PackageConfig packageConfig = await loadPackageConfigWithLogging(
          flutterProject.directory.childDirectory('.dart_tool').childFile('package_config.json'),
          logger: globals.logger,
          throwOnError: false,
        );
        await generateMainDartWithPluginRegistrant(
          flutterProject,
          packageConfig,
          'package:app/main.dart',
          mainFile,
          throwOnPluginPubspecError: true,
        );
        expect(flutterProject.dartPluginRegistrant.existsSync(), isTrue);

        // No plugins.
        createFakeDartPlugins(
          flutterProject,
          flutterManifest,
          fs,
          <String, String>{});

        await generateMainDartWithPluginRegistrant(
          flutterProject,
          packageConfig,
          'package:app/main.dart',
          mainFile,
          throwOnPluginPubspecError: true,
        );
        expect(flutterProject.dartPluginRegistrant.existsSync(), isFalse);
      }, overrides: <Type, Generator>{
        FileSystem: () => fs,
        ProcessManager: () => FakeProcessManager.any(),
      });
    });
  });
}

void createFakeDartPlugins(
  FakeFlutterProject flutterProject,
  FakeFlutterManifest flutterManifest,
  FileSystem fs,
  Map<String, String> plugins,
) {
  final Directory fakePubCache = fs.systemTempDirectory.childDirectory('cache');
  final File packagesFile = flutterProject.directory
    .childFile('.packages');
  if (packagesFile.existsSync()) {
    packagesFile.deleteSync();
  }
  packagesFile.createSync(recursive: true);

  for (final MapEntry<String, String> entry in plugins.entries) {
    final String name = fs.path.basename(entry.key);
    final Directory pluginDirectory = fakePubCache.childDirectory(name);
    packagesFile.writeAsStringSync(
      '$name:file://${pluginDirectory.childFile('lib').uri}\n',
      mode: FileMode.writeOnlyAppend,
    );
    pluginDirectory.childFile('pubspec.yaml')
      ..createSync(recursive: true)
      ..writeAsStringSync(entry.value);
  }
  flutterManifest.dependencies = plugins.keys.toSet();
}

class FakeFlutterManifest extends Fake implements FlutterManifest {
  @override
  Set<String> dependencies = <String>{};
}

class FakeFlutterProject extends Fake implements FlutterProject {
  @override
  bool isModule = false;

  @override
  late FlutterManifest manifest;

  @override
  late Directory directory;

  @override
  late File flutterPluginsFile;

  @override
  late File flutterPluginsDependenciesFile;

  @override
  late File dartPluginRegistrant;

  @override
  late IosProject ios;

  @override
  late AndroidProject android;

  @override
  late WebProject web;

  @override
  late MacOSProject macos;

  @override
  late LinuxProject linux;

  @override
  late WindowsProject windows;
}
