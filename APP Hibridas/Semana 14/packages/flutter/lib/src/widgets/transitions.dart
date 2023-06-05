// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'container.dart';
import 'framework.dart';
import 'text.dart';

export 'package:flutter/rendering.dart' show RelativeRect;

/// A widget that rebuilds when the given [Listenable] changes value.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=LKKgYpC-EPQ}
///
/// [AnimatedWidget] is most commonly used with [Animation] objects, which are
/// [Listenable], but it can be used with any [Listenable], including
/// [ChangeNotifier] and [ValueNotifier].
///
/// [AnimatedWidget] is most useful for widgets that are otherwise stateless. To
/// use [AnimatedWidget], subclass it and implement the build function.
///
/// {@tool dartpad}
/// This code defines a widget called `Spinner` that spins a green square
/// continually. It is built with an [AnimatedWidget].
///
/// ** See code in examples/api/lib/widgets/transitions/animated_widget.0.dart **
/// {@end-tool}
///
/// For more complex case involving additional state, consider using
/// [AnimatedBuilder] or [ListenableBuilder].
///
/// ## Relationship to [ImplicitlyAnimatedWidget]s
///
/// [AnimatedWidget]s (and their subclasses) take an explicit [Listenable] as
/// argument, which is usually an [Animation] derived from an
/// [AnimationController]. In most cases, the lifecycle of that
/// [AnimationController] has to be managed manually by the developer.
/// In contrast to that, [ImplicitlyAnimatedWidget]s (and their subclasses)
/// automatically manage their own internal [AnimationController] making those
/// classes easier to use as no external [Animation] has to be provided by the
/// developer. If you only need to set a target value for the animation and
/// configure its duration/curve, consider using (a subclass of)
/// [ImplicitlyAnimatedWidget]s instead of (a subclass of) this class.
///
/// ## Common animated widgets
///
/// A number of animated widgets ship with the framework. They are usually named
/// `FooTransition`, where `Foo` is the name of the non-animated
/// version of that widget. The subclasses of this class should not be confused
/// with subclasses of [ImplicitlyAnimatedWidget] (see above), which are usually
/// named `AnimatedFoo`. Commonly used animated widgets include:
///
///  * [ListenableBuilder], which uses a builder pattern that is useful for
///    complex [Listenable] use cases.
///  * [AnimatedBuilder], which uses a builder pattern that is useful for
///    complex [Animation] use cases.
///  * [AlignTransition], which is an animated version of [Align].
///  * [DecoratedBoxTransition], which is an animated version of [DecoratedBox].
///  * [DefaultTextStyleTransition], which is an animated version of
///    [DefaultTextStyle].
///  * [PositionedTransition], which is an animated version of [Positioned].
///  * [RelativePositionedTransition], which is an animated version of
///    [Positioned].
///  * [RotationTransition], which animates the rotation of a widget.
///  * [ScaleTransition], which animates the scale of a widget.
///  * [SizeTransition], which animates its own size.
///  * [SlideTransition], which animates the position of a widget relative to
///    its normal position.
///  * [FadeTransition], which is an animated version of [Opacity].
///  * [AnimatedModalBarrier], which is an animated version of [ModalBarrier].
abstract class AnimatedWidget extends StatefulWidget {
  /// Creates a widget that rebuilds when the given listenable changes.
  ///
  /// The [listenable] argument is required.
  const AnimatedWidget({
    super.key,
    required this.listenable,
  });

  /// The [Listenable] to which this widget is listening.
  ///
  /// Commonly an [Animation] or a [ChangeNotifier].
  final Listenable listenable;

  /// Override this method to build widgets that depend on the state of the
  /// listenable (e.g., the current value of the animation).
  @protected
  Widget build(BuildContext context);

  /// Subclasses typically do not override this method.
  @override
  State<AnimatedWidget> createState() => _AnimatedState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Listenable>('listenable', listenable));
  }
}

class _AnimatedState extends State<AnimatedWidget> {
  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(_handleChange);
  }

  @override
  void didUpdateWidget(AnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listenable != oldWidget.listenable) {
      oldWidget.listenable.removeListener(_handleChange);
      widget.listenable.addListener(_handleChange);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_handleChange);
    super.dispose();
  }

  void _handleChange() {
    setState(() {
      // The listenable's state is our build state, and it changed already.
    });
  }

  @override
  Widget build(BuildContext context) => widget.build(context);
}

