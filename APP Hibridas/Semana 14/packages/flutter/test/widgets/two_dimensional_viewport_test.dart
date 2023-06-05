// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'two_dimensional_utils.dart';

void main() {
  group('TwoDimensionalChildDelegate', () {
    group('TwoDimensionalChildBuilderDelegate', () {
      testWidgets('repaintBoundaries', (WidgetTester tester) async {
        // Default - adds repaint boundaries
        await tester.pumpWidget(simpleBuilderTest(
          delegate: TwoDimensionalChildBuilderDelegate(
            // Only build 1 child
            maxXIndex: 0,
            maxYIndex: 0,
            builder: (BuildContext context, ChildVicinity vicinity) {
              return SizedBox(
                height: 200,
                width: 200,
                child: Center(child: Text('C${vicinity.xIndex}:R${vicinity.yIndex}')),
              );
            }
          )
        ));
        await tester.pumpAndSettle();

        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
            expect(find.byType(RepaintBoundary), findsNWidgets(7));
          case TargetPlatform.iOS:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            expect(find.byType(RepaintBoundary), findsNWidgets(3));
        }

        // None
        await tester.pumpWidget(simpleBuilderTest(
          delegate: TwoDimensionalChildBuilderDelegate(
            // Only build 1 child
            maxXIndex: 0,
            maxYIndex: 0,
            addRepaintBoundaries: false,
            builder: (BuildContext context, ChildVicinity vicinity) {
              return SizedBox(
                height: 200,
                width: 200,
                child: Center(child: Text('C${vicinity.xIndex}:R${vicinity.yIndex}')),
              );
            }
          )
        ));
        await tester.pumpAndSettle();

        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
            expect(find.byType(RepaintBoundary), findsNWidgets(6));
          case TargetPlatform.iOS:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            expect(find.byType(RepaintBoundary), findsNWidgets(2));
        }
      }, variant: TargetPlatformVariant.all());

      testWidgets('will return null from build for exceeding maxXIndex and maxYIndex', (WidgetTester tester) async {
        late BuildContext capturedContext;
        final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
          // Only build 1 child
          maxXIndex: 0,
          maxYIndex: 0,
          addRepaintBoundaries: false,
          builder: (BuildContext context, ChildVicinity vicinity) {
            capturedContext = context;
            return SizedBox(
              height: 200,
              width: 200,
              child: Center(child: Text('C${vicinity.xIndex}:R${vicinity.yIndex}')),
            );
          }
        );
        await tester.pumpWidget(simpleBuilderTest(
          delegate: delegate,
        ));
        await tester.pumpAndSettle();
        // maxXIndex
        expect(
          delegate.build(capturedContext, const ChildVicinity(xIndex: 1, yIndex: 0)),
          isNull,
        );

        // maxYIndex
        expect(
          delegate.build(capturedContext, const ChildVicinity(xIndex: 0, yIndex: 1)),
          isNull,
        );

        // Both
        expect(
          delegate.build(capturedContext, const ChildVicinity(xIndex: 1, yIndex: 1)),
          isNull,
        );
      }, variant: TargetPlatformVariant.all());

      testWidgets('throws an error when builder throws', (WidgetTester tester) async {
        final List<Object> exceptions = <Object>[];
        final FlutterExceptionHandler? oldHandler = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          exceptions.add(details.exception);
        };
        final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
          // Only build 1 child
          maxXIndex: 0,
          maxYIndex: 0,
          addRepaintBoundaries: false,
          builder: (BuildContext context, ChildVicinity vicinity) {
            throw 'Builder error!';
          }
        );
        await tester.pumpWidget(simpleBuilderTest(
          delegate: delegate,
        ));
        await tester.pumpAndSettle();
        FlutterError.onError = oldHandler;

        expect(exceptions.isNotEmpty, isTrue);
        expect(exceptions.length, 1);
        expect(exceptions[0] as String, contains('Builder error!'));
      }, variant: TargetPlatformVariant.all());

      testWidgets('shouldRebuild', (WidgetTester tester) async {
        expect(builderDelegate.shouldRebuild(builderDelegate), isTrue);
      }, variant: TargetPlatformVariant.all());
    });

    group('TwoDimensionalChildListDelegate', () {
      testWidgets('repaintBoundaries', (WidgetTester tester) async {
        final List<List<Widget>> children = <List<Widget>>[];
        children.add(<Widget>[
          const SizedBox(
            height: 200,
            width: 200,
            child: Center(child: Text('R0:C0')),
          )
        ]);
        // Default - adds repaint boundaries
        await tester.pumpWidget(simpleListTest(
          delegate: TwoDimensionalChildListDelegate(
            // Only builds 1 child
            children: children,
          )
        ));
        await tester.pumpAndSettle();

        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
            expect(find.byType(RepaintBoundary), findsNWidgets(7));
          case TargetPlatform.iOS:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            expect(find.byType(RepaintBoundary), findsNWidgets(3));
        }

        // None
        await tester.pumpWidget(simpleListTest(
          delegate: TwoDimensionalChildListDelegate(
            // Different children triggers rebuild
            children: <List<Widget>>[<Widget>[Container()]],
            addRepaintBoundaries: false,
          )
        ));
        await tester.pumpAndSettle();

        switch (defaultTargetPlatform) {
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
            expect(find.byType(RepaintBoundary), findsNWidgets(6));
          case TargetPlatform.iOS:
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            expect(find.byType(RepaintBoundary), findsNWidgets(2));
        }
      }, variant: TargetPlatformVariant.all());

      testWidgets('will return null for a ChildVicinity outside of list bounds', (WidgetTester tester) async {
        final List<List<Widget>> children = <List<Widget>>[];
        children.add(<Widget>[
          const SizedBox(
            height: 200,
            width: 200,
            child: Center(child: Text('R0:C0')),
          )
        ]);
        final TwoDimensionalChildListDelegate delegate = TwoDimensionalChildListDelegate(
          // Only builds 1 child
          children: children,
        );

        // X index
        expect(
          delegate.build(_NullBuildContext(), const ChildVicinity(xIndex: 1, yIndex: 0)),
          isNull,
        );
        // Y index
        expect(
          delegate.build(_NullBuildContext(), const ChildVicinity(xIndex: 0, yIndex: 1)),
          isNull,
        );

        // Both
        expect(
          delegate.build(_NullBuildContext(), const ChildVicinity(xIndex: 1, yIndex: 1)),
          isNull,
        );
      }, variant: TargetPlatformVariant.all());

      testWidgets('shouldRebuild', (WidgetTester tester) async {
        final List<List<Widget>> children = <List<Widget>>[];
        children.add(<Widget>[
          const SizedBox(
            height: 200,
            width: 200,
            child: Center(child: Text('R0:C0')),
          )
        ]);
        final TwoDimensionalChildListDelegate delegate = TwoDimensionalChildListDelegate(
          // Only builds 1 child
          children: children,
        );
        expect(delegate.shouldRebuild(delegate), isFalse);

        final List<List<Widget>> newChildren = <List<Widget>>[];
        final TwoDimensionalChildListDelegate oldDelegate = TwoDimensionalChildListDelegate(
          children: newChildren,
        );

        expect(delegate.shouldRebuild(oldDelegate), isTrue);
      }, variant: TargetPlatformVariant.all());
    });
  });

  group('TwoDimensionalScrollable', () {
    testWidgets('.of, .maybeOf', (WidgetTester tester) async {
      late BuildContext capturedContext;
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        builder: (BuildContext context, ChildVicinity vicinity) {
          capturedContext = context;
          return const SizedBox.square(dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();

      expect(TwoDimensionalScrollable.of(capturedContext), isNotNull);
      expect(TwoDimensionalScrollable.maybeOf(capturedContext), isNotNull);

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          capturedContext = context;
          TwoDimensionalScrollable.of(context);
          return Container();
        }
      ));
      await tester.pumpAndSettle();
      final dynamic exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception as FlutterError;
      expect(error.toString(), contains(
        'TwoDimensionalScrollable.of() was called with a context that does '
        'not contain a TwoDimensionalScrollable widget.'
      ));

      expect(TwoDimensionalScrollable.maybeOf(capturedContext), isNull);
    }, variant: TargetPlatformVariant.all());

    testWidgets('horizontal and vertical getters', (WidgetTester tester) async {
      late BuildContext capturedContext;
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        builder: (BuildContext context, ChildVicinity vicinity) {
          capturedContext = context;
          return const SizedBox.square(dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();

      final TwoDimensionalScrollableState scrollable = TwoDimensionalScrollable.of(capturedContext);
      expect(scrollable.verticalScrollable.position.pixels, 0.0);
      expect(scrollable.horizontalScrollable.position.pixels, 0.0);
    }, variant: TargetPlatformVariant.all());

    testWidgets('creates fallback ScrollControllers if not provided by ScrollableDetails', (WidgetTester tester) async {
      late BuildContext capturedContext;
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        builder: (BuildContext context, ChildVicinity vicinity) {
          capturedContext = context;
          return const SizedBox.square(dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();

      // Vertical
      final ScrollableState vertical = Scrollable.of(capturedContext, axis: Axis.vertical);
      expect(vertical.widget.controller, isNotNull);
      // Horizontal
      final ScrollableState horizontal = Scrollable.of(capturedContext, axis: Axis.horizontal);
      expect(horizontal.widget.controller, isNotNull);
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the axis directions do not conflict with one another', (WidgetTester tester) async {
      final List<Object> exceptions = <Object>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        exceptions.add(details.exception);
      };
      // Horizontal mismatch
      await tester.pumpWidget(TwoDimensionalScrollable(
        horizontalDetails: const ScrollableDetails.horizontal(),
        verticalDetails: const ScrollableDetails.horizontal(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return Container();
        },
      ));

      // Vertical mismatch
      await tester.pumpWidget(TwoDimensionalScrollable(
        horizontalDetails: const ScrollableDetails.vertical(),
        verticalDetails: const ScrollableDetails.vertical(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return Container();
        },
      ));

      // Both
      await tester.pumpWidget(TwoDimensionalScrollable(
        horizontalDetails: const ScrollableDetails.vertical(),
        verticalDetails: const ScrollableDetails.horizontal(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return Container();
        },
      ));

      expect(exceptions.length, 3);
      for (final Object exception in exceptions) {
        expect(exception, isAssertionError);
        expect((exception as AssertionError).message, contains('are not Axis'));
      }
      FlutterError.onError = oldHandler;
    }, variant: TargetPlatformVariant.all());

    testWidgets('correctly sets restorationIds', (WidgetTester tester) async {
      late BuildContext capturedContext;
      // with restorationID set
      await tester.pumpWidget(WidgetsApp(
        color: const Color(0xFFFFFFFF),
        restorationScopeId: 'Test ID',
        builder: (BuildContext context, Widget? child) => TwoDimensionalScrollable(
          restorationId: 'Custom Restoration ID',
          horizontalDetails: const ScrollableDetails.horizontal(),
          verticalDetails: const ScrollableDetails.vertical(),
          viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
            return SizedBox.square(
              dimension: 200,
              child: Builder(
                builder: (BuildContext context) {
                  capturedContext = context;
                  return Container();
                },
              )
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(
        RestorationScope.of(capturedContext).restorationId,
        'Custom Restoration ID',
      );
      expect(
        Scrollable.of(capturedContext, axis: Axis.vertical).widget.restorationId,
        'OuterVerticalTwoDimensionalScrollable',
      );
      expect(
        Scrollable.of(capturedContext, axis: Axis.horizontal).widget.restorationId,
        'InnerHorizontalTwoDimensionalScrollable',
      );

      // default restorationID
      await tester.pumpWidget(TwoDimensionalScrollable(
        horizontalDetails: const ScrollableDetails.horizontal(),
        verticalDetails: const ScrollableDetails.vertical(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return SizedBox.square(
            dimension: 200,
            child: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return Container();
              },
            )
          );
        },
      ));
      await tester.pumpAndSettle();

      expect(
        RestorationScope.maybeOf(capturedContext),
        isNull,
      );
      expect(
        Scrollable.of(capturedContext, axis: Axis.vertical).widget.restorationId,
        'OuterVerticalTwoDimensionalScrollable',
      );
      expect(
        Scrollable.of(capturedContext, axis: Axis.horizontal).widget.restorationId,
        'InnerHorizontalTwoDimensionalScrollable',
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('Restoration works', (WidgetTester tester) async {
      await tester.pumpWidget(WidgetsApp(
        color: const Color(0xFFFFFFFF),
        restorationScopeId: 'Test ID',
        builder: (BuildContext context, Widget? child) => TwoDimensionalScrollable(
          restorationId: 'Custom Restoration ID',
          horizontalDetails: const ScrollableDetails.horizontal(),
          verticalDetails: const ScrollableDetails.vertical(),
          viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
            return SimpleBuilderTableViewport(
              verticalOffset: verticalPosition,
              verticalAxisDirection: AxisDirection.down,
              horizontalOffset: horizontalPosition,
              horizontalAxisDirection: AxisDirection.right,
              delegate: builderDelegate,
              mainAxis: Axis.vertical,
            );
          },
        ),
      ));
      await tester.pumpAndSettle();

      await restoreScrollAndVerify(tester);
    }, variant: TargetPlatformVariant.all());

    testWidgets('Inner Scrollables receive the correct details from TwoDimensionalScrollable', (WidgetTester tester) async {
      // Default
      late BuildContext capturedContext;
      await tester.pumpWidget(TwoDimensionalScrollable(
        horizontalDetails: const ScrollableDetails.horizontal(),
        verticalDetails: const ScrollableDetails.vertical(),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return SizedBox.square(
            dimension: 200,
            child: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return Container();
              },
            )
          );
        },
      ));
      await tester.pumpAndSettle();

      // Vertical
      ScrollableState vertical = Scrollable.of(capturedContext, axis: Axis.vertical);
      expect(vertical.widget.key, isNotNull);
      expect(vertical.widget.axisDirection, AxisDirection.down);
      expect(vertical.widget.controller, isNotNull);
      expect(vertical.widget.physics, isNull);
      expect(vertical.widget.clipBehavior, Clip.hardEdge);
      expect(vertical.widget.incrementCalculator, isNull);
      expect(vertical.widget.excludeFromSemantics, isFalse);
      expect(vertical.widget.restorationId, 'OuterVerticalTwoDimensionalScrollable');
      expect(vertical.widget.dragStartBehavior, DragStartBehavior.start);

      // Horizontal
      ScrollableState horizontal = Scrollable.of(capturedContext, axis: Axis.horizontal);
      expect(horizontal.widget.key, isNotNull);
      expect(horizontal.widget.axisDirection, AxisDirection.right);
      expect(horizontal.widget.controller, isNotNull);
      expect(horizontal.widget.physics, isNull);
      expect(horizontal.widget.clipBehavior, Clip.hardEdge);
      expect(horizontal.widget.incrementCalculator, isNull);
      expect(horizontal.widget.excludeFromSemantics, isFalse);
      expect(horizontal.widget.restorationId, 'InnerHorizontalTwoDimensionalScrollable');
      expect(horizontal.widget.dragStartBehavior, DragStartBehavior.start);

      // Customized
      final ScrollController horizontalController = ScrollController();
      final ScrollController verticalController = ScrollController();
      double calculator(_) => 0.0;
      await tester.pumpWidget(TwoDimensionalScrollable(
        incrementCalculator: calculator,
        excludeFromSemantics: true,
        dragStartBehavior: DragStartBehavior.down,
        horizontalDetails: ScrollableDetails.horizontal(
          reverse: true,
          controller: horizontalController,
          physics: const ClampingScrollPhysics(),
          decorationClipBehavior: Clip.antiAlias,
        ),
        verticalDetails: ScrollableDetails.vertical(
          reverse: true,
          controller: verticalController,
          physics: const AlwaysScrollableScrollPhysics(),
          decorationClipBehavior: Clip.antiAliasWithSaveLayer,
        ),
        viewportBuilder: (BuildContext context, ViewportOffset verticalPosition, ViewportOffset horizontalPosition) {
          return SizedBox.square(
            dimension: 200,
            child: Builder(
              builder: (BuildContext context) {
                capturedContext = context;
                return Container();
              },
            )
          );
        },
      ));
      await tester.pumpAndSettle();

      // Vertical
      vertical = Scrollable.of(capturedContext, axis: Axis.vertical);
      expect(vertical.widget.key, isNotNull);
      expect(vertical.widget.axisDirection, AxisDirection.up);
      expect(vertical.widget.controller, verticalController);
      expect(vertical.widget.physics, const AlwaysScrollableScrollPhysics());
      expect(vertical.widget.clipBehavior, Clip.antiAliasWithSaveLayer);
      expect(
        vertical.widget.incrementCalculator!(ScrollIncrementDetails(
          type: ScrollIncrementType.line,
          metrics: verticalController.position,
        )),
        0.0,
      );
      expect(vertical.widget.excludeFromSemantics, isTrue);
      expect(vertical.widget.restorationId, 'OuterVerticalTwoDimensionalScrollable');
      expect(vertical.widget.dragStartBehavior, DragStartBehavior.down);

      // Horizontal
      horizontal = Scrollable.of(capturedContext, axis: Axis.horizontal);
      expect(horizontal.widget.key, isNotNull);
      expect(horizontal.widget.axisDirection, AxisDirection.left);
      expect(horizontal.widget.controller, horizontalController);
      expect(horizontal.widget.physics, const ClampingScrollPhysics());
      expect(horizontal.widget.clipBehavior, Clip.antiAlias);
      expect(
        horizontal.widget.incrementCalculator!(ScrollIncrementDetails(
          type: ScrollIncrementType.line,
          metrics: horizontalController.position,
        )),
        0.0,
      );
      expect(horizontal.widget.excludeFromSemantics, isTrue);
      expect(horizontal.widget.restorationId, 'InnerHorizontalTwoDimensionalScrollable');
      expect(horizontal.widget.dragStartBehavior, DragStartBehavior.down);
    }, variant: TargetPlatformVariant.all());

    group('DiagonalDragBehavior', () {
      testWidgets('none (default)', (WidgetTester tester) async {
        // Vertical and horizontal axes are locked.
        final ScrollController verticalController = ScrollController();
        final ScrollController horizontalController = ScrollController();
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: simpleBuilderTest(
            verticalDetails: ScrollableDetails.vertical(controller: verticalController),
            horizontalDetails: ScrollableDetails.horizontal(controller: horizontalController),
          )
        ));
        await tester.pumpAndSettle();
        final Finder findScrollable = find.byElementPredicate((Element e) => e.widget is TwoDimensionalScrollable);

        expect(verticalController.position.pixels, 0.0);
        expect(horizontalController.position.pixels, 0.0);
        await tester.drag(findScrollable, const Offset(0.0, -100.0));
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 80.0);
        expect(horizontalController.position.pixels, 0.0);
        await tester.drag(findScrollable, const Offset(-100.0, 0.0));
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 80.0);
        expect(horizontalController.position.pixels, 80.0);
        // Drag with and x and y offset, only vertical will accept the gesture
        // since the x is < kTouchSlop
        await tester.drag(findScrollable, const Offset(-10.0, -50.0));
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 110.0);
        expect(horizontalController.position.pixels, 80.0);
        // Drag with and x and y offset, only horizontal will accept the gesture
        // since the y is < kTouchSlop
        await tester.drag(findScrollable, const Offset(-50.0, -10.0));
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 110.0);
        expect(horizontalController.position.pixels, 110.0);
        // Drag with and x and y offset, only vertical will accept the gesture
        //  x is > kTouchSlop, larger offset wins
        await tester.drag(findScrollable, const Offset(-20.0, -50.0));
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 140.0);
        expect(horizontalController.position.pixels, 110.0);
        // Drag with and x and y offset, only horizontal will accept the gesture
        //  y is > kTouchSlop, larger offset wins
        await tester.drag(findScrollable, const Offset(-50.0, -20.0));
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 140.0);
        expect(horizontalController.position.pixels, 140.0);
      }, variant: TargetPlatformVariant.all());

      testWidgets('weightedEvent', (WidgetTester tester) async {
        // For weighted event, the winning axis is locked for the duration of
        // the gesture.
        final ScrollController verticalController = ScrollController();
        final ScrollController horizontalController = ScrollController();
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: simpleBuilderTest(
            diagonalDrag: DiagonalDragBehavior.weightedEvent,
            verticalDetails: ScrollableDetails.vertical(controller: verticalController),
            horizontalDetails: ScrollableDetails.horizontal(controller: horizontalController),
          )
        ));
        await tester.pumpAndSettle();
        final Finder findScrollable = find.byElementPredicate((Element e) => e.widget is TwoDimensionalScrollable);

        // Locks to vertical axis - simple.
        expect(verticalController.position.pixels, 0.0);
        expect(horizontalController.position.pixels, 0.0);
        TestGesture gesture = await tester.startGesture(tester.getCenter(findScrollable));
        // In this case, the vertical axis clearly wins.
        Offset secondLocation = tester.getCenter(findScrollable) + const Offset(0.0, -50.0);
        await gesture.moveTo(secondLocation);
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 50.0);
        expect(horizontalController.position.pixels, 0.0);
        // Gesture has not ended yet, move with horizontal diff
        Offset thirdLocation = secondLocation + const Offset(-30, -15);
        await gesture.moveTo(thirdLocation);
        await tester.pumpAndSettle();
        // Only vertical diff applied
        expect(verticalController.position.pixels, 65.0);
        expect(horizontalController.position.pixels, 0.0);
        await gesture.up();
        await tester.pumpAndSettle();

        // Lock to vertical axis - scrolls diagonally until certain
        verticalController.jumpTo(0.0);
        horizontalController.jumpTo(0.0);
        await tester.pump();
        expect(verticalController.position.pixels, 0.0);
        expect(horizontalController.position.pixels, 0.0);
        gesture = await tester.startGesture(tester.getCenter(findScrollable));
        // In this case, the no one clearly wins, so it moves diagonally.
        secondLocation = tester.getCenter(findScrollable) + const Offset(-50.0, -50.0);
        await gesture.moveTo(secondLocation);
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 50.0);
        expect(horizontalController.position.pixels, 50.0);
        // Gesture has not ended yet, move clearly indicating vertical
        thirdLocation = secondLocation + const Offset(-20, -50);
        await gesture.moveTo(thirdLocation);
        await tester.pumpAndSettle();
        // Only vertical diff applied
        expect(verticalController.position.pixels, 100.0);
        expect(horizontalController.position.pixels, 50.0);
        // Gesture has not ended yet, and vertical axis has won for the gesture
        // continue only vertical scrolling.
        Offset fourthLocation = thirdLocation + const Offset(-30, -30);
        await gesture.moveTo(fourthLocation);
        await tester.pumpAndSettle();
        // Only vertical diff applied
        expect(verticalController.position.pixels, 130.0);
        expect(horizontalController.position.pixels, 50.0);
        await gesture.up();
        await tester.pumpAndSettle();

        // Locks to horizontal axis - simple.
        verticalController.jumpTo(0.0);
        horizontalController.jumpTo(0.0);
        await tester.pump();
        expect(verticalController.position.pixels, 0.0);
        expect(horizontalController.position.pixels, 0.0);
        gesture = await tester.startGesture(tester.getCenter(findScrollable));
        // In this case, the horizontal axis clearly wins.
        secondLocation = tester.getCenter(findScrollable) + const Offset(-50.0, 0.0);
        await gesture.moveTo(secondLocation);
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 0.0);
        expect(horizontalController.position.pixels, 50.0);
        // Gesture has not ended yet, move with vertical diff
        thirdLocation = secondLocation + const Offset(-15, -30);
        await gesture.moveTo(thirdLocation);
        await tester.pumpAndSettle();
        // Only vertical diff applied
        expect(verticalController.position.pixels, 0.0);
        expect(horizontalController.position.pixels, 65.0);
        await gesture.up();
        await tester.pumpAndSettle();

        // Lock to horizontal axis - scrolls diagonally until certain
        verticalController.jumpTo(0.0);
        horizontalController.jumpTo(0.0);
        await tester.pump();
        expect(verticalController.position.pixels, 0.0);
        expect(horizontalController.position.pixels, 0.0);
        gesture = await tester.startGesture(tester.getCenter(findScrollable));
        // In this case, the no one clearly wins, so it moves diagonally.
        secondLocation = tester.getCenter(findScrollable) + const Offset(-50.0, -50.0);
        await gesture.moveTo(secondLocation);
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 50.0);
        expect(horizontalController.position.pixels, 50.0);
        // Gesture has not ended yet, move clearly indicating horizontal
        thirdLocation = secondLocation + const Offset(-50, -20);
        await gesture.moveTo(thirdLocation);
        await tester.pumpAndSettle();
        // Only horizontal diff applied
        expect(verticalController.position.pixels, 50.0);
        expect(horizontalController.position.pixels, 100.0);
        // Gesture has not ended yet, and horizontal axis has won for the gesture
        // continue only horizontal scrolling.
        fourthLocation = thirdLocation + const Offset(-30, -30);
        await gesture.moveTo(fourthLocation);
        await tester.pumpAndSettle();
        // Only horizontal diff applied
        expect(verticalController.position.pixels, 50.0);
        expect(horizontalController.position.pixels, 130.0);
        await gesture.up();
        await tester.pumpAndSettle();
      }, variant: TargetPlatformVariant.all());

      testWidgets('weightedContinuous', (WidgetTester tester) async {
        // For weighted continuous, the winning axis can change if the axis
        // differential for the gesture exceeds kTouchSlop. So it can lock, and
        // remain locked, if the user maintains a generally straight gesture,
        // otherwise it will unlock and re-evaluate.
        final ScrollController verticalController = ScrollController();
        final ScrollController horizontalController = ScrollController();
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: simpleBuilderTest(
            diagonalDrag: DiagonalDragBehavior.weightedContinuous,
            verticalDetails: ScrollableDetails.vertical(controller: verticalController),
            horizontalDetails: ScrollableDetails.horizontal(controller: horizontalController),
          )
        ));
        await tester.pumpAndSettle();
        final Finder findScrollable = find.byElementPredicate((Element e) => e.widget is TwoDimensionalScrollable);

        // Locks to vertical, and then unlocks, resets to horizontal, then
        // unlocks and scrolls diagonally.
        expect(verticalController.position.pixels, 0.0);
        expect(horizontalController.position.pixels, 0.0);
        final TestGesture gesture = await tester.startGesture(tester.getCenter(findScrollable));
        // In this case, the vertical axis clearly wins.
        final Offset secondLocation = tester.getCenter(findScrollable) + const Offset(0.0, -50.0);
        await gesture.moveTo(secondLocation);
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 50.0);
        expect(horizontalController.position.pixels, 0.0);
        // Gesture has not ended yet, move with horizontal diff, but still
        // dominant vertical
        final Offset thirdLocation = secondLocation + const Offset(-15, -50);
        await gesture.moveTo(thirdLocation);
        await tester.pumpAndSettle();
        // Only vertical diff applied since kTouchSlop was not exceeded in the
        // horizontal axis from one drag event to the next.
        expect(verticalController.position.pixels, 100.0);
        expect(horizontalController.position.pixels, 0.0);
        // Gesture has not ended yet, move with unlocking horizontal diff
        final Offset fourthLocation = thirdLocation + const Offset(-50, -15);
        await gesture.moveTo(fourthLocation);
        await tester.pumpAndSettle();
        // Only horizontal diff applied
        expect(verticalController.position.pixels, 100.0);
        expect(horizontalController.position.pixels, 50.0);
        // Gesture has not ended yet, move with unlocking diff that results in
        // diagonal move since neither wins.
        final Offset fifthLocation = fourthLocation + const Offset(-50, -50);
        await gesture.moveTo(fifthLocation);
        await tester.pumpAndSettle();
        // Only horizontal diff applied
        expect(verticalController.position.pixels, 150.0);
        expect(horizontalController.position.pixels, 100.0);
        await gesture.up();
        await tester.pumpAndSettle();
      }, variant: TargetPlatformVariant.all());

      testWidgets('free', (WidgetTester tester) async {
        // For free, anything goes.
        final ScrollController verticalController = ScrollController();
        final ScrollController horizontalController = ScrollController();
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: simpleBuilderTest(
            diagonalDrag: DiagonalDragBehavior.free,
            verticalDetails: ScrollableDetails.vertical(controller: verticalController),
            horizontalDetails: ScrollableDetails.horizontal(controller: horizontalController),
          )
        ));
        await tester.pumpAndSettle();
        final Finder findScrollable = find.byElementPredicate((Element e) => e.widget is TwoDimensionalScrollable);

        // Nothing locks.
        expect(verticalController.position.pixels, 0.0);
        expect(horizontalController.position.pixels, 0.0);
        final TestGesture gesture = await tester.startGesture(tester.getCenter(findScrollable));
        final Offset secondLocation = tester.getCenter(findScrollable) + const Offset(0.0, -50.0);
        await gesture.moveTo(secondLocation);
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 50.0);
        expect(horizontalController.position.pixels, 0.0);
        final Offset thirdLocation = secondLocation + const Offset(-15, -50);
        await gesture.moveTo(thirdLocation);
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 100.0);
        expect(horizontalController.position.pixels, 15.0);
        final Offset fourthLocation = thirdLocation + const Offset(-50, -15);
        await gesture.moveTo(fourthLocation);
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 115.0);
        expect(horizontalController.position.pixels, 65.0);
        final Offset fifthLocation = fourthLocation + const Offset(-50, -50);
        await gesture.moveTo(fifthLocation);
        await tester.pumpAndSettle();
        expect(verticalController.position.pixels, 165.0);
        expect(horizontalController.position.pixels, 115.0);
        await gesture.up();
        await tester.pumpAndSettle();
      });
    });
  });

  testWidgets('TwoDimensionalViewport asserts against axes mismatch', (WidgetTester tester) async {
    // Horizontal mismatch
    expect(
      () {
        SimpleBuilderTableViewport(
          verticalOffset: ViewportOffset.fixed(0.0),
          verticalAxisDirection: AxisDirection.left,
          horizontalOffset: ViewportOffset.fixed(0.0),
          horizontalAxisDirection: AxisDirection.right,
          delegate: builderDelegate,
          mainAxis: Axis.vertical,
        );
      },
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          'description',
          contains('AxisDirection is not Axis.'),
        ),
      ),
    );

    // Vertical mismatch
    expect(
      () {
        SimpleBuilderTableViewport(
          verticalOffset: ViewportOffset.fixed(0.0),
          verticalAxisDirection: AxisDirection.up,
          horizontalOffset: ViewportOffset.fixed(0.0),
          horizontalAxisDirection: AxisDirection.down,
          delegate: builderDelegate,
          mainAxis: Axis.vertical,
        );
      },
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          'description',
          contains('AxisDirection is not Axis.'),
        ),
      ),
    );

    // Both
    expect(
      () {
        SimpleBuilderTableViewport(
          verticalOffset: ViewportOffset.fixed(0.0),
          verticalAxisDirection: AxisDirection.left,
          horizontalOffset: ViewportOffset.fixed(0.0),
          horizontalAxisDirection: AxisDirection.down,
          delegate: builderDelegate,
          mainAxis: Axis.vertical,
        );
      },
      throwsA(
        isA<AssertionError>().having(
          (AssertionError error) => error.toString(),
          'description',
          contains('AxisDirection is not Axis.'),
        ),
      ),
    );
  });

  test('TwoDimensionalViewportParentData', () {
    // Default vicinity is invalid
    final TwoDimensionalViewportParentData parentData = TwoDimensionalViewportParentData();
    expect(parentData.vicinity, ChildVicinity.invalid);

    // toString
    parentData
      ..vicinity = const ChildVicinity(xIndex: 10, yIndex: 10)
      ..paintOffset = const Offset(20.0, 20.0)
      ..layoutOffset = const Offset(20.0, 20.0);
    expect(
      parentData.toString(),
      'vicinity=(xIndex: 10, yIndex: 10); layoutOffset=Offset(20.0, 20.0); '
      'paintOffset=Offset(20.0, 20.0); not visible ',
    );
  });

  test('ChildVicinity comparable', () {
    const ChildVicinity baseVicinity = ChildVicinity(xIndex: 0, yIndex: 0);
    const ChildVicinity sameXVicinity = ChildVicinity(xIndex: 0, yIndex: 2);
    const ChildVicinity sameYVicinity = ChildVicinity(xIndex: 3, yIndex: 0);
    const ChildVicinity sameNothingVicinity = ChildVicinity(xIndex: 20, yIndex: 30);
    // ==
    expect(baseVicinity == baseVicinity, isTrue);
    expect(baseVicinity == sameXVicinity, isFalse);
    expect(baseVicinity == sameYVicinity, isFalse);
    expect(baseVicinity == sameNothingVicinity, isFalse);

    // compareTo
    expect(baseVicinity.compareTo(baseVicinity), 0);
    expect(baseVicinity.compareTo(sameXVicinity), -2);
    expect(baseVicinity.compareTo(sameYVicinity), -3);
    expect(baseVicinity.compareTo(sameNothingVicinity), -20);

    // toString
    expect(baseVicinity.toString(), '(xIndex: 0, yIndex: 0)');
    expect(sameXVicinity.toString(), '(xIndex: 0, yIndex: 2)');
    expect(sameYVicinity.toString(), '(xIndex: 3, yIndex: 0)');
    expect(sameNothingVicinity.toString(), '(xIndex: 20, yIndex: 30)');
  });

  group('RenderTwoDimensionalViewport', () {
    testWidgets('asserts against axes mismatch', (WidgetTester tester) async {
      // Horizontal mismatch
      expect(
        () {
          RenderSimpleBuilderTableViewport(
            verticalOffset: ViewportOffset.fixed(0.0),
            verticalAxisDirection: AxisDirection.left,
            horizontalOffset: ViewportOffset.fixed(0.0),
            horizontalAxisDirection: AxisDirection.right,
            delegate: builderDelegate,
            mainAxis: Axis.vertical,
            childManager: _NullBuildContext(),
          );
        },
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.toString(),
            'description',
            contains('AxisDirection is not Axis.'),
          ),
        ),
      );

      // Vertical mismatch
      expect(
        () {
          RenderSimpleBuilderTableViewport(
            verticalOffset: ViewportOffset.fixed(0.0),
            verticalAxisDirection: AxisDirection.up,
            horizontalOffset: ViewportOffset.fixed(0.0),
            horizontalAxisDirection: AxisDirection.down,
            delegate: builderDelegate,
            mainAxis: Axis.vertical,
            childManager: _NullBuildContext(),
          );
        },
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.toString(),
            'description',
            contains('AxisDirection is not Axis.'),
          ),
        ),
      );

      // Both
      expect(
        () {
          RenderSimpleBuilderTableViewport(
            verticalOffset: ViewportOffset.fixed(0.0),
            verticalAxisDirection: AxisDirection.left,
            horizontalOffset: ViewportOffset.fixed(0.0),
            horizontalAxisDirection: AxisDirection.down,
            delegate: builderDelegate,
            mainAxis: Axis.vertical,
            childManager: _NullBuildContext(),
          );
        },
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.toString(),
            'description',
            contains('AxisDirection is not Axis.'),
          ),
        ),
      );
    });

    testWidgets('getters', (WidgetTester tester) async {
      final UniqueKey childKey = UniqueKey();
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        builder: (BuildContext context, ChildVicinity vicinity) {
          return SizedBox.square(key: childKey, dimension: 200);
        }
      );
      final RenderSimpleBuilderTableViewport renderViewport = RenderSimpleBuilderTableViewport(
        verticalOffset: ViewportOffset.fixed(10.0),
        verticalAxisDirection: AxisDirection.down,
        horizontalOffset: ViewportOffset.fixed(20.0),
        horizontalAxisDirection: AxisDirection.right,
        delegate: delegate,
        mainAxis: Axis.vertical,
        childManager: _NullBuildContext(),
      );

      expect(renderViewport.clipBehavior, Clip.hardEdge);
      expect(renderViewport.cacheExtent, RenderAbstractViewport.defaultCacheExtent);
      expect(renderViewport.isRepaintBoundary, isTrue);
      expect(renderViewport.sizedByParent, isTrue);
      // No size yet, should assert.
      expect(
        () {
          renderViewport.viewportDimension;
        },
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.toString(),
            'description',
            contains('hasSize'),
          ),
        ),
      );
      expect(renderViewport.horizontalOffset.pixels, 20.0);
      expect(renderViewport.horizontalAxisDirection, AxisDirection.right);
      expect(renderViewport.verticalOffset.pixels, 10.0);
      expect(renderViewport.verticalAxisDirection, AxisDirection.down);
      expect(renderViewport.delegate, delegate);
      expect(renderViewport.mainAxis, Axis.vertical);

      // viewportDimension when hasSize
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();
      final RenderTwoDimensionalViewport viewport = getViewport(tester, childKey);
      expect(viewport.viewportDimension, const Size(800.0, 600.0));
    }, variant: TargetPlatformVariant.all());

    testWidgets('Children are organized according to mainAxis', (WidgetTester tester) async {
      final Map<ChildVicinity, UniqueKey> childKeys = <ChildVicinity, UniqueKey>{};
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 5,
        maxYIndex: 5,
        builder: (BuildContext context, ChildVicinity vicinity) {
          childKeys[vicinity] = UniqueKey();
          return SizedBox.square(key: childKeys[vicinity], dimension: 200);
        }
      );
      TwoDimensionalViewportParentData parentDataOf(RenderBox child) {
        return child.parentData! as TwoDimensionalViewportParentData;
      }
      // mainAxis is vertical (default)
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();
      RenderTwoDimensionalViewport viewport = getViewport(
        tester,
        childKeys.values.first,
      );
      expect(viewport.mainAxis, Axis.vertical);
      // first child
      expect(
        parentDataOf(viewport.firstChild!).vicinity,
        const ChildVicinity(xIndex: 0, yIndex: 0),
      );
      expect(
        parentDataOf(viewport.childAfter(viewport.firstChild!)!).vicinity,
        const ChildVicinity(xIndex: 1, yIndex: 0),
      );
      expect(
        viewport.childBefore(viewport.firstChild!),
        isNull,
      );
      // last child
      expect(
        parentDataOf(viewport.lastChild!).vicinity,
        const ChildVicinity(xIndex: 4, yIndex: 3),
      );
      expect(
        viewport.childAfter(viewport.lastChild!),
        isNull,
      );
      expect(
        parentDataOf(viewport.childBefore(viewport.lastChild!)!).vicinity,
        const ChildVicinity(xIndex: 3, yIndex: 3),
      );

      // mainAxis is horizontal
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        mainAxis: Axis.horizontal,
      ));
      await tester.pumpAndSettle();
      viewport = getViewport(tester, childKeys.values.first);
      expect(viewport.mainAxis, Axis.horizontal);
      // first child
      expect(
        parentDataOf(viewport.firstChild!).vicinity,
        const ChildVicinity(xIndex: 0, yIndex: 0),
      );
      expect(
        parentDataOf(viewport.childAfter(viewport.firstChild!)!).vicinity,
        const ChildVicinity(xIndex: 0, yIndex: 1),
      );
      expect(
        viewport.childBefore(viewport.firstChild!),
        isNull,
      );
      // last child
      expect(
        parentDataOf(viewport.lastChild!).vicinity,
        const ChildVicinity(xIndex: 4, yIndex: 3),
      );
      expect(
        viewport.childAfter(viewport.lastChild!),
        isNull,
      );
      expect(
        parentDataOf(viewport.childBefore(viewport.lastChild!)!).vicinity,
        const ChildVicinity(xIndex: 4, yIndex: 2),
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('sets up parent data', (WidgetTester tester) async {
      // Also tests computeChildPaintOffset & computeChildPaintExtent
      final Map<ChildVicinity, UniqueKey> childKeys = <ChildVicinity, UniqueKey>{};
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 5,
        maxYIndex: 5,
        builder: (BuildContext context, ChildVicinity vicinity) {
          childKeys[vicinity] = UniqueKey();
          return SizedBox.square(key: childKeys[vicinity], dimension: 200);
        }
      );

      // parent data is TwoDimensionalViewportParentData
      TwoDimensionalViewportParentData parentDataOf(RenderBox child) {
        return child.parentData! as TwoDimensionalViewportParentData;
      }

      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        useCacheExtent: true,
      ));
      await tester.pumpAndSettle();

      RenderTwoDimensionalViewport viewport = getViewport(
        tester,
        childKeys.values.first,
      );

      // first child
      // parentData is computed correctly - normal axes
      // - layoutOffset, paintOffset, isVisible, ChildVicinity
      TwoDimensionalViewportParentData childParentData = parentDataOf(viewport.firstChild!);
      expect(childParentData.vicinity, const ChildVicinity(xIndex: 0, yIndex: 0));
      expect(childParentData.isVisible, isTrue);
      expect(childParentData.paintOffset, Offset.zero);
      expect(childParentData.layoutOffset, Offset.zero);
      // The last child is in the cache extent, and should not be visible.
      childParentData = parentDataOf(viewport.lastChild!);
      expect(childParentData.vicinity, const ChildVicinity(xIndex: 5, yIndex: 5));
      expect(childParentData.isVisible, isFalse);
      expect(childParentData.paintOffset, const Offset(1000.0, 1000.0));
      expect(childParentData.layoutOffset, const Offset(1000.0, 1000.0));

      // parentData is computed correctly - reverse axes
      // - vertical reverse
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        verticalDetails: const ScrollableDetails.vertical(reverse: true),
      ));
      await tester.pumpAndSettle();

      viewport = getViewport(tester, childKeys.values.first);

      childParentData = parentDataOf(viewport.firstChild!);
      expect(childParentData.vicinity, const ChildVicinity(xIndex: 0, yIndex: 0));
      expect(childParentData.isVisible, isTrue);
      expect(childParentData.paintOffset, const Offset(0.0, 400.0));
      expect(childParentData.layoutOffset, Offset.zero);
      // The last child is in the cache extent, and should not be visible.
      childParentData = parentDataOf(viewport.lastChild!);
      expect(childParentData.vicinity, const ChildVicinity(xIndex: 5, yIndex: 5));
      expect(childParentData.isVisible, isFalse);
      expect(childParentData.paintOffset, const Offset(1000.0, -400.0));
      expect(childParentData.layoutOffset, const Offset(1000.0, 1000.0));

      // - horizontal reverse
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        horizontalDetails: const ScrollableDetails.horizontal(reverse: true),
      ));
      await tester.pumpAndSettle();

      viewport = getViewport(tester, childKeys.values.first);

      childParentData = parentDataOf(viewport.firstChild!);
      expect(childParentData.vicinity, const ChildVicinity(xIndex: 0, yIndex: 0));
      expect(childParentData.isVisible, isTrue);
      expect(childParentData.paintOffset, const Offset(600.0, 0.0));
      expect(childParentData.layoutOffset, Offset.zero);
      // The last child is in the cache extent, and should not be visible.
      childParentData = parentDataOf(viewport.lastChild!);
      expect(childParentData.vicinity, const ChildVicinity(xIndex: 5, yIndex: 5));
      expect(childParentData.isVisible, isFalse);
      expect(childParentData.paintOffset, const Offset(-200.0, 1000.0));
      expect(childParentData.layoutOffset, const Offset(1000.0, 1000.0));

      // - both reverse
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        horizontalDetails: const ScrollableDetails.horizontal(reverse: true),
        verticalDetails: const ScrollableDetails.vertical(reverse: true),
      ));
      await tester.pumpAndSettle();

      viewport = getViewport(tester, childKeys.values.first);

      childParentData = parentDataOf(viewport.firstChild!);
      expect(childParentData.vicinity, const ChildVicinity(xIndex: 0, yIndex: 0));
      expect(childParentData.isVisible, isTrue);
      expect(childParentData.paintOffset, const Offset(600.0, 400.0));
      expect(childParentData.layoutOffset, Offset.zero);
      // The last child is in the cache extent, and should not be visible.
      childParentData = parentDataOf(viewport.lastChild!);
      expect(childParentData.vicinity, const ChildVicinity(xIndex: 5, yIndex: 5));
      expect(childParentData.isVisible, isFalse);
      expect(childParentData.paintOffset, const Offset(-200.0, -400.0));
      expect(childParentData.layoutOffset, const Offset(1000.0, 1000.0));

      // Change the scroll positions to test partially visible.
      final ScrollController verticalController = ScrollController();
      final ScrollController horizontalController = ScrollController();
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        horizontalDetails: ScrollableDetails.horizontal(controller: horizontalController),
        verticalDetails: ScrollableDetails.vertical(controller: verticalController),
      ));
      await tester.pumpAndSettle();
      verticalController.jumpTo(50.0);
      horizontalController.jumpTo(50.0);
      await tester.pump();

      viewport = getViewport(tester, childKeys.values.first);

      childParentData = parentDataOf(viewport.firstChild!);
      expect(childParentData.vicinity, const ChildVicinity(xIndex: 0, yIndex: 0));
      expect(childParentData.isVisible, isTrue);
      expect(childParentData.paintOffset, const Offset(-50.0, -50.0));
      expect(childParentData.layoutOffset, const Offset(-50.0, -50.0));
    }, variant: TargetPlatformVariant.all());

    testWidgets('debugDescribeChildren', (WidgetTester tester) async {
      final Map<ChildVicinity, UniqueKey> childKeys = <ChildVicinity, UniqueKey>{};
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 5,
        maxYIndex: 5,
        builder: (BuildContext context, ChildVicinity vicinity) {
          childKeys[vicinity] = UniqueKey();
          return SizedBox.square(key: childKeys[vicinity], dimension: 200);
        }
      );

      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();

      final RenderTwoDimensionalViewport viewport = getViewport(
        tester,
        childKeys.values.first,
      );
      final List<DiagnosticsNode> result = viewport.debugDescribeChildren();
      expect(result.length, 20);
      expect(
        result.first.toString(),
        equalsIgnoringHashCodes('(xIndex: 0, yIndex: 0): RenderRepaintBoundary#00000'),
      );
      expect(
        result.last.toString(),
        equalsIgnoringHashCodes('(xIndex: 4, yIndex: 3): RenderRepaintBoundary#00000 NEEDS-PAINT'),
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts that both axes are bounded', (WidgetTester tester) async {
      final List<Object> exceptions = <Object>[];
      final FlutterExceptionHandler? oldHandler = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        exceptions.add(details.exception);
      };
      // Compose unbounded - vertical axis
      await tester.pumpWidget(WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (BuildContext context, Widget? child) => Column(
          children: <Widget>[
            SimpleBuilderTableView(delegate: builderDelegate)
          ]
        ),
      ));
      await tester.pumpAndSettle();
      FlutterError.onError = oldHandler;
      expect(exceptions.isNotEmpty, isTrue);
      expect((exceptions[0] as FlutterError).message, contains('unbounded'));

      exceptions.clear();
      FlutterError.onError = (FlutterErrorDetails details) {
        exceptions.add(details.exception);
      };
      // Compose unbounded - horizontal axis
      await tester.pumpWidget(WidgetsApp(
        color: const Color(0xFFFFFFFF),
        builder: (BuildContext context, Widget? child) => Row(
          children: <Widget>[
            SimpleBuilderTableView(delegate: builderDelegate)
          ]
        ),
      ));
      await tester.pumpAndSettle();
      FlutterError.onError = oldHandler;
      expect(exceptions.isNotEmpty, isTrue);
      expect((exceptions[0] as FlutterError).message, contains('unbounded'));
    }, variant: TargetPlatformVariant.all());

    testWidgets('computeDryLayout asserts axes are bounded', (WidgetTester tester) async {
      final UniqueKey childKey = UniqueKey();
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        builder: (BuildContext context, ChildVicinity vicinity) {
          return SizedBox.square(key: childKey, dimension: 200);
        }
      );
      // Call computeDryLayout with unbounded constraints
      await tester.pumpWidget(simpleBuilderTest(delegate: delegate));
      final RenderTwoDimensionalViewport viewport = getViewport(
        tester,
        childKey,
      );
      expect(
        () {
          viewport.computeDryLayout(const BoxConstraints());
        },
        throwsA(
          isA<FlutterError>().having(
            (FlutterError error) => error.message,
            'error.message',
            contains('unbounded'),
          ),
        ),
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('correctly resizes dimensions', (WidgetTester tester) async {
      final UniqueKey childKey = UniqueKey();
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        builder: (BuildContext context, ChildVicinity vicinity) {
          return SizedBox.square(key: childKey, dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();
      RenderTwoDimensionalViewport viewport = getViewport(
        tester,
        childKey,
      );
      expect(viewport.viewportDimension, const Size(800.0, 600.0));
      tester.view.physicalSize = const Size(300.0, 300.0);
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();
      viewport = getViewport(tester, childKey);
      expect(viewport.viewportDimension, const Size(300.0, 300.0));
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }, variant: TargetPlatformVariant.all());

    testWidgets('Rebuilds when delegate changes', (WidgetTester tester) async {
      final UniqueKey firstChildKey = UniqueKey();
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        addRepaintBoundaries: false,
        builder: (BuildContext context, ChildVicinity vicinity) {
          return SizedBox.square(key: firstChildKey, dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      RenderTwoDimensionalViewport viewport = getViewport(tester, firstChildKey);
      expect(viewport.firstChild, tester.renderObject<RenderBox>(find.byKey(firstChildKey)));
      // New delegate
      final UniqueKey newChildKey = UniqueKey();
      final TwoDimensionalChildBuilderDelegate newDelegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 0,
        maxYIndex: 0,
        addRepaintBoundaries: false,
        builder: (BuildContext context, ChildVicinity vicinity) {
          return Container(key: newChildKey, height: 300, width: 300, color: const Color(0xFFFFFFFF));
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: newDelegate,
      ));
      viewport = getViewport(tester, newChildKey);
      expect(firstChildKey, isNot(newChildKey));
      expect(find.byKey(firstChildKey), findsNothing);
      expect(find.byKey(newChildKey), findsOneWidget);
      expect(viewport.firstChild, tester.renderObject<RenderBox>(find.byKey(newChildKey)));
    }, variant: TargetPlatformVariant.all());

    testWidgets('hitTestChildren', (WidgetTester tester) async {
      final List<ChildVicinity> taps = <ChildVicinity>[];
      final Map<ChildVicinity, UniqueKey> childKeys = <ChildVicinity, UniqueKey>{};
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 19,
        maxYIndex: 19,
        builder: (BuildContext context, ChildVicinity vicinity) {
          childKeys[vicinity] = UniqueKey();
          return SizedBox.square(
            dimension: 200,
            child: Center(
              child: FloatingActionButton(
                key: childKeys[vicinity],
                onPressed: () {
                  taps.add(vicinity);
                },
              ),
            ),
          );
        }
      );

      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        useCacheExtent: true, // Untappable children are rendered in the cache extent
      ));
      await tester.pumpAndSettle();
      // Regular orientation
      // Offset at center of first child
      await tester.tapAt(const Offset(100.0, 100.0));
      await tester.pump();
      expect(taps.contains(const ChildVicinity(xIndex: 0, yIndex: 0)), isTrue);
      // Offset by child location
      await tester.tap(find.byKey(childKeys[const ChildVicinity(xIndex: 2, yIndex: 2)]!));
      await tester.pump();
      expect(taps.contains(const ChildVicinity(xIndex: 2, yIndex: 2)), isTrue);
      // Offset out of bounds
      await tester.tap(
        find.byKey(childKeys[const ChildVicinity(xIndex: 5, yIndex: 5)]!),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(taps.contains(const ChildVicinity(xIndex: 5, yIndex: 5)), isFalse);

      // Reversed
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        verticalDetails: const ScrollableDetails.vertical(reverse: true),
        horizontalDetails: const ScrollableDetails.horizontal(reverse: true),
        useCacheExtent: true, // Untappable children are rendered in the cache extent
      ));
      await tester.pumpAndSettle();
      // Offset at center of first child
      await tester.tapAt(const Offset(700.0, 500.0));
      await tester.pump();
      expect(taps.contains(const ChildVicinity(xIndex: 0, yIndex: 0)), isTrue);
      // Offset by child location
      await tester.tap(find.byKey(childKeys[const ChildVicinity(xIndex: 2, yIndex: 2)]!));
      await tester.pump();
      expect(taps.contains(const ChildVicinity(xIndex: 2, yIndex: 2)), isTrue);
      // Offset out of bounds
      await tester.tap(
        find.byKey(childKeys[const ChildVicinity(xIndex: 5, yIndex: 5)]!),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(taps.contains(const ChildVicinity(xIndex: 5, yIndex: 5)), isFalse);
    }, variant: TargetPlatformVariant.all());

    testWidgets('getChildFor', (WidgetTester tester) async {
      final Map<ChildVicinity, UniqueKey> childKeys = <ChildVicinity, UniqueKey>{};
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 5,
        maxYIndex: 5,
        builder: (BuildContext context, ChildVicinity vicinity) {
          childKeys[vicinity] = UniqueKey();
          return SizedBox.square(key: childKeys[vicinity], dimension: 200);
        }
      );

      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();

      final RenderSimpleBuilderTableViewport viewport = getViewport(
        tester, childKeys.values.first,
      ) as RenderSimpleBuilderTableViewport;
      // returns child
      expect(
        viewport.testGetChildFor(const ChildVicinity(xIndex: 0, yIndex: 0)),
        isNotNull,
      );
      expect(
        viewport.testGetChildFor(const ChildVicinity(xIndex: 0, yIndex: 0)),
        viewport.firstChild,
      );

      // returns null
      expect(
        viewport.testGetChildFor(const ChildVicinity(xIndex: 10, yIndex: 10)),
        isNull,
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts vicinity is valid when children are asked to build', (WidgetTester tester) async {
      final Map<ChildVicinity, UniqueKey> childKeys = <ChildVicinity, UniqueKey>{};
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 5,
        maxYIndex: 5,
        builder: (BuildContext context, ChildVicinity vicinity) {
          childKeys[vicinity] = UniqueKey();
          return SizedBox.square(key: childKeys[vicinity], dimension: 200);
        }
      );

      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();

      final RenderTwoDimensionalViewport viewport = getViewport(
        tester,
        childKeys.values.first,
      );
      expect(
        () {
          viewport.buildOrObtainChildFor(ChildVicinity.invalid);
        },
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.toString(),
            'description',
            contains('ChildVicinity.invalid'),
          ),
        ),
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts that content dimensions have been applied', (WidgetTester tester) async {
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 5,
        maxYIndex: 5,
        builder: (BuildContext context, ChildVicinity vicinity) {
          return const SizedBox.square(dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        // Will cause the test implementation to not set dimensions
        applyDimensions: false,
      ));
      final FlutterError error = tester.takeException() as FlutterError;
      expect(error.message, contains('was not given content dimensions'));
    }, variant: TargetPlatformVariant.all());

    testWidgets('will not rebuild a child if it can be reused', (WidgetTester tester) async {
      final List<ChildVicinity> builtChildren = <ChildVicinity>[];
      final ScrollController controller = ScrollController();
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 5,
        maxYIndex: 5,
        builder: (BuildContext context, ChildVicinity vicinity) {
          builtChildren.add(vicinity);
          return const SizedBox.square(dimension: 200);
        }
      );

      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        verticalDetails: ScrollableDetails.vertical(controller: controller),
      ));
      expect(controller.position.pixels, 0.0);
      expect(builtChildren.length, 20);
      expect(builtChildren[0], const ChildVicinity(xIndex: 0, yIndex: 0));
      builtChildren.clear();
      controller.jumpTo(1.0); // Move slightly to trigger another layout
      await tester.pump();
      expect(controller.position.pixels, 1.0);
      expect(builtChildren.length, 5); // Next row of children was built
      // Children from the first layout pass were re-used, not rebuilt.
      expect(
        builtChildren.contains(const ChildVicinity(xIndex: 0, yIndex: 0)),
        isFalse,
      );
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the layoutOffset has been set by the subclass', (WidgetTester tester) async {
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 5,
        maxYIndex: 5,
        builder: (BuildContext context, ChildVicinity vicinity) {
          return const SizedBox.square(dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        // Will cause the test implementation to not set the layoutOffset of
        // the parent data
        setLayoutOffset: false,
      ));
      final AssertionError error = tester.takeException() as AssertionError;
      expect(error.message, contains('was not provided a layoutOffset'));
    }, variant: TargetPlatformVariant.all());

    testWidgets('asserts the children have a size after layoutChildSequence', (WidgetTester tester) async {
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 5,
        maxYIndex: 5,
        builder: (BuildContext context, ChildVicinity vicinity) {
          return const SizedBox.square(dimension: 200);
        }
      );
      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
        // Will cause the test implementation to not actually layout the
        // children it asked for.
        forgetToLayoutChild: true,
      ));
      final AssertionError error = tester.takeException() as AssertionError;
      expect(error.toString(), contains('child.hasSize'));
    }, variant: TargetPlatformVariant.all());

    testWidgets('does not support intrinsics', (WidgetTester tester) async {
      final Map<ChildVicinity, UniqueKey> childKeys = <ChildVicinity, UniqueKey>{};
      final TwoDimensionalChildBuilderDelegate delegate = TwoDimensionalChildBuilderDelegate(
        maxXIndex: 5,
        maxYIndex: 5,
        builder: (BuildContext context, ChildVicinity vicinity) {
          childKeys[vicinity] = UniqueKey();
          return SizedBox.square(key: childKeys[vicinity], dimension: 200);
        }
      );

      await tester.pumpWidget(simpleBuilderTest(
        delegate: delegate,
      ));
      await tester.pumpAndSettle();

      final RenderTwoDimensionalViewport viewport = getViewport(
        tester,
        childKeys.values.first,
      );
      expect(
        () {
          viewport.computeMinIntrinsicWidth(100);
        },
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.toString(),
            'description',
            contains('does not support returning intrinsic dimensions'),
          ),
        ),
      );
      expect(
        () {
          viewport.computeMaxIntrinsicWidth(100);
        },
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.toString(),
            'description',
            contains('does not support returning intrinsic dimensions'),
          ),
        ),
      );
      expect(
        () {
          viewport.computeMinIntrinsicHeight(100);
        },
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.toString(),
            'description',
            contains('does not support returning intrinsic dimensions'),
          ),
        ),
      );
      expect(
        () {
          viewport.computeMaxIntrinsicHeight(100);
        },
        throwsA(
          isA<AssertionError>().having(
            (AssertionError error) => error.toString(),
            'description',
            contains('does not support returning intrinsic dimensions'),
          ),
        ),
      );
    }, variant: TargetPlatformVariant.all());
  });
}

