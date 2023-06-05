// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

const TextStyle testStyle = TextStyle(
  fontSize: 10.0,
  letterSpacing: 0.0,
);

void main() {
  testWidgets('Default layout minimum size', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(child: const CupertinoButton(
        onPressed: null,
        child: Text('X', style: testStyle),
      )),
    );
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size,
      // 1 10px character + 16px * 2 is smaller than the default 44px minimum.
      const Size.square(44.0),
    );
  });

  testWidgets('Minimum size parameter', (WidgetTester tester) async {
    const double minSize = 60.0;
    await tester.pumpWidget(
      boilerplate(child: const CupertinoButton(
        onPressed: null,
        minSize: minSize,
        child: Text('X', style: testStyle),
      )),
    );
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size,
      // 1 10px character + 16px * 2 is smaller than defined 60.0px minimum
      const Size.square(minSize),
    );
  });

  testWidgets('Size grows with text', (WidgetTester tester) async {
    await tester.pumpWidget(
      boilerplate(child: const CupertinoButton(
        onPressed: null,
        child: Text('XXXX', style: testStyle),
      )),
    );
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size.width,
      // 4 10px character + 16px * 2 = 72.
      72.0,
    );
  });

  // TODO(LongCatIsLoong): Uncomment once https://github.com/flutter/flutter/issues/44115
  // is fixed.
  /*
  testWidgets(
    'CupertinoButton.filled default color contrast meets guideline',
    (WidgetTester tester) async {
      // The native color combination systemBlue text over white background fails
      // to pass the color contrast guideline.
      //await tester.pumpWidget(
      //  CupertinoTheme(
      //    data: const CupertinoThemeData(),
      //    child: Directionality(
      //      textDirection: TextDirection.ltr,
      //      child: CupertinoButton.filled(
      //        child: const Text('Button'),
      //        onPressed: () {},
      //      ),
      //    ),
      //  ),
      //);
      //await expectLater(tester, meetsGuideline(textContrastGuideline));

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: CupertinoButton.filled(
              child: const Text('Button'),
              onPressed: () {},
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
  */

  testWidgets('Button child alignment', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoButton(
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    Align align = tester.firstWidget<Align>(find.ancestor(of: find.text('button'), matching: find.byType(Align)));
    expect(align.alignment, Alignment.center); // default

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoButton(
          alignment: Alignment.centerLeft,
          onPressed: () { },
          child: const Text('button'),
        ),
      ),
    );

    align = tester.firstWidget<Align>(find.ancestor(of: find.text('button'), matching: find.byType(Align)));
    expect(align.alignment, Alignment.centerLeft);
  });

  testWidgets('Button with background is wider', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(child: const CupertinoButton(
      onPressed: null,
      color: Color(0xFFFFFFFF),
      child: Text('X', style: testStyle),
    )));
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size.width,
      // 1 10px character + 64 * 2 = 138 for buttons with background.
      138.0,
    );
  });

  testWidgets('Custom padding', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(child: const CupertinoButton(
      onPressed: null,
      padding: EdgeInsets.all(100.0),
      child: Text('X', style: testStyle),
    )));
    final RenderBox buttonBox = tester.renderObject(find.byType(CupertinoButton));
    expect(
      buttonBox.size,
      const Size.square(210.0),
    );
  });

  testWidgets('Button takes taps', (WidgetTester tester) async {
    bool value = false;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return boilerplate(
            child: CupertinoButton(
              child: const Text('Tap me'),
              onPressed: () {
                setState(() {
                  value = true;
                });
              },
            ),
          );
        },
      ),
    );

    expect(value, isFalse);
    // No animating by default.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
    await tester.tap(find.byType(CupertinoButton));
    expect(value, isTrue);
    // Animates.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(1));
  });

  testWidgets("Disabled button doesn't animate", (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(child: const CupertinoButton(
      onPressed: null,
      child: Text('Tap me'),
    )));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
    await tester.tap(find.byType(CupertinoButton));
    // Still doesn't animate.
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));
  });

  testWidgets('Enabled button animates', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(child: CupertinoButton(
      child: const Text('Tap me'),
      onPressed: () { },
    )));

    await tester.tap(find.byType(CupertinoButton));
    // Enter animation.
    await tester.pump();
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));

    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(0.403, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 100));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(0.400, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(0.650, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(0.894, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(0.988, epsilon: 0.001));

    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, moreOrLessEquals(1.0, epsilon: 0.001));
  });

  testWidgets('pressedOpacity defaults to 0.1', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(child: CupertinoButton(
      child: const Text('Tap me'),
      onPressed: () { },
    )));

    // Keep a "down" gesture on the button
    final Offset center = tester.getCenter(find.byType(CupertinoButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Check opacity
    final FadeTransition opacity = tester.widget(find.descendant(
      of: find.byType(CupertinoButton),
      matching: find.byType(FadeTransition),
    ));
    expect(opacity.opacity.value, 0.4);
  });

  testWidgets('pressedOpacity parameter', (WidgetTester tester) async {
    const double pressedOpacity = 0.5;
    await tester.pumpWidget(boilerplate(child: CupertinoButton(
      pressedOpacity: pressedOpacity,
      child: const Text('Tap me'),
      onPressed: () { },
    )));

    // Keep a "down" gesture on the button
    final Offset center = tester.getCenter(find.byType(CupertinoButton));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Check opacity
    final FadeTransition opacity = tester.widget(find.descendant(
      of: find.byType(CupertinoButton),
      matching: find.byType(FadeTransition),
    ));
    expect(opacity.opacity.value, pressedOpacity);
  });

  testWidgets('Cupertino button is semantically a button', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      boilerplate(
          child: Center(
            child: CupertinoButton(
              onPressed: () { },
              child: const Text('ABC'),
            ),
          ),
      ),
    );

    expect(semantics, hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            actions: SemanticsAction.tap.index,
            label: 'ABC',
            flags: SemanticsFlag.isButton.index,
          ),
        ],
      ),
      ignoreId: true,
      ignoreRect: true,
      ignoreTransform: true,
    ));

    semantics.dispose();
  });

  testWidgets('Can specify colors', (WidgetTester tester) async {
    await tester.pumpWidget(boilerplate(child: CupertinoButton(
      color: const Color(0x000000FF),
      disabledColor: const Color(0x0000FF00),
      onPressed: () { },
      child: const Text('Skeuomorph me'),
    )));

    BoxDecoration boxDecoration = tester.widget<DecoratedBox>(
      find.widgetWithText(DecoratedBox, 'Skeuomorph me'),
    ).decoration as BoxDecoration;

    expect(boxDecoration.color, const Color(0x000000FF));

    await tester.pumpWidget(boilerplate(child: const CupertinoButton(
      color: Color(0x000000FF),
      disabledColor: Color(0x0000FF00),
      onPressed: null,
      child: Text('Skeuomorph me'),
    )));

    boxDecoration = tester.widget<DecoratedBox>(
      find.widgetWithText(DecoratedBox, 'Skeuomorph me'),
    ).decoration as BoxDecoration;

    expect(boxDecoration.color, const Color(0x0000FF00));
  });

  testWidgets('Can specify dynamic colors', (WidgetTester tester) async {
    const Color bgColor = CupertinoDynamicColor.withBrightness(
      color: Color(0xFF123456),
      darkColor: Color(0xFF654321),
    );

    const Color inactive = CupertinoDynamicColor.withBrightness(
      color: Color(0xFF111111),
      darkColor: Color(0xFF222222),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.dark),
        child: boilerplate(child: CupertinoButton(
          color: bgColor,
          disabledColor: inactive,
          onPressed: () { },
          child: const Text('Skeuomorph me'),
        )),
      ),
    );

    BoxDecoration boxDecoration = tester.widget<DecoratedBox>(
      find.widgetWithText(DecoratedBox, 'Skeuomorph me'),
    ).decoration as BoxDecoration;

    expect(boxDecoration.color!.value, 0xFF654321);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: boilerplate(child: const CupertinoButton(
          color: bgColor,
          disabledColor: inactive,
          onPressed: null,
          child: Text('Skeuomorph me'),
        )),
      ),
    );

    boxDecoration = tester.widget<DecoratedBox>(
      find.widgetWithText(DecoratedBox, 'Skeuomorph me'),
    ).decoration as BoxDecoration;

    // Disabled color.
    expect(boxDecoration.color!.value, 0xFF111111);
  });

  testWidgets('Button respects themes', (WidgetTester tester) async {
    late TextStyle textStyle;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoButton(
          onPressed: () { },
          child: Builder(builder: (BuildContext context) {
            textStyle = DefaultTextStyle.of(context).style;
            return const Placeholder();
          }),
        ),
      ),
    );

    expect(textStyle.color, CupertinoColors.activeBlue);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoButton.filled(
          onPressed: () { },
          child: Builder(builder: (BuildContext context) {
            textStyle = DefaultTextStyle.of(context).style;
            return const Placeholder();
          }),
        ),
      ),
    );

    expect(textStyle.color, isSameColorAs(CupertinoColors.white));
    BoxDecoration decoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(CupertinoButton),
        matching: find.byType(DecoratedBox),
      ),
    ).decoration as BoxDecoration;
    expect(decoration.color, CupertinoColors.activeBlue);

    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: CupertinoButton(
          onPressed: () { },
          child: Builder(builder: (BuildContext context) {
            textStyle = DefaultTextStyle.of(context).style;
            return const Placeholder();
          }),
        ),
      ),
    );
    expect(textStyle.color, isSameColorAs(CupertinoColors.systemBlue.darkColor));

    await tester.pumpWidget(
      CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        home: CupertinoButton.filled(
          onPressed: () { },
          child: Builder(builder: (BuildContext context) {
            textStyle = DefaultTextStyle.of(context).style;
            return const Placeholder();
          }),
        ),
      ),
    );
    expect(textStyle.color, isSameColorAs(CupertinoColors.black));
    decoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(CupertinoButton),
        matching: find.byType(DecoratedBox),
      ),
    ).decoration as BoxDecoration;
    expect(decoration.color, isSameColorAs(CupertinoColors.systemBlue.darkColor));
  });

  testWidgets('Hovering over Cupertino button updates cursor to clickable on Web', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoButton.filled(
            onPressed: () { },
            child: const Text('Tap me'),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse, pointer: 1);
    await gesture.addPointer(location: const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);

    final Offset button = tester.getCenter(find.byType(CupertinoButton));
    await gesture.moveTo(button);
    await tester.pumpAndSettle();
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      kIsWeb ? SystemMouseCursors.click : SystemMouseCursors.basic,
    );
  });
}

Widget boilerplate({ required Widget child }) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  );
}