/// Animates the position of a widget relative to its normal position.
///
/// The translation is expressed as an [Offset] scaled to the child's size. For
/// example, an [Offset] with a `dx` of 0.25 will result in a horizontal
/// translation of one quarter the width of the child.
///
/// By default, the offsets are applied in the coordinate system of the canvas
/// (so positive x offsets move the child towards the right). If a
/// [textDirection] is provided, then the offsets are applied in the reading
/// direction, so in right-to-left text, positive x offsets move towards the
/// left, and in left-to-right text, positive x offsets move towards the right.
///
/// Here's an illustration of the [SlideTransition] widget, with its [position]
/// animated by a [CurvedAnimation] set to [Curves.elasticIn]:
/// {@animation 300 378 https://flutter.github.io/assets-for-api-docs/assets/widgets/slide_transition.mp4}
///
/// {@tool dartpad}
/// The following code implements the [SlideTransition] as seen in the video
/// above:
///
/// ** See code in examples/api/lib/widgets/transitions/slide_transition.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [AlignTransition], an animated version of an [Align] that animates its
///    [Align.alignment] property.
///  * [PositionedTransition], a widget that animates its child from a start
///    position to an end position over the lifetime of the animation.
///  * [RelativePositionedTransition], a widget that transitions its child's
///    position based on the value of a rectangle relative to a bounding box.
class SlideTransition extends AnimatedWidget {
  /// Creates a fractional translation transition.
  ///
  /// The [position] argument must not be null.
  const SlideTransition({
    super.key,
    required Animation<Offset> position,
    this.transformHitTests = true,
    this.textDirection,
    this.child,
  }) : super(listenable: position);

  /// The animation that controls the position of the child.
  ///
  /// If the current value of the position animation is `(dx, dy)`, the child
  /// will be translated horizontally by `width * dx` and vertically by
  /// `height * dy`, after applying the [textDirection] if available.
  Animation<Offset> get position => listenable as Animation<Offset>;

  /// The direction to use for the x offset described by the [position].
  ///
  /// If [textDirection] is null, the x offset is applied in the coordinate
  /// system of the canvas (so positive x offsets move the child towards the
  /// right).
  ///
  /// If [textDirection] is [TextDirection.rtl], the x offset is applied in the
  /// reading direction such that x offsets move the child towards the left.
  ///
  /// If [textDirection] is [TextDirection.ltr], the x offset is applied in the
  /// reading direction such that x offsets move the child towards the right.
  final TextDirection? textDirection;

  /// Whether hit testing should be affected by the slide animation.
  ///
  /// If false, hit testing will proceed as if the child was not translated at
  /// all. Setting this value to false is useful for fast animations where you
  /// expect the user to commonly interact with the child widget in its final
  /// location and you want the user to benefit from "muscle memory".
  final bool transformHitTests;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    Offset offset = position.value;
    if (textDirection == TextDirection.rtl) {
      offset = Offset(-offset.dx, offset.dy);
    }
    return FractionalTranslation(
      translation: offset,
      transformHitTests: transformHitTests,
      child: child,
    );
  }
}

/// Animates the scale of a transformed widget.
///
/// Here's an illustration of the [ScaleTransition] widget, with it's [alignment]
/// animated by a [CurvedAnimation] set to [Curves.fastOutSlowIn]:
/// {@animation 300 378 https://flutter.github.io/assets-for-api-docs/assets/widgets/scale_transition.mp4}
///
/// {@tool dartpad}
/// The following code implements the [ScaleTransition] as seen in the video
/// above:
///
/// ** See code in examples/api/lib/widgets/transitions/scale_transition.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [PositionedTransition], a widget that animates its child from a start
///    position to an end position over the lifetime of the animation.
///  * [RelativePositionedTransition], a widget that transitions its child's
///    position based on the value of a rectangle relative to a bounding box.
///  * [SizeTransition], a widget that animates its own size and clips and
///    aligns its child.
class ScaleTransition extends AnimatedWidget {
  /// Creates a scale transition.
  ///
  /// The [scale] argument must not be null. The [alignment] argument defaults
  /// to [Alignment.center].
  const ScaleTransition({
    super.key,
    required Animation<double> scale,
    this.alignment = Alignment.center,
    this.filterQuality,
    this.child,
  }) : super(listenable: scale);

  /// The animation that controls the scale of the child.
  ///
  /// If the current value of the scale animation is v, the child will be
  /// painted v times its normal size.
  Animation<double> get scale => listenable as Animation<double>;

  /// The alignment of the origin of the coordinate system in which the scale
  /// takes place, relative to the size of the box.
  ///
  /// For example, to set the origin of the scale to bottom middle, you can use
  /// an alignment of (0.0, 1.0).
  final Alignment alignment;

