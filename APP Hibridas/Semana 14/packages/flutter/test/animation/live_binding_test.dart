// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../foundation/leak_tracking.dart';

void main() {
  /*
   * Here lies golden tests for packages/flutter_test/lib/src/binding.dart
   * because [matchesGoldenFile] does not use Skia Gold in its native package.
   */

  LiveTestWidgetsFlutterBinding().framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;

  testWidgetsWithLeakTracking('Should show event indicator for pointer events', (WidgetTester tester) async {
    final AnimationSheetBuilder animationSheet = AnimationSheetBuilder(frameSize: const Size(200, 200), allLayers: true);
    final List<Offset> taps = <Offset>[];
    Widget target({bool recording = true}) => Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 25, 20),
      child: animationSheet.record(
        MaterialApp(
          home: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 128, 128, 128),
              border: Border.all(),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                color: Colors.black,
                child: GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    taps.add(details.globalPosition);
                  },
                ),
              ),
            ),
          ),
        ),
        recording: recording,
      ),
    );

    await tester.pumpWidget(target(recording: false));

    await tester.pumpFrames(target(), const Duration(milliseconds: 50));

    final TestGesture gesture1 = await tester.createGesture(pointer: 1);
    await gesture1.down(tester.getCenter(find.byType(GestureDetector)) + const Offset(10, 10));
    expect(taps, equals(const <Offset>[Offset(130, 120)]));
    taps.clear();

    await tester.pumpFrames(target(), const Duration(milliseconds: 100));

    final TestGesture gesture2 = await tester.createGesture(pointer: 2);
    await gesture2.down(tester.getTopLeft(find.byType(GestureDetector)) + const Offset(30, -10));
    await gesture1.moveBy(const Offset(50, 50));

    await tester.pumpFrames(target(), const Duration(milliseconds: 100));
    await gesture1.up();
    await gesture2.up();
    await tester.pumpFrames(target(), const Duration(milliseconds: 50));
    expect(taps, isEmpty);

    await expectLater(
      animationSheet.collate(6),
      matchesGoldenFile('LiveBinding.press.animation.png'),
    );
    // Currently skipped due to daily flake: https://github.com/flutter/flutter/issues/87588
  }, skip: true); // Typically skip: isBrowser https://github.com/flutter/flutter/issues/42767

  testWidgetsWithLeakTracking('Should show event indicator for pointer events with setSurfaceSize', (WidgetTester tester) async {
    final AnimationSheetBuilder animationSheet = AnimationSheetBuilder(frameSize: const Size(200, 200), allLayers: true);
    final List<Offset> taps = <Offset>[];
    Widget target({bool recording = true}) => Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 25, 20),
      child: animationSheet.record(
        MaterialApp(
          home: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 128, 128, 128),
              border: Border.all(),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                color: Colors.black,
                child: GestureDetector(
                  onTapDown: (TapDownDetails details) {
                    taps.add(details.globalPosition);
                  },
                ),
              ),
            ),
          ),
        ),
        recording: recording,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(300, 300));
    await tester.pumpWidget(target(recording: false));

    await tester.pumpFrames(target(), const Duration(milliseconds: 50));

    final TestGesture gesture1 = await tester.createGesture(pointer: 1);
    await gesture1.down(tester.getCenter(find.byType(GestureDetector)) + const Offset(10, 10));
    expect(taps, equals(const <Offset>[Offset(130, 120)]));
    taps.clear();

    await tester.pumpFrames(target(), const Duration(milliseconds: 100));

    final TestGesture gesture2 = await tester.createGesture(pointer: 2);
    await gesture2.down(tester.getTopLeft(find.byType(GestureDetector)) + const Offset(30, -10));
    await gesture1.moveBy(const Offset(50, 50));

    await tester.pumpFrames(target(), const Duration(milliseconds: 100));
    await gesture1.up();
    await gesture2.up();
    await tester.pumpFrames(target(), const Duration(milliseconds: 50));
    expect(taps, isEmpty);

    final ui.Image image = await animationSheet.collate(6);

    await expectLater(
      image,
      matchesGoldenFile('LiveBinding.press.animation.2.png'),
    );
    image.dispose();
  }, skip: isBrowser); // https://github.com/flutter/flutter/issues/56001
}
