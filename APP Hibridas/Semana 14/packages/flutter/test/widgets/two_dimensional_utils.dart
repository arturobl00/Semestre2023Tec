// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ViewportOffset;


// BUILDER DELEGATE ---

final TwoDimensionalChildBuilderDelegate builderDelegate = TwoDimensionalChildBuilderDelegate(
  maxXIndex: 5,
  maxYIndex: 5,
  builder: (BuildContext context, ChildVicinity vicinity) {
    return Container(
      color: vicinity.xIndex.isEven && vicinity.yIndex.isEven
        ? Colors.amber[100]
        : (vicinity.xIndex.isOdd && vicinity.yIndex.isOdd
        ? Colors.blueAccent[100]
        : null),
      height: 200,
      width: 200,
      child: Center(child: Text('R${vicinity.xIndex}:C${vicinity.yIndex}')),
    );
  }
);

// Creates a simple 2D table of 200x200 squares with a builder delegate.
Widget simpleBuilderTest({
  Axis mainAxis = Axis.vertical,
  bool? primary,
  ScrollableDetails? verticalDetails,
  ScrollableDetails? horizontalDetails,
  TwoDimensionalChildBuilderDelegate? delegate,
  double? cacheExtent,
  DiagonalDragBehavior? diagonalDrag,
  Clip? clipBehavior,
  String? restorationID,
  bool useCacheExtent = false,
  bool applyDimensions = true,
  bool forgetToLayoutChild = false,
  bool setLayoutOffset = true,
}) {
  return MaterialApp(
    restorationScopeId: restorationID,
    home: Scaffold(
      body: SimpleBuilderTableView(
        mainAxis: mainAxis,
        verticalDetails: verticalDetails ?? const ScrollableDetails.vertical(),
        horizontalDetails: horizontalDetails ?? const ScrollableDetails.horizontal(),
        cacheExtent: cacheExtent,
        useCacheExtent: useCacheExtent,
        diagonalDragBehavior: diagonalDrag ?? DiagonalDragBehavior.none,
        clipBehavior: clipBehavior ?? Clip.hardEdge,
        delegate: delegate ?? builderDelegate,
        applyDimensions: applyDimensions,
        forgetToLayoutChild: forgetToLayoutChild,
        setLayoutOffset: setLayoutOffset,
      ),
    ),
  );
}

class SimpleBuilderTableView extends TwoDimensionalScrollView {
  const SimpleBuilderTableView({
    super.key,
    super.primary,
    super.mainAxis = Axis.vertical,
    super.verticalDetails = const ScrollableDetails.vertical(),
    super.horizontalDetails = const ScrollableDetails.horizontal(),
    required TwoDimensionalChildBuilderDelegate delegate,
    super.cacheExtent,
    super.diagonalDragBehavior = DiagonalDragBehavior.none,
    super.dragStartBehavior = DragStartBehavior.start,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.clipBehavior = Clip.hardEdge,
    this.useCacheExtent = false,
    this.applyDimensions = true,
    this.forgetToLayoutChild = false,
    this.setLayoutOffset = true,
  }) : super(delegate: delegate);

  // Piped through for testing in RenderTwoDimensionalViewport
  final bool useCacheExtent;
  final bool applyDimensions;
  final bool forgetToLayoutChild;
  final bool setLayoutOffset;

  @override
  Widget buildViewport(BuildContext context, ViewportOffset verticalOffset, ViewportOffset horizontalOffset) {
    return SimpleBuilderTableViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
      useCacheExtent: useCacheExtent,
      applyDimensions: applyDimensions,
      forgetToLayoutChild: forgetToLayoutChild,
      setLayoutOffset: setLayoutOffset,
    );
  }
}

class SimpleBuilderTableViewport extends TwoDimensionalViewport {
  const SimpleBuilderTableViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required TwoDimensionalChildBuilderDelegate delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
    this.useCacheExtent = false,
    this.applyDimensions = true,
    this.forgetToLayoutChild = false,
    this.setLayoutOffset = true,
  }) : super(delegate: delegate);

  // Piped through for testing in RenderTwoDimensionalViewport
  final bool useCacheExtent;
  final bool applyDimensions;
  final bool forgetToLayoutChild;
  final bool setLayoutOffset;

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return RenderSimpleBuilderTableViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildBuilderDelegate,
      childManager: context as TwoDimensionalChildManager,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
      useCacheExtent: useCacheExtent,
      applyDimensions: applyDimensions,
      forgetToLayoutChild: forgetToLayoutChild,
      setLayoutOffset: setLayoutOffset,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSimpleBuilderTableViewport renderObject) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..mainAxis = mainAxis
      ..delegate = delegate
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}

