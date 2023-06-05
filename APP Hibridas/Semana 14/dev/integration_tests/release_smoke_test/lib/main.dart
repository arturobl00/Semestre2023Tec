// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show utf8;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  const Text text = Text('Hello, world!', textDirection: TextDirection.ltr);
  // These calls must not result in an error. They behave differently in
  // release mode compared to debug or profile.
  // The test will grep logcat for any errors emitted by Flutter.
  print(text.toDiagnosticsNode());
  print(text.toStringDeep());
  // regression test for https://github.com/flutter/flutter/issues/49601
  final List<int> computed = await compute(_utf8Encode, 'test', debugLabel: null);
  print(computed);
  runApp(
    const Center(
      child: text,
    ),
  );
}

List<int> _utf8Encode(String data) {
  return utf8.encode(data);
}
