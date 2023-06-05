// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:archive/archive.dart';
import 'package:file/memory.dart';
import 'package:file_testing/file_testing.dart';
import 'package:flutter_tools/src/android/android_sdk.dart';
import 'package:flutter_tools/src/android/android_studio.dart';
import 'package:flutter_tools/src/android/application_package.dart';
import 'package:flutter_tools/src/android/gradle.dart';
import 'package:flutter_tools/src/android/gradle_errors.dart';
import 'package:flutter_tools/src/android/gradle_utils.dart';
import 'package:flutter_tools/src/artifacts.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/user_messages.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/reporting/reporting.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';
import '../../src/context.dart';
import '../../src/fake_process_manager.dart';
import '../../src/fakes.dart';

void main() {
  group('gradle build', () {
    late BufferLogger logger;
    late TestUsage testUsage;
    late FileSystem fileSystem;
    late FakeProcessManager processManager;

    setUp(() {
      processManager = FakeProcessManager.empty();
      logger = BufferLogger.test();
      testUsage = TestUsage();
      fileSystem = MemoryFileSystem.test();
      Cache.flutterRoot = '';
    });

    testUsingContext('Can immediately tool exit on recognized exit code/stderr', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
         'gradlew',
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
        exitCode: 1,
        stderr: '\nSome gradle message\n',
      ));

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      bool handlerCalled = false;
      await expectLater(() async {
       await builder.buildGradleApp(
          project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          configOnly: false,
          localGradleErrors: <GradleHandledError>[
            GradleHandledError(
              test: (String line) {
                return line.contains('Some gradle message');
              },
              handler: ({
                String? line,
                FlutterProject? project,
                bool? usesAndroidX,
                bool? multidexEnabled
              }) async {
                handlerCalled = true;
                return GradleBuildStatus.exit;
              },
              eventLabel: 'random-event-label',
            ),
          ],
        );
      },
      throwsToolExit(
        message: 'Gradle task assembleRelease failed with exit code 1'
      ));

      expect(handlerCalled, isTrue);

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'gradle',
          label: 'gradle-random-event-label-failure',
          parameters: CustomDimensions(),
        ),
      ));
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('Verbose mode for APKs includes Gradle stacktrace and sets debug log level', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: BufferLogger.test(verbose: true),
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
         'gradlew',
          '--full-stacktrace',
          '--info',
          '-Pverbose=true',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
      ));

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      fileSystem.directory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('flutter-apk')
        .childFile('app-release.apk')
        .createSync(recursive: true);

      await builder.buildGradleApp(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        androidBuildInfo: const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            null,
            treeShakeIcons: false,
          ),
        ),
        target: 'lib/main.dart',
        isBuildingBundle: false,
        configOnly: false,
        localGradleErrors: <GradleHandledError>[],
      );
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('Can retry build on recognized exit code/stderr', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );

      const FakeCommand fakeCmd = FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
        exitCode: 1,
        stderr: '\nSome gradle message\n',
      );

      processManager.addCommand(fakeCmd);

      const int maxRetries = 2;
      for (int i = 0; i < maxRetries; i++) {
        processManager.addCommand(fakeCmd);
      }

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      int testFnCalled = 0;
      await expectLater(() async {
       await builder.buildGradleApp(
          maxRetries: maxRetries,
          project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          configOnly: false,
          localGradleErrors: <GradleHandledError>[
            GradleHandledError(
              test: (String line) {
                if (line.contains('Some gradle message')) {
                  testFnCalled++;
                  return true;
                }
                return false;
              },
              handler: ({
                String? line,
                FlutterProject? project,
                bool? usesAndroidX,
                bool? multidexEnabled
              }) async {
                return GradleBuildStatus.retry;
              },
              eventLabel: 'random-event-label',
            ),
          ],
        );
      }, throwsToolExit(
        message: 'Gradle task assembleRelease failed with exit code 1'
      ));

      expect(logger.statusText, contains('Retrying Gradle Build: #1, wait time: 100ms'));
      expect(logger.statusText, contains('Retrying Gradle Build: #2, wait time: 200ms'));

      expect(testFnCalled, equals(maxRetries + 1));
      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'gradle',
          label: 'gradle-random-event-label-failure',
          parameters: CustomDimensions(),
        ),
      ));
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('Converts recognized ProcessExceptions into tools exits', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
        exitCode: 1,
        stderr: '\nSome gradle message\n',
      ));

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      bool handlerCalled = false;
      await expectLater(() async {
       await builder.buildGradleApp(
          project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          configOnly: false,
          localGradleErrors: <GradleHandledError>[
            GradleHandledError(
              test: (String line) {
                return line.contains('Some gradle message');
              },
              handler: ({
                String? line,
                FlutterProject? project,
                bool? usesAndroidX,
                bool? multidexEnabled
              }) async {
                handlerCalled = true;
                return GradleBuildStatus.exit;
              },
              eventLabel: 'random-event-label',
            ),
          ],
        );
      },
      throwsToolExit(
        message: 'Gradle task assembleRelease failed with exit code 1'
      ));

      expect(handlerCalled, isTrue);

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'gradle',
          label: 'gradle-random-event-label-failure',
          parameters: CustomDimensions(),
        ),
      ));
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('rethrows unrecognized ProcessException', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(FakeCommand(
        command: const <String>[
          'gradlew',
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
        exitCode: 1,
        onRun: () {
          throw const ProcessException('', <String>[], 'Unrecognized');
        }
      ));

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      await expectLater(() async {
        await builder.buildGradleApp(
          project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          configOnly: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsProcessException());
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('logs success event after a successful retry', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
        exitCode: 1,
        stderr: '\nnSome gradle message\n',
      ));
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
      ));

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      fileSystem.directory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('flutter-apk')
        .childFile('app-release.apk')
        .createSync(recursive: true);

      await builder.buildGradleApp(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        androidBuildInfo: const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            null,
            treeShakeIcons: false,
          ),
        ),
        target: 'lib/main.dart',
        isBuildingBundle: false,
        configOnly: false,
        localGradleErrors: <GradleHandledError>[
          GradleHandledError(
            test: (String line) {
              return line.contains('Some gradle message');
            },
            handler: ({
              String? line,
              FlutterProject? project,
              bool? usesAndroidX,
                bool? multidexEnabled
            }) async {
              return GradleBuildStatus.retry;
            },
            eventLabel: 'random-event-label',
          ),
        ],
      );
      expect(testUsage.events, contains(
        const TestUsageEvent(
          'build',
          'gradle',
          label: 'gradle-random-event-label-success',
          parameters: CustomDimensions(),
        ),
      ));
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('performs code size analysis and sends analytics', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(
          environment: <String, String>{
            'HOME': '/home',
          },
        ),
        androidStudio: FakeAndroidStudio(),
      );
       processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          '-Ptarget-platform=android-arm64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          '-Pcode-size-directory=foo',
          'assembleRelease',
        ],
      ));

      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      final Archive archive = Archive()
        ..addFile(ArchiveFile('AndroidManifest.xml', 100,  List<int>.filled(100, 0)))
        ..addFile(ArchiveFile('META-INF/CERT.RSA', 10,  List<int>.filled(10, 0)))
        ..addFile(ArchiveFile('META-INF/CERT.SF', 10,  List<int>.filled(10, 0)))
        ..addFile(ArchiveFile('lib/arm64-v8a/libapp.so', 50,  List<int>.filled(50, 0)))
        ..addFile(ArchiveFile('lib/arm64-v8a/libflutter.so', 50, List<int>.filled(50, 0)));

      fileSystem.directory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('flutter-apk')
        .childFile('app-release.apk')
        ..createSync(recursive: true)
        ..writeAsBytesSync(ZipEncoder().encode(archive)!);

      fileSystem.file('foo/snapshot.arm64-v8a.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
[
  {
    "l": "dart:_internal",
    "c": "SubListIterable",
    "n": "[Optimized] skip",
    "s": 2400
  }
]''');
      fileSystem.file('foo/trace.arm64-v8a.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{}');

      await builder.buildGradleApp(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        androidBuildInfo: const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            null,
            treeShakeIcons: false,
            codeSizeDirectory: 'foo',
          ),
          targetArchs: <AndroidArch>[AndroidArch.arm64_v8a],
        ),
        target: 'lib/main.dart',
        isBuildingBundle: false,
        configOnly: false,
        localGradleErrors: <GradleHandledError>[],
      );

      expect(testUsage.events, contains(
        const TestUsageEvent(
          'code-size-analysis',
          'apk',
        ),
      ));
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('indicates that an APK has been built successfully', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
      ));
      fileSystem.directory('android')
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);

      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      fileSystem.directory('build')
        .childDirectory('app')
        .childDirectory('outputs')
        .childDirectory('flutter-apk')
        .childFile('app-release.apk')
        .createSync(recursive: true);

      await builder.buildGradleApp(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        androidBuildInfo: const AndroidBuildInfo(
          BuildInfo(
            BuildMode.release,
            null,
            treeShakeIcons: false,
          ),
        ),
        target: 'lib/main.dart',
        isBuildingBundle: false,
        configOnly: false,
        localGradleErrors: const <GradleHandledError>[],
      );

      expect(
        logger.statusText,
        contains('Built build/app/outputs/flutter-apk/app-release.apk (0.0MB)'),
      );
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('Uses namespace attribute if manifest lacks a package attribute', () async {
      final FlutterProject project = FlutterProject.fromDirectoryTest(fileSystem.currentDirectory);
      final AndroidSdk sdk = FakeAndroidSdk();

      fileSystem.directory(project.android.hostAppGradleRoot)
        .childFile('build.gradle')
        .createSync(recursive: true);

      fileSystem.directory(project.android.hostAppGradleRoot)
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync(
'''
apply from: irrelevant/flutter.gradle

android {
    namespace 'com.example.foo'
}
''');

      fileSystem.directory(project.android.hostAppGradleRoot)
        .childDirectory('app')
        .childDirectory('src')
        .childDirectory('main')
        .childFile('AndroidManifest.xml')
        ..createSync(recursive: true)
        ..writeAsStringSync(r'''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="namespacetest"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
''');

      final AndroidApk? androidApk = await AndroidApk.fromAndroidProject(
        project.android,
        androidSdk: sdk,
        fileSystem: fileSystem,
        logger: logger,
        processManager: processManager,
        processUtils: ProcessUtils(processManager: processManager, logger: logger),
        userMessages: UserMessages(),
        buildInfo: const BuildInfo(BuildMode.debug, null, treeShakeIcons: false),
      );

      expect(androidApk?.id, 'com.example.foo');
    });

    testUsingContext('can call custom gradle task getBuildOptions and parse the result', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          'printBuildVariants',
        ],
        stdout: '''
BuildVariant: freeDebug
BuildVariant: paidDebug
BuildVariant: freeRelease
BuildVariant: paidRelease
BuildVariant: freeProfile
BuildVariant: paidProfile
        ''',
      ));
      final List<String> actual = await builder.getBuildVariants(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      );
      expect(actual, <String>['freeDebug', 'paidDebug', 'freeRelease', 'paidRelease', 'freeProfile', 'paidProfile']);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('getBuildOptions returns empty list if gradle returns error', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          'printBuildVariants',
        ],
        stderr: '''
Gradle Crashed
        ''',
        exitCode: 1,
      ));
      final List<String> actual = await builder.getBuildVariants(
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
      );
      expect(actual, const <String>[]);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext("doesn't indicate how to consume an AAR when printHowToConsumeAar is false", () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
           'gradlew',
          '-I=/packages/flutter_tools/gradle/aar_init_script.gradle',
          '-Pflutter-root=/',
          '-Poutput-dir=build/',
          '-Pis-plugin=false',
          '-PbuildNumber=1.0',
          '-q',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          'assembleAarRelease',
        ],
      ));

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.file('.android/gradlew').createSync(recursive: true);
      fileSystem.file('.android/gradle.properties')
        .writeAsStringSync('irrelevant');
      fileSystem.file('.android/build.gradle')
        .createSync(recursive: true);
      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      await builder.buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '1.0',
      );

      expect(
        logger.statusText,
        contains('Built build/outputs/repo'),
      );
      expect(
        logger.statusText.contains('Consuming the Module'),
        isFalse,
      );
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('Verbose mode for AARs includes Gradle stacktrace and sets debug log level', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: BufferLogger.test(verbose: true),
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-I=/packages/flutter_tools/gradle/aar_init_script.gradle',
          '-Pflutter-root=/',
          '-Poutput-dir=build/',
          '-Pis-plugin=false',
          '-PbuildNumber=1.0',
          '--full-stacktrace',
          '--info',
          '-Pverbose=true',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          'assembleAarRelease',
        ],
      ));

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.file('.android/gradlew').createSync(recursive: true);
      fileSystem.file('.android/gradle.properties')
          .writeAsStringSync('irrelevant');
      fileSystem.file('.android/build.gradle')
          .createSync(recursive: true);
      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      await builder.buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '1.0',
      );
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('gradle exit code and stderr is forwarded to tool exit', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-I=/packages/flutter_tools/gradle/aar_init_script.gradle',
          '-Pflutter-root=/',
          '-Poutput-dir=build/',
          '-Pis-plugin=false',
          '-PbuildNumber=1.0',
          '-q',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          'assembleAarRelease',
        ],
        exitCode: 108,
        stderr: 'Gradle task assembleAarRelease failed with exit code 108.',
      ));

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.file('.android/gradlew').createSync(recursive: true);
      fileSystem.file('.android/gradle.properties')
          .writeAsStringSync('irrelevant');
      fileSystem.file('.android/build.gradle')
          .createSync(recursive: true);
      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      await expectLater(() async =>
        builder.buildGradleAar(
          androidBuildInfo: const AndroidBuildInfo(BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
          project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          outputDirectory: fileSystem.directory('build/'),
          target: '',
          buildNumber: '1.0',
        ), throwsToolExit(exitCode: 108, message: 'Gradle task assembleAarRelease failed with exit code 108.'));
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('build apk uses selected local engine with arm32 ABI', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(localEngine: 'out/android_arm'),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          '-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0',
          '-Plocal-engine-build-mode=release',
          '-Plocal-engine-out=out/android_arm',
          '-Ptarget-platform=android-arm',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
      ));

      fileSystem.file('out/android_arm/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_arm/armeabi_v7a_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm/armeabi_v7a_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm/armeabi_v7a_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

      fileSystem.file('android/gradlew').createSync(recursive: true);
      fileSystem.directory('android')
        .childFile('gradle.properties')
        .createSync(recursive: true);
      fileSystem.file('android/build.gradle')
        .createSync(recursive: true);
      fileSystem.directory('android')
        .childDirectory('app')
        .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      await expectLater(() async {
        await builder.buildGradleApp(
          project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          configOnly: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsToolExit());
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('build apk uses selected local engine with arm64 ABI', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(localEngine: 'out/android_arm64'),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          '-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0',
          '-Plocal-engine-build-mode=release',
          '-Plocal-engine-out=out/android_arm64',
          '-Ptarget-platform=android-arm64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
      ));

      fileSystem.file('out/android_arm64/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_arm64/arm64_v8a_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm64/arm64_v8a_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm64/arm64_v8a_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

      fileSystem.file('android/gradlew').createSync(recursive: true);
      fileSystem.directory('android')
          .childFile('gradle.properties')
          .createSync(recursive: true);
      fileSystem.file('android/build.gradle')
          .createSync(recursive: true);
      fileSystem.directory('android')
          .childDirectory('app')
          .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      await expectLater(() async {
        await builder.buildGradleApp(
          project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          configOnly: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsToolExit());
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('build apk uses selected local engine with x86 ABI', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(localEngine: 'out/android_x86'),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          '-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0',
          '-Plocal-engine-build-mode=release',
          '-Plocal-engine-out=out/android_x86',
          '-Ptarget-platform=android-x86',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
      ));

      fileSystem.file('out/android_x86/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_x86/x86_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x86/x86_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x86/x86_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

      fileSystem.file('android/gradlew').createSync(recursive: true);
      fileSystem.directory('android')
          .childFile('gradle.properties')
          .createSync(recursive: true);
      fileSystem.file('android/build.gradle')
          .createSync(recursive: true);
      fileSystem.directory('android')
          .childDirectory('app')
          .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      await expectLater(() async {
        await builder.buildGradleApp(
          project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          configOnly: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsToolExit());
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('build apk uses selected local engine with x64 ABI', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(localEngine: 'out/android_x64'),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-q',
          '-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0',
          '-Plocal-engine-build-mode=release',
          '-Plocal-engine-out=out/android_x64',
          '-Ptarget-platform=android-x64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
        exitCode: 1,
      ));

      fileSystem.file('out/android_x64/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_x64/x86_64_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x64/x86_64_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x64/x86_64_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

      fileSystem.file('android/gradlew').createSync(recursive: true);
      fileSystem.directory('android')
          .childFile('gradle.properties')
          .createSync(recursive: true);
      fileSystem.file('android/build.gradle')
          .createSync(recursive: true);
      fileSystem.directory('android')
          .childDirectory('app')
          .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      await expectLater(() async {
        await builder.buildGradleApp(
          project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          configOnly: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsToolExit());
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('honors --no-android-gradle-daemon setting', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(
        const FakeCommand(command: <String>[
          'gradlew',
          '-q',
          '--no-daemon',
          '-Ptarget-platform=android-arm,android-arm64,android-x64',
          '-Ptarget=lib/main.dart',
          '-Pbase-application-name=io.flutter.app.FlutterApplication',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          'assembleRelease',
        ],
      ));
      fileSystem.file('android/gradlew').createSync(recursive: true);

      fileSystem.directory('android')
          .childFile('gradle.properties')
          .createSync(recursive: true);
      fileSystem.file('android/build.gradle')
          .createSync(recursive: true);
      fileSystem.directory('android')
          .childDirectory('app')
          .childFile('build.gradle')
        ..createSync(recursive: true)
        ..writeAsStringSync('apply from: irrelevant/flutter.gradle');

      await expectLater(() async {
        await builder.buildGradleApp(
          project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
          androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(
              BuildMode.release,
              null,
              treeShakeIcons: false,
              androidGradleDaemon: false,
            ),
          ),
          target: 'lib/main.dart',
          isBuildingBundle: false,
          configOnly: false,
          localGradleErrors: const <GradleHandledError>[],
        );
      }, throwsToolExit());
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('build aar uses selected local engine with arm32 ABI', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(localEngine: 'out/android_arm'),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-I=/packages/flutter_tools/gradle/aar_init_script.gradle',
          '-Pflutter-root=/',
          '-Poutput-dir=build/',
          '-Pis-plugin=false',
          '-PbuildNumber=2.0',
          '-q',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          '-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0',
          '-Plocal-engine-build-mode=release',
          '-Plocal-engine-out=out/android_arm',
          '-Ptarget-platform=android-arm',
          'assembleAarRelease',
        ],
      ));

      fileSystem.file('out/android_arm/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_arm/armeabi_v7a_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm/armeabi_v7a_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm/armeabi_v7a_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.directory('.android/gradle')
        .createSync(recursive: true);
      fileSystem.directory('.android/gradle/wrapper')
        .createSync(recursive: true);
      fileSystem.file('.android/gradlew').createSync(recursive: true);
      fileSystem.file('.android/gradle.properties')
        .writeAsStringSync('irrelevant');
      fileSystem.file('.android/build.gradle')
        .createSync(recursive: true);

      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      await builder.buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '2.0',
      );

      expect(fileSystem.link(
        'build/outputs/repo/io/flutter/flutter_embedding_release/'
        '1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b/'
        'flutter_embedding_release-1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b.pom'
      ), exists);
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('build aar uses selected local engine with x64 ABI', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(localEngine: 'out/android_arm64'),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-I=/packages/flutter_tools/gradle/aar_init_script.gradle',
          '-Pflutter-root=/',
          '-Poutput-dir=build/',
          '-Pis-plugin=false',
          '-PbuildNumber=2.0',
          '-q',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          '-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0',
          '-Plocal-engine-build-mode=release',
          '-Plocal-engine-out=out/android_arm64',
          '-Ptarget-platform=android-arm64',
          'assembleAarRelease',
        ],
      ));

      fileSystem.file('out/android_arm64/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_arm64/arm64_v8a_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm64/arm64_v8a_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm64/arm64_v8a_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_arm64/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.directory('.android/gradle')
          .createSync(recursive: true);
      fileSystem.directory('.android/gradle/wrapper')
          .createSync(recursive: true);
      fileSystem.file('.android/gradlew').createSync(recursive: true);
      fileSystem.file('.android/gradle.properties')
          .writeAsStringSync('irrelevant');
      fileSystem.file('.android/build.gradle')
          .createSync(recursive: true);
      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      await builder.buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '2.0',
      );

      expect(fileSystem.link(
        'build/outputs/repo/io/flutter/flutter_embedding_release/'
        '1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b/'
        'flutter_embedding_release-1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b.pom'
      ), exists);
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('build aar uses selected local engine with x86 ABI', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(localEngine: 'out/android_x86'),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
          'gradlew',
          '-I=/packages/flutter_tools/gradle/aar_init_script.gradle',
          '-Pflutter-root=/',
          '-Poutput-dir=build/',
          '-Pis-plugin=false',
          '-PbuildNumber=2.0',
          '-q',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          '-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0',
          '-Plocal-engine-build-mode=release',
          '-Plocal-engine-out=out/android_x86',
          '-Ptarget-platform=android-x86',
          'assembleAarRelease',
        ],
      ));

      fileSystem.file('out/android_x86/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_x86/x86_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x86/x86_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x86/x86_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x86/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.directory('.android/gradle')
          .createSync(recursive: true);
      fileSystem.directory('.android/gradle/wrapper')
          .createSync(recursive: true);
      fileSystem.file('.android/gradlew').createSync(recursive: true);
      fileSystem.file('.android/gradle.properties')
          .writeAsStringSync('irrelevant');
      fileSystem.file('.android/build.gradle')
          .createSync(recursive: true);
      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      await builder.buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '2.0',
      );

      expect(fileSystem.link(
        'build/outputs/repo/io/flutter/flutter_embedding_release/'
        '1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b/'
        'flutter_embedding_release-1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b.pom'
      ), exists);
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });

    testUsingContext('build aar uses selected local engine on x64 ABI', () async {
      final AndroidGradleBuilder builder = AndroidGradleBuilder(
        java: FakeJava(),
        logger: logger,
        processManager: processManager,
        fileSystem: fileSystem,
        artifacts: Artifacts.test(localEngine: 'out/android_x64'),
        usage: testUsage,
        gradleUtils: FakeGradleUtils(),
        platform: FakePlatform(),
        androidStudio: FakeAndroidStudio(),
      );
      processManager.addCommand(const FakeCommand(
        command: <String>[
         'gradlew',
          '-I=/packages/flutter_tools/gradle/aar_init_script.gradle',
          '-Pflutter-root=/',
          '-Poutput-dir=build/',
          '-Pis-plugin=false',
          '-PbuildNumber=2.0',
          '-q',
          '-Pdart-obfuscation=false',
          '-Ptrack-widget-creation=false',
          '-Ptree-shake-icons=false',
          '-Plocal-engine-repo=/.tmp_rand0/flutter_tool_local_engine_repo.rand0',
          '-Plocal-engine-build-mode=release',
          '-Plocal-engine-out=out/android_x64',
          '-Ptarget-platform=android-x64',
          'assembleAarRelease',
        ],
      ));

      fileSystem.file('out/android_x64/flutter_embedding_release.pom')
        ..createSync(recursive: true)
        ..writeAsStringSync('''
<?xml version="1.0" encoding="UTF-8"?>
<project>
  <version>1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b</version>
  <dependencies>
  </dependencies>
</project>
''');
      fileSystem.file('out/android_x64/x86_64_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x64/x86_64_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x64/x86_64_release.maven-metadata.xml').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.jar').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.pom').createSync(recursive: true);
      fileSystem.file('out/android_x64/flutter_embedding_release.maven-metadata.xml').createSync(recursive: true);

      final File manifestFile = fileSystem.file('pubspec.yaml');
      manifestFile.createSync(recursive: true);
      manifestFile.writeAsStringSync('''
        flutter:
          module:
            androidPackage: com.example.test
        '''
      );

      fileSystem.directory('.android/gradle')
          .createSync(recursive: true);
      fileSystem.directory('.android/gradle/wrapper')
          .createSync(recursive: true);
      fileSystem.file('.android/gradlew').createSync(recursive: true);
      fileSystem.file('.android/gradle.properties')
          .writeAsStringSync('irrelevant');
      fileSystem.file('.android/build.gradle')
          .createSync(recursive: true);
      fileSystem.directory('build/outputs/repo').createSync(recursive: true);

      await builder.buildGradleAar(
        androidBuildInfo: const AndroidBuildInfo(
            BuildInfo(BuildMode.release, null, treeShakeIcons: false)),
        project: FlutterProject.fromDirectoryTest(fileSystem.currentDirectory),
        outputDirectory: fileSystem.directory('build/'),
        target: '',
        buildNumber: '2.0',
      );

      expect(fileSystem.link(
        'build/outputs/repo/io/flutter/flutter_embedding_release/'
        '1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b/'
        'flutter_embedding_release-1.0.0-73fd6b049a80bcea2db1f26c7cee434907cd188b.pom'
      ), exists);
      expect(processManager, hasNoRemainingExpectations);
    }, overrides: <Type, Generator>{
      AndroidStudio: () => FakeAndroidStudio(),
    });
  });
}

class FakeGradleUtils extends Fake implements GradleUtils {
  @override
  String getExecutable(FlutterProject project) {
    return 'gradlew';
  }
}

class FakeAndroidStudio extends Fake implements AndroidStudio {
  @override
  String get javaPath => '/android-studio/jbr';
}