  /// The filter quality with which to apply the transform as a bitmap operation.
  ///
  /// When the animation is stopped (either in [AnimationStatus.dismissed] or
  /// [AnimationStatus.completed]), the filter quality argument will be ignored.
  ///
  /// {@macro flutter.widgets.Transform.optional.FilterQuality}
  final FilterQuality? filterQuality;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // The ImageFilter layer created by setting filterQuality will introduce
    // a saveLayer call. This is usually worthwhile when animating the layer,
    // but leaving it in the layer tree before the animation has started or after
    // it has finished significantly hurts performance.
    final bool useFilterQuality;
    switch (scale.status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        useFilterQuality = false;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        useFilterQuality = true;
    }
    return Transform.scale(
      scale: scale.value,
      alignment: alignment,
      filterQuality: useFilterQuality ? filterQuality : null,
      child: child,
    );
  }
}

/// Animates the rotation of a widget.
///
/// Here's an illustration of the [RotationTransition] widget, with it's [turns]
/// animated by a [CurvedAnimation] set to [Curves.elasticOut]:
/// {@animation 300 378 https://flutter.github.io/assets-for-api-docs/assets/widgets/rotation_transition.mp4}
///
/// {@tool dartpad}
/// The following code implements the [RotationTransition] as seen in the video
/// above:
///
/// ** See code in examples/api/lib/widgets/transitions/rotation_transition.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [ScaleTransition], a widget that animates the scale of a transformed
///    widget.
///  * [SizeTransition], a widget that animates its own size and clips and
///    aligns its child.
class RotationTransition extends AnimatedWidget {
  /// Creates a rotation transition.
  ///
  /// The [turns] argument must not be null.
  const RotationTransition({
    super.key,
    required Animation<double> turns,
    this.alignment = Alignment.center,
    this.filterQuality,
    this.child,
  }) : super(listenable: turns);

  /// The animation that controls the rotation of the child.
  ///
  /// If the current value of the turns animation is v, the child will be
  /// rotated v * 2 * pi radians before being painted.
  Animation<double> get turns => listenable as Animation<double>;

  /// The alignment of the origin of the coordinate system around which the
  /// rotation occurs, relative to the size of the box.
  ///
  /// For example, to set the origin of the rotation to top right corner, use
  /// an alignment of (1.0, -1.0) or use [Alignment.topRight]
  final Alignment alignment;

  /// The filter quality with which to apply the transform as a bitmap operation.
  ///
  /// When the animation is stopped (either in [AnimationStatus.dismissed] or
  /// [AnimationStatus.completed]), the filter quality argument will be ignored.
  ///
  /// {@macro flutter.widgets.Transform.optional.FilterQuality}
  final FilterQuality? filterQuality;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    // The ImageFilter layer created by setting filterQuality will introduce
    // a saveLayer call. This is usually worthwhile when animating the layer,
    // but leaving it in the layer tree before the animation has started or after
    // it has finished significantly hurts performance.
    final bool useFilterQuality;
    switch (turns.status) {
      case AnimationStatus.dismissed:
      case AnimationStatus.completed:
        useFilterQuality = false;
      case AnimationStatus.forward:
      case AnimationStatus.reverse:
        useFilterQuality = true;
    }
    return Transform.rotate(
      angle: turns.value * math.pi * 2.0,
      alignment: alignment,
      filterQuality: useFilterQuality ? filterQuality : null,
      child: child,
    );
  }
}

/// Animates its own size and clips and aligns its child.
///
/// [SizeTransition] acts as a [ClipRect] that animates either its width or its
/// height, depending upon the value of [axis]. The alignment of the child along
/// the [axis] is specified by the [axisAlignment].
///
/// Like most widgets, [SizeTransition] will conform to the constraints it is
/// given, so be sure to put it in a context where it can change size. For
/// instance, if you place it into a [Container] with a fixed size, then the
/// [SizeTransition] will not be able to change size, and will appear to do
/// nothing.
///
/// Here's an illustration of the [SizeTransition] widget, with it's [sizeFactor]
/// animated by a [CurvedAnimation] set to [Curves.fastOutSlowIn]:
/// {@animation 300 378 https://flutter.github.io/assets-for-api-docs/assets/widgets/size_transition.mp4}
///
/// {@tool dartpad}
/// This code defines a widget that uses [SizeTransition] to change the size
/// of [FlutterLogo] continually. It is built with a [Scaffold]
/// where the internal widget has space to change its size.
///
/// ** See code in examples/api/lib/widgets/transitions/size_transition.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [AnimatedCrossFade], for a widget that automatically animates between
///    the sizes of two children, fading between them.
///  * [ScaleTransition], a widget that scales the size of the child instead of
///    clipping it.
///  * [PositionedTransition], a widget that animates its child from a start
///    position to an end position over the lifetime of the animation.
///  * [RelativePositionedTransition], a widget that transitions its child's
///    position based on the value of a rectangle relative to a bounding box.
class SizeTransition extends AnimatedWidget {
  /// Creates a size transition.
  ///
  /// The [axis], [sizeFactor], and [axisAlignment] arguments must not be null.
  /// The [axis] argument defaults to [Axis.vertical]. The [axisAlignment]
  /// defaults to 0.0, which centers the child along the main axis during the
  /// transition.
  const SizeTransition({
    super.key,
    this.axis = Axis.vertical,
    required Animation<double> sizeFactor,
    this.axisAlignment = 0.0,
    this.child,
  }) : super(listenable: sizeFactor);