class RenderSimpleBuilderTableViewport extends RenderTwoDimensionalViewport {
  RenderSimpleBuilderTableViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildBuilderDelegate delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
    this.applyDimensions = true,
    this.setLayoutOffset = true,
    this.useCacheExtent = false,
    this.forgetToLayoutChild = false,
  }) : super(delegate: delegate);

  // These are to test conditions to validate subclass implementations after
  // layoutChildSequence
  final bool applyDimensions;
  final bool setLayoutOffset;
  final bool useCacheExtent;
  final bool forgetToLayoutChild;

  RenderBox? testGetChildFor(ChildVicinity vicinity) => getChildFor(vicinity);

  @override
  void layoutChildSequence() {
    // Really simple table implementation for testing.
    // Every child is 200x200 square
    final double horizontalPixels = horizontalOffset.pixels;
    final double verticalPixels = verticalOffset.pixels;
    final double viewportWidth = viewportDimension.width + (useCacheExtent ? cacheExtent : 0.0);
    final double viewportHeight = viewportDimension.height + (useCacheExtent ? cacheExtent : 0.0);
    final TwoDimensionalChildBuilderDelegate builderDelegate = delegate as TwoDimensionalChildBuilderDelegate;

    final int maxRowIndex;
    final int maxColumnIndex;
    maxRowIndex = builderDelegate.maxYIndex ?? 5;
    maxColumnIndex = builderDelegate.maxXIndex ?? 5;

    final int leadingColumn = math.max((horizontalPixels / 200).floor(), 0);
    final int leadingRow = math.max((verticalPixels / 200).floor(), 0);
    final int trailingColumn = math.min(
      ((horizontalPixels + viewportWidth) / 200).ceil(),
      maxColumnIndex,
    );
    final int trailingRow = math.min(
      ((verticalPixels + viewportHeight) / 200).ceil(),
      maxRowIndex,
    );

    double xLayoutOffset = (leadingColumn * 200) - horizontalOffset.pixels;
    for (int column = leadingColumn; column <= trailingColumn; column++) {
      double yLayoutOffset = (leadingRow * 200) - verticalOffset.pixels;
      for (int row = leadingRow; row <= trailingRow; row++) {
        final ChildVicinity vicinity = ChildVicinity(xIndex: column, yIndex: row);
        final RenderBox child = buildOrObtainChildFor(vicinity)!;
        if (!forgetToLayoutChild) {
          child.layout(constraints.tighten(width: 200.0, height: 200.0));
        }

        if (setLayoutOffset) {
          parentDataOf(child).layoutOffset = Offset(xLayoutOffset, yLayoutOffset);
        }
        yLayoutOffset += 200;
      }
      xLayoutOffset += 200;
    }
    if (applyDimensions) {
      final double verticalExtent = 200 * (maxRowIndex + 1);
      verticalOffset.applyContentDimensions(
        0.0,
        clampDouble(verticalExtent - viewportDimension.height, 0.0, double.infinity),
      );
      final double horizontalExtent = 200 * (maxColumnIndex + 1);
      horizontalOffset.applyContentDimensions(
        0.0,
        clampDouble(horizontalExtent - viewportDimension.width, 0.0, double.infinity),
      );
    }
  }
}

// LIST DELEGATE ---
final List<List<Widget>> children = List<List<Widget>>.generate(
  100,
  (int xIndex) {
    return List<Widget>.generate(
      100,
      (int yIndex) {
        return Container(
          color: xIndex.isEven && yIndex.isEven
            ? Colors.amber[100]
            : (xIndex.isOdd && yIndex.isOdd
              ? Colors.blueAccent[100]
              : null),
          height: 200,
          width: 200,
          child: Center(child: Text('R$xIndex:C$yIndex')),
        );
      },
    );
  },
);

