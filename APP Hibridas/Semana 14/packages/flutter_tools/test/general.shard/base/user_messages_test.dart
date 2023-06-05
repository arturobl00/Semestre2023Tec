// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/base/user_messages.dart';

import '../../src/common.dart';

typedef _InstallationMessage = String Function(Platform);

void main() {
  final FakePlatform macPlatform = FakePlatform(operatingSystem: 'macos');
  final FakePlatform linuxPlatform = FakePlatform();
  final FakePlatform windowsPlatform = FakePlatform(operatingSystem: 'windows');

  void checkInstallationURL(_InstallationMessage message) {
    expect(message(macPlatform), contains('https://flutter.dev/docs/get-started/install/macos#android-setup'));
    expect(message(linuxPlatform), contains('https://flutter.dev/docs/get-started/install/linux#android-setup'));
    expect(message(windowsPlatform), contains('https://flutter.dev/docs/get-started/install/windows#android-setup'));
    expect(message(FakePlatform(operatingSystem: '')), contains('https://flutter.dev/docs/get-started/install '));
  }

  testWithoutContext('Android installation instructions', () {
    final UserMessages userMessages = UserMessages();
    checkInstallationURL((Platform platform) => userMessages.androidMissingSdkInstructions(platform));
    checkInstallationURL((Platform platform) => userMessages.androidSdkInstallHelp(platform));
    checkInstallationURL((Platform platform) => userMessages.androidMissingSdkManager('/', platform));
    checkInstallationURL((Platform platform) => userMessages.androidCannotRunSdkManager('/', '', platform));
    checkInstallationURL((Platform platform) => userMessages.androidSdkBuildToolsOutdated(0, '', platform));
    checkInstallationURL((Platform platform) => userMessages.androidStudioInstallation(platform));
  });

  testWithoutContext('Xcode installation instructions', () {
    final UserMessages userMessages = UserMessages();
    expect(userMessages.xcodeMissing, contains('iOS and macOS'));
    expect(userMessages.xcodeIncomplete, contains('iOS and macOS'));
  });
}