  /// [Axis.horizontal] if [sizeFactor] modifies the width, otherwise
  /// [Axis.vertical].
  final Axis axis;

  /// The animation that controls the (clipped) size of the child.
  ///
  /// The width or height (depending on the [axis] value) of this widget will be
  /// its intrinsic width or height multiplied by [sizeFactor]'s value at the
  /// current point in the animation.
  ///
  /// If the value of [sizeFactor] is less than one, the child will be clipped
  /// in the appropriate axis.
  Animation<double> get sizeFactor => listenable as Animation<double>;

  /// Describes how to align the child along the axis that [sizeFactor] is
  /// modifying.
  ///
  /// A value of -1.0 indicates the top when [axis] is [Axis.vertical], and the
  /// start when [axis] is [Axis.horizontal]. The start is on the left when the
  /// text direction in effect is [TextDirection.ltr] and on the right when it
  /// is [TextDirection.rtl].
  ///
  /// A value of 1.0 indicates the bottom or end, depending upon the [axis].
  ///
  /// A value of 0.0 (the default) indicates the center for either [axis] value.
  final double axisAlignment;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final AlignmentDirectional alignment;
    if (axis == Axis.vertical) {
      alignment = AlignmentDirectional(-1.0, axisAlignment);
    } else {
      alignment = AlignmentDirectional(axisAlignment, -1.0);
    }
    return ClipRect(
      child: Align(
        alignment: alignment,
        heightFactor: axis == Axis.vertical ? math.max(sizeFactor.value, 0.0) : null,
        widthFactor: axis == Axis.horizontal ? math.max(sizeFactor.value, 0.0) : null,
        child: child,
      ),
    );
  }
}

/// Animates the opacity of a widget.
///
/// For a widget that automatically animates between the sizes of two children,
/// fading between them, see [AnimatedCrossFade].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=rLwWVbv3xDQ}
///
/// Here's an illustration of the [FadeTransition] widget, with it's [opacity]
/// animated by a [CurvedAnimation] set to [Curves.fastOutSlowIn]:
///
/// {@tool dartpad}
/// The following code implements the [FadeTransition] using
/// the Flutter logo:
///
/// ** See code in examples/api/lib/widgets/transitions/fade_transition.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [Opacity], which does not animate changes in opacity.
///  * [AnimatedOpacity], which animates changes in opacity without taking an
///    explicit [Animation] argument.
///  * [SliverFadeTransition], the sliver version of this widget.
class FadeTransition extends SingleChildRenderObjectWidget {
  /// Creates an opacity transition.
  ///
  /// The [opacity] argument must not be null.
  const FadeTransition({
    super.key,
    required this.opacity,
    this.alwaysIncludeSemantics = false,
    super.child,
  });

  /// The animation that controls the opacity of the child.
  ///
  /// If the current value of the opacity animation is v, the child will be
  /// painted with an opacity of v. For example, if v is 0.5, the child will be
  /// blended 50% with its background. Similarly, if v is 0.0, the child will be
  /// completely transparent.
  final Animation<double> opacity;

  /// Whether the semantic information of the children is always included.
  ///
  /// Defaults to false.
  ///
  /// When true, regardless of the opacity settings the child semantic
  /// information is exposed as if the widget were fully visible. This is
  /// useful in cases where labels may be hidden during animations that
  /// would otherwise contribute relevant semantics.
  final bool alwaysIncludeSemantics;

  @override
  RenderAnimatedOpacity createRenderObject(BuildContext context) {
    return RenderAnimatedOpacity(
      opacity: opacity,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderAnimatedOpacity renderObject) {
    renderObject
      ..opacity = opacity
      ..alwaysIncludeSemantics = alwaysIncludeSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Animation<double>>('opacity', opacity));
    properties.add(FlagProperty('alwaysIncludeSemantics', value: alwaysIncludeSemantics, ifTrue: 'alwaysIncludeSemantics'));
  }
}