RenderTwoDimensionalViewport getViewport(WidgetTester tester, Key childKey) {
  return RenderAbstractViewport.of(
    tester.renderObject(find.byKey(childKey))
  ) as RenderSimpleBuilderTableViewport;
}

class _NullBuildContext implements BuildContext, TwoDimensionalChildManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Future<void> restoreScrollAndVerify(WidgetTester tester) async {
  final Finder findScrollable = find.byElementPredicate((Element e) => e.widget is TwoDimensionalScrollable);

  tester.state<TwoDimensionalScrollableState>(findScrollable).horizontalScrollable.position.jumpTo(100);
  tester.state<TwoDimensionalScrollableState>(findScrollable).verticalScrollable.position.jumpTo(100);
  await tester.pump();
  await tester.restartAndRestore();

  expect(
    tester.state<TwoDimensionalScrollableState>(findScrollable).horizontalScrollable.position.pixels,
    100.0,
  );
  expect(
    tester.state<TwoDimensionalScrollableState>(findScrollable).verticalScrollable.position.pixels,
    100.0,
  );

  final TestRestorationData data = await tester.getRestorationData();
  tester.state<TwoDimensionalScrollableState>(findScrollable).horizontalScrollable.position.jumpTo(0);
  tester.state<TwoDimensionalScrollableState>(findScrollable).verticalScrollable.position.jumpTo(0);
  await tester.pump();
  await tester.restoreFrom(data);

  expect(
    tester.state<TwoDimensionalScrollableState>(findScrollable).horizontalScrollable.position.pixels,
    100.0,
  );
  expect(
    tester.state<TwoDimensionalScrollableState>(findScrollable).verticalScrollable.position.pixels,
    100.0,
  );
}
