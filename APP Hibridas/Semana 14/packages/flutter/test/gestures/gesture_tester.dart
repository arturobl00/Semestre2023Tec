// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:fake_async/fake_async.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

class GestureTester {
  GestureTester._(this.async);

  final FakeAsync async;

  void closeArena(int pointer) {
    GestureBinding.instance.gestureArena.close(pointer);
  }

  void route(PointerEvent event) {
    GestureBinding.instance.pointerRouter.route(event);
    async.flushMicrotasks();
  }
}

typedef GestureTest = void Function(GestureTester tester);

@isTest
void testGesture(String description, GestureTest callback) {
  test(description, () {
    FakeAsync().run((FakeAsync async) {
      callback(GestureTester._(async));
    });
  });
}