/// Animates the opacity of a sliver widget.
///
/// {@tool dartpad}
/// Creates a [CustomScrollView] with a [SliverFixedExtentList] that uses a
/// [SliverFadeTransition] to fade the list in and out.
///
/// ** See code in examples/api/lib/widgets/transitions/sliver_fade_transition.0.dart **
/// {@end-tool}
///
/// Here's an illustration of the [FadeTransition] widget, the [RenderBox]
/// equivalent widget, with it's [opacity] animated by a [CurvedAnimation] set
/// to [Curves.fastOutSlowIn]:
///
/// {@animation 300 378 https://flutter.github.io/assets-for-api-docs/assets/widgets/fade_transition.mp4}
///
/// See also:
///
///  * [SliverOpacity], which does not animate changes in opacity.
///  * [FadeTransition], the box version of this widget.
class SliverFadeTransition extends SingleChildRenderObjectWidget {
  /// Creates an opacity transition.
  ///
  /// The [opacity] argument must not be null.
  const SliverFadeTransition({
    super.key,
    required this.opacity,
    this.alwaysIncludeSemantics = false,
    Widget? sliver,
  }) : super(child: sliver);

  /// The animation that controls the opacity of the sliver child.
  ///
  /// If the current value of the opacity animation is v, the child will be
  /// painted with an opacity of v. For example, if v is 0.5, the child will be
  /// blended 50% with its background. Similarly, if v is 0.0, the child will be
  /// completely transparent.
  final Animation<double> opacity;

  /// Whether the semantic information of the sliver child is always included.
  ///
  /// Defaults to false.
  ///
  /// When true, regardless of the opacity settings the sliver child's semantic
  /// information is exposed as if the widget were fully visible. This is
  /// useful in cases where labels may be hidden during animations that
  /// would otherwise contribute relevant semantics.
  final bool alwaysIncludeSemantics;

  @override
  RenderSliverAnimatedOpacity createRenderObject(BuildContext context) {
    return RenderSliverAnimatedOpacity(
      opacity: opacity,
      alwaysIncludeSemantics: alwaysIncludeSemantics,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderSliverAnimatedOpacity renderObject) {
    renderObject
      ..opacity = opacity
      ..alwaysIncludeSemantics = alwaysIncludeSemantics;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Animation<double>>('opacity', opacity));
    properties.add(FlagProperty('alwaysIncludeSemantics', value: alwaysIncludeSemantics, ifTrue: 'alwaysIncludeSemantics'));
  }
}

/// An interpolation between two relative rects.
///
/// This class specializes the interpolation of [Tween<RelativeRect>] to
/// use [RelativeRect.lerp].
///
/// See [Tween] for a discussion on how to use interpolation objects.
class RelativeRectTween extends Tween<RelativeRect> {
  /// Creates a [RelativeRect] tween.
  ///
  /// The [begin] and [end] properties may be null; the null value
  /// is treated as [RelativeRect.fill].
  RelativeRectTween({ super.begin, super.end });

  /// Returns the value this variable has at the given animation clock value.
  @override
  RelativeRect lerp(double t) => RelativeRect.lerp(begin, end, t)!;
}

/// Animated version of [Positioned] which takes a specific
/// [Animation<RelativeRect>] to transition the child's position from a start
/// position to an end position over the lifetime of the animation.
///
/// Only works if it's the child of a [Stack].
///
/// Here's an illustration of the [PositionedTransition] widget, with it's [rect]
/// animated by a [CurvedAnimation] set to [Curves.elasticInOut]:
/// {@animation 300 378 https://flutter.github.io/assets-for-api-docs/assets/widgets/positioned_transition.mp4}
///
/// {@tool dartpad}
/// The following code implements the [PositionedTransition] as seen in the video
/// above:
///
/// ** See code in examples/api/lib/widgets/transitions/positioned_transition.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [AnimatedPositioned], which transitions a child's position without
///    taking an explicit [Animation] argument.
///  * [RelativePositionedTransition], a widget that transitions its child's
///    position based on the value of a rectangle relative to a bounding box.
///  * [SlideTransition], a widget that animates the position of a widget
///    relative to its normal position.
///  * [AlignTransition], an animated version of an [Align] that animates its
///    [Align.alignment] property.
///  * [ScaleTransition], a widget that animates the scale of a transformed
///    widget.
///  * [SizeTransition], a widget that animates its own size and clips and
///    aligns its child.
class PositionedTransition extends AnimatedWidget {
  /// Creates a transition for [Positioned].
  ///
  /// The [rect] argument must not be null.
  const PositionedTransition({
    super.key,
    required Animation<RelativeRect> rect,
    required this.child,
  }) : super(listenable: rect);

  /// The animation that controls the child's size and position.
  Animation<RelativeRect> get rect => listenable as Animation<RelativeRect>;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fromRelativeRect(
      rect: rect.value,
      child: child,
    );
  }
}