// Builds a simple 2D table of 200x200 squares with a list delegate.
Widget simpleListTest({
  Axis mainAxis = Axis.vertical,
  bool? primary,
  ScrollableDetails? verticalDetails,
  ScrollableDetails? horizontalDetails,
  TwoDimensionalChildListDelegate? delegate,
  double? cacheExtent,
  DiagonalDragBehavior? diagonalDrag,
  Clip? clipBehavior,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SimpleListTableView(
        mainAxis: mainAxis,
        verticalDetails: verticalDetails ?? const ScrollableDetails.vertical(),
        horizontalDetails: horizontalDetails ?? const ScrollableDetails.horizontal(),
        cacheExtent: cacheExtent,
        diagonalDragBehavior: diagonalDrag ?? DiagonalDragBehavior.none,
        clipBehavior: clipBehavior ?? Clip.hardEdge,
        delegate: delegate ?? TwoDimensionalChildListDelegate(children: children),
      ),
    ),
  );
}

class SimpleListTableView extends TwoDimensionalScrollView {
  const SimpleListTableView({
    super.key,
    super.primary,
    super.mainAxis = Axis.vertical,
    super.verticalDetails = const ScrollableDetails.vertical(),
    super.horizontalDetails = const ScrollableDetails.horizontal(),
    required TwoDimensionalChildListDelegate delegate,
    super.cacheExtent,
    super.diagonalDragBehavior = DiagonalDragBehavior.none,
    super.dragStartBehavior = DragStartBehavior.start,
    super.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    super.clipBehavior = Clip.hardEdge,
  }) : super(delegate: delegate);

  @override
  Widget buildViewport(BuildContext context, ViewportOffset verticalOffset, ViewportOffset horizontalOffset) {
    return SimpleListTableViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalDetails.direction,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalDetails.direction,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildListDelegate,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }
}

class SimpleListTableViewport extends TwoDimensionalViewport {
  const SimpleListTableViewport({
    super.key,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required TwoDimensionalChildListDelegate delegate,
    required super.mainAxis,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  }) : super(delegate: delegate);

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) {
    return RenderSimpleListTableViewport(
      horizontalOffset: horizontalOffset,
      horizontalAxisDirection: horizontalAxisDirection,
      verticalOffset: verticalOffset,
      verticalAxisDirection: verticalAxisDirection,
      mainAxis: mainAxis,
      delegate: delegate as TwoDimensionalChildListDelegate,
      childManager: context as TwoDimensionalChildManager,
      cacheExtent: cacheExtent,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSimpleListTableViewport renderObject) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..mainAxis = mainAxis
      ..delegate = delegate
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior;
  }
}

class RenderSimpleListTableViewport extends RenderTwoDimensionalViewport {
  RenderSimpleListTableViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildListDelegate delegate,
    required super.mainAxis,
    required super.childManager,
    super.cacheExtent,
    super.clipBehavior = Clip.hardEdge,
  }) : super(delegate: delegate);

  @override
  void layoutChildSequence() {
    // Really simple table implementation for testing.
    // Every child is 200x200 square
    final double horizontalPixels = horizontalOffset.pixels;
    final double verticalPixels = verticalOffset.pixels;
    final TwoDimensionalChildListDelegate listDelegate = delegate as TwoDimensionalChildListDelegate;
    final int rowCount;
    final int columnCount;
    rowCount = listDelegate.children.length - 1;
    columnCount = listDelegate.children[0].length - 1;

    final int leadingColumn = math.max((horizontalPixels / 200).floor(), 0);
    final int leadingRow = math.max((verticalPixels / 200).floor(), 0);
    final int trailingColumn = math.min(
      ((horizontalPixels + viewportDimension.width) / 200).ceil(),
      columnCount,
    );
    final int trailingRow = math.min(
      ((verticalPixels + viewportDimension.height) / 200).ceil(),
      rowCount,
    );

    double xLayoutOffset = (leadingColumn * 200) - horizontalOffset.pixels;
    for (int column = leadingColumn; column <= trailingColumn; column++) {
      double yLayoutOffset = (leadingRow * 200) - verticalOffset.pixels;
      for (int row = leadingRow; row <= trailingRow; row++) {
        final ChildVicinity vicinity = ChildVicinity(xIndex: column, yIndex: row);
        final RenderBox child = buildOrObtainChildFor(vicinity)!;
        child.layout(constraints.tighten(width: 200.0, height: 200.0));

        parentDataOf(child).layoutOffset = Offset(xLayoutOffset, yLayoutOffset);
        yLayoutOffset += 200;
      }
      xLayoutOffset += 200;
    }
    verticalOffset.applyContentDimensions(0, 200 * 100 - viewportDimension.height);
    horizontalOffset.applyContentDimensions(0, 200 * 100 - viewportDimension.width);
  }
}
