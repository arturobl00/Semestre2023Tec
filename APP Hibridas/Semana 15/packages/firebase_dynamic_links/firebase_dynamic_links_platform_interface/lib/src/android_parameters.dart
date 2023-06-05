// Copyright 2021 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The Dynamic Link Android parameters.
class AndroidParameters {
  const AndroidParameters({
    this.fallbackUrl,
    this.minimumVersion,
    required this.packageName,
  });

  /// The link to open when the app isn’t installed.
  ///
  /// Specify this to do something other than install the app from the Play
  /// Store when the app isn’t installed, such as open the mobile web version of
  /// the content, or display a promotional page for the app.
  final Uri? fallbackUrl;

  /// The version of the minimum version of your app that can open the link.
  ///
  /// If the installed app is an older version, the user is taken to the Play
  /// Store to upgrade the app.
  final int? minimumVersion;

  /// The Android app’s package name.
  final String packageName;

  Map<String, dynamic> asMap() => <String, dynamic>{
        'fallbackUrl': fallbackUrl?.toString(),
        'minimumVersion': minimumVersion,
        'packageName': packageName,
      };

  @override
  String toString() {
    return '$AndroidParameters($asMap)';
  }
}