/// Animated version of [Positioned] which transitions the child's position
/// based on the value of [rect] relative to a bounding box with the
/// specified [size].
///
/// Only works if it's the child of a [Stack].
///
/// Here's an illustration of the [RelativePositionedTransition] widget, with it's [rect]
/// animated by a [CurvedAnimation] set to [Curves.elasticInOut]:
/// {@animation 300 378 https://flutter.github.io/assets-for-api-docs/assets/widgets/relative_positioned_transition.mp4}
///
/// {@tool dartpad}
/// The following code implements the [RelativePositionedTransition] as seen in the video
/// above:
///
/// ** See code in examples/api/lib/widgets/transitions/relative_positioned_transition.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [PositionedTransition], a widget that animates its child from a start
///    position to an end position over the lifetime of the animation.
///  * [AlignTransition], an animated version of an [Align] that animates its
///    [Align.alignment] property.
///  * [ScaleTransition], a widget that animates the scale of a transformed
///    widget.
///  * [SizeTransition], a widget that animates its own size and clips and
///    aligns its child.
///  * [SlideTransition], a widget that animates the position of a widget
///    relative to its normal position.
class RelativePositionedTransition extends AnimatedWidget {
  /// Create an animated version of [Positioned].
  ///
  /// Each frame, the [Positioned] widget will be configured to represent the
  /// current value of the [rect] argument assuming that the stack has the given
  /// [size]. Both [rect] and [size] must not be null.
  const RelativePositionedTransition({
    super.key,
    required Animation<Rect?> rect,
    required this.size,
    required this.child,
  }) : super(listenable: rect);

  /// The animation that controls the child's size and position.
  ///
  /// If the animation returns a null [Rect], the rect is assumed to be [Rect.zero].
  ///
  /// See also:
  ///
  ///  * [size], which gets the size of the box that the [Positioned] widget's
  ///    offsets are relative to.
  Animation<Rect?> get rect => listenable as Animation<Rect?>;

  /// The [Positioned] widget's offsets are relative to a box of this
  /// size whose origin is 0,0.
  final Size size;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final RelativeRect offsets = RelativeRect.fromSize(rect.value ?? Rect.zero, size);
    return Positioned(
      top: offsets.top,
      right: offsets.right,
      bottom: offsets.bottom,
      left: offsets.left,
      child: child,
    );
  }
}

/// Animated version of a [DecoratedBox] that animates the different properties
/// of its [Decoration].
///
/// Here's an illustration of the [DecoratedBoxTransition] widget, with it's
/// [decoration] animated by a [CurvedAnimation] set to [Curves.decelerate]:
/// {@animation 300 378 https://flutter.github.io/assets-for-api-docs/assets/widgets/decorated_box_transition.mp4}
///
/// {@tool dartpad}
/// The following code implements the [DecoratedBoxTransition] as seen in the video
/// above:
///
/// ** See code in examples/api/lib/widgets/transitions/decorated_box_transition.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [DecoratedBox], which also draws a [Decoration] but is not animated.
///  * [AnimatedContainer], a more full-featured container that also animates on
///    decoration using an internal animation.
class DecoratedBoxTransition extends AnimatedWidget {
  /// Creates an animated [DecoratedBox] whose [Decoration] animation updates
  /// the widget.
  ///
  /// The [decoration] and [position] must not be null.
  ///
  /// See also:
  ///
  ///  * [DecoratedBox.new]
  const DecoratedBoxTransition({
    super.key,
    required this.decoration,
    this.position = DecorationPosition.background,
    required this.child,
  }) : super(listenable: decoration);

  /// Animation of the decoration to paint.
  ///
  /// Can be created using a [DecorationTween] interpolating typically between
  /// two [BoxDecoration].
  final Animation<Decoration> decoration;

  /// Whether to paint the box decoration behind or in front of the child.
  final DecorationPosition position;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration.value,
      position: position,
      child: child,
    );
  }
}

/// Animated version of an [Align] that animates its [Align.alignment] property.
///
/// Here's an illustration of the [DecoratedBoxTransition] widget, with it's
/// [DecoratedBoxTransition.decoration] animated by a [CurvedAnimation] set to
/// [Curves.decelerate]:
///
/// {@animation 300 378 https://flutter.github.io/assets-for-api-docs/assets/widgets/align_transition.mp4}
///
/// {@tool dartpad}
/// The following code implements the [AlignTransition] as seen in the video
/// above:
///
/// ** See code in examples/api/lib/widgets/transitions/align_transition.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [AnimatedAlign], which animates changes to the [alignment] without
///    taking an explicit [Animation] argument.
///  * [PositionedTransition], a widget that animates its child from a start
///    position to an end position over the lifetime of the animation.
///  * [RelativePositionedTransition], a widget that transitions its child's
///    position based on the value of a rectangle relative to a bounding box.
///  * [SizeTransition], a widget that animates its own size and clips and
///    aligns its child.
///  * [SlideTransition], a widget that animates the position of a widget
///    relative to its normal position.
class AlignTransition extends AnimatedWidget {
  /// Creates an animated [Align] whose [AlignmentGeometry] animation updates
  /// the widget.
  ///
  /// See also:
  ///
  ///  * [Align.new].
  const AlignTransition({
    super.key,
    required Animation<AlignmentGeometry> alignment,
    required this.child,
    this.widthFactor,
    this.heightFactor,
  }) : super(listenable: alignment);

  /// The animation that controls the child's alignment.
  Animation<AlignmentGeometry> get alignment => listenable as Animation<AlignmentGeometry>;

  /// If non-null, the child's width factor, see [Align.widthFactor].
  final double? widthFactor;

  /// If non-null, the child's height factor, see [Align.heightFactor].
  final double? heightFactor;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment.value,
      widthFactor: widthFactor,
      heightFactor: heightFactor,
      child: child,
    );
  }
}

/// Animated version of a [DefaultTextStyle] that animates the different properties
/// of its [TextStyle].
///
/// {@tool dartpad}
/// The following code implements the [DefaultTextStyleTransition] that shows
/// a transition between thick blue font and thin red font.
///
/// ** See code in examples/api/lib/widgets/transitions/default_text_style_transition.0.dart **
/// {@end-tool}
///
/// See also:
///
///  * [AnimatedDefaultTextStyle], which animates changes in text style without
///    taking an explicit [Animation] argument.
///  * [DefaultTextStyle], which also defines a [TextStyle] for its descendants
///    but is not animated.
class DefaultTextStyleTransition extends AnimatedWidget {
  /// Creates an animated [DefaultTextStyle] whose [TextStyle] animation updates
  /// the widget.
  const DefaultTextStyleTransition({
    super.key,
    required Animation<TextStyle> style,
    required this.child,
    this.textAlign,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
  }) : super(listenable: style);

  /// The animation that controls the descendants' text style.
  Animation<TextStyle> get style => listenable as Animation<TextStyle>;

  /// How the text should be aligned horizontally.
  final TextAlign? textAlign;

  /// Whether the text should break at soft line breaks.
  ///
  /// See [DefaultTextStyle.softWrap] for more details.
  final bool softWrap;

  /// How visual overflow should be handled.
  ///
  final TextOverflow overflow;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  ///
  /// See [DefaultTextStyle.maxLines] for more details.
  final int? maxLines;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: style.value,
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      child: child,
    );
  }
}

/// A general-purpose widget for building a widget subtree when a [Listenable]
/// changes.
///
/// [ListenableBuilder] is useful for more complex widgets that wish to listen
/// to changes in other objects as part of a larger build function. To use
/// [ListenableBuilder], construct the widget and pass it a [builder]
/// function.
///
/// Any subtype of [Listenable] (such as a [ChangeNotifier], [ValueNotifier], or
/// [Animation]) can be used with a [ListenableBuilder] to rebuild only certain
/// parts of a widget when the [Listenable] notifies its listeners. Although
/// they have identical implementations, if an [Animation] is being listened to,
/// consider using an [AnimatedBuilder] instead for better readability.
///
/// {@tool dartpad}
/// The following example uses a subclass of [ChangeNotifier] to hold the
/// application model's state, in this case, a counter. A [ListenableBuilder] is
/// then used to update the rendering (a [Text] widget) whenever the model changes.
///
/// ** See code in examples/api/lib/widgets/transitions/listenable_builder.2.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This version is identical, but using a [ValueNotifier] instead of a
/// dedicated subclass of [ChangeNotifier]. This works well when there is only a
/// single immutable value to be tracked.
///
/// ** See code in examples/api/lib/widgets/transitions/listenable_builder.1.dart **
/// {@end-tool}
///
/// ## Performance optimizations
///
/// {@template flutter.widgets.transitions.ListenableBuilder.optimizations}
/// If the [builder] function contains a subtree that does not depend on the
/// [listenable], it is more efficient to build that subtree once instead
/// of rebuilding it on every change of the [listenable].
///
/// Performance is therefore improved by specifying any widgets that don't need
/// to change using the prebuilt [child] attribute. The [ListenableBuilder]
/// passes this [child] back to the [builder] callback so that it can be
/// incorporated into the build.
///
/// Using this pre-built [child] is entirely optional, but can improve
/// performance significantly in some cases and is therefore a good practice.
/// {@endtemplate}
///
/// {@tool dartpad}
/// This example shows how a [ListenableBuilder] can be used to listen to a
/// [FocusNode] (which is also a [ChangeNotifier]) to see when a subtree has
/// focus, and modify a decoration when its focus state changes. Only the
/// [Container] is rebuilt when the [FocusNode] changes; the rest of the tree
/// (notably the [Focus] widget) remain unchanged from frame to frame.
///
/// ** See code in examples/api/lib/widgets/transitions/listenable_builder.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [AnimatedBuilder], which has the same functionality, but is named more
///   appropriately for a builder triggered by [Animation]s.
/// * [ValueListenableBuilder], which is specialized for [ValueNotifier]s and
///   reports the new value in its builder callback.
class ListenableBuilder extends AnimatedWidget {
  /// Creates a builder that responds to changes in [listenable].
  ///
  /// The [listenable] and [builder] arguments must not be null.
  const ListenableBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  /// The [Listenable] supplied to the constructor.
  ///
  /// {@tool dartpad}
  /// In this example, the [listenable] is a [ChangeNotifier] subclass that
  /// encapsulates a list. The [ListenableBuilder] is rebuilt each time an item
  /// is added to the list.
  ///
  /// ** See code in examples/api/lib/widgets/transitions/listenable_builder.3.dart **
  /// {@end-tool}
  ///
  /// See also:
  ///
  /// * [AnimatedBuilder], a widget with identical functionality commonly
  ///   used with [Animation] [Listenable]s for better readability.
  //
  // Overridden getter to replace with documentation tailored to
  // ListenableBuilder.
  @override
  Listenable get listenable => super.listenable;

  /// Called every time the [listenable] notifies about a change.
  ///
  /// The child given to the builder should typically be part of the returned
  /// widget tree.
  final TransitionBuilder builder;

  /// The child widget to pass to the [builder].
  ///
  /// {@macro flutter.widgets.transitions.ListenableBuilder.optimizations}
  final Widget? child;

  @override
  Widget build(BuildContext context) => builder(context, child);
}

/// A general-purpose widget for building animations.
///
/// [AnimatedBuilder] is useful for more complex widgets that wish to include
/// an animation as part of a larger build function. To use [AnimatedBuilder],
/// construct the widget and pass it a builder function.
///
/// For simple cases without additional state, consider using
/// [AnimatedWidget].
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=N-RiyZlv8v8}
///
/// Despite the name, [AnimatedBuilder] is not limited to [Animation]s, any
/// subtype of [Listenable] (such as [ChangeNotifier] or [ValueNotifier]) can be
/// used to trigger rebuilds. Although they have identical implementations, if
/// an [Animation] is not being listened to, consider using a
/// [ListenableBuilder] for better readability.
///
/// ## Performance optimizations
///
/// {@template flutter.widgets.transitions.AnimatedBuilder.optimizations}
/// If the [builder] function contains a subtree that does not depend on the
/// animation passed to the constructor, it's more efficient to build that
/// subtree once instead of rebuilding it on every animation tick.
///
/// If a pre-built subtree is passed as the [child] parameter, the
/// [AnimatedBuilder] will pass it back to the [builder] function so that it can
/// be incorporated into the build.
///
/// Using this pre-built child is entirely optional, but can improve
/// performance significantly in some cases and is therefore a good practice.
/// {@endtemplate}
///
/// {@tool dartpad}
/// This code defines a widget that spins a green square continually. It is
/// built with an [AnimatedBuilder] and makes use of the [child] feature to
/// avoid having to rebuild the [Container] each time.
///
/// ** See code in examples/api/lib/widgets/transitions/animated_builder.0.dart **
/// {@end-tool}
///
/// See also:
///
/// * [ListenableBuilder], a widget with similar functionality, but named
///   more appropriately for a builder triggered on changes in [Listenable]s
///   that aren't [Animation]s.
/// * [TweenAnimationBuilder], which animates a property to a target value
///   without requiring manual management of an [AnimationController].
class AnimatedBuilder extends ListenableBuilder {
  /// Creates an animated builder.
  ///
  /// The [animation] and [builder] arguments are required.
  const AnimatedBuilder({
    super.key,
    required Listenable animation,
    required super.builder,
    super.child,
  }) : super(listenable: animation);

  /// The [Listenable] supplied to the constructor (typically an [Animation]).
  ///
  /// Also accessible through the [listenable] getter.
  ///
  /// See also:
  ///
  /// * [ListenableBuilder], a widget with similar functionality commonly used
  ///   with [Listenable]s (such as [ChangeNotifier]) for better readability
  ///   when the [animation] isn't an [Animation].
  Listenable get animation => super.listenable;

  /// The [Listenable] supplied to the constructor (typically an [Animation]).
  ///
  /// Also accessible through the [animation] getter.
  ///
  /// See also:
  ///
  /// * [ListenableBuilder], a widget with identical functionality commonly
  ///   used with non-animation [Listenable]s for readability.
  //
  // Overridden getter to replace with documentation tailored to
  // ListenableBuilder.
  @override
  Listenable get listenable => super.listenable;

  /// Called every time the [animation] notifies about a change.
  ///
  /// The child given to the builder should typically be part of the returned
  /// widget tree.
  //
  // Overridden getter to replace with documentation tailored to
  // AnimatedBuilder.
  @override
  TransitionBuilder get builder => super.builder;
}
