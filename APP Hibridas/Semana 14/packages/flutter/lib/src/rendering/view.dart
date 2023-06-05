// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:io' show Platform;
import 'dart:ui' as ui show FlutterView, Scene, SceneBuilder, SemanticsUpdate;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'binding.dart';
import 'box.dart';
import 'debug.dart';
import 'layer.dart';
import 'object.dart';

/// The layout constraints for the root render object.
@immutable
class ViewConfiguration {
  /// Creates a view configuration.
  ///
  /// By default, the view has zero [size] and a [devicePixelRatio] of 1.0.
  const ViewConfiguration({
    this.size = Size.zero,
    this.devicePixelRatio = 1.0,
  });

  /// The size of the output surface.
  final Size size;

  /// The pixel density of the output surface.
  final double devicePixelRatio;

  /// Creates a transformation matrix that applies the [devicePixelRatio].
  ///
  /// The matrix translates points from the local coordinate system of the
  /// app (in logical pixels) to the global coordinate system of the
  /// [FlutterView] (in physical pixels).
  Matrix4 toMatrix() {
    return Matrix4.diagonal3Values(devicePixelRatio, devicePixelRatio, 1.0);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is ViewConfiguration
        && other.size == size
        && other.devicePixelRatio == devicePixelRatio;
  }

  @override
  int get hashCode => Object.hash(size, devicePixelRatio);

  @override
  String toString() => '$size at ${debugFormatDouble(devicePixelRatio)}x';
}

/// The root of the render tree.
///
/// The view represents the total output surface of the render tree and handles
/// bootstrapping the rendering pipeline. The view has a unique child
/// [RenderBox], which is required to fill the entire output surface.
class RenderView extends RenderObject with RenderObjectWithChildMixin<RenderBox> {
  /// Creates the root of the render tree.
  ///
  /// Typically created by the binding (e.g., [RendererBinding]).
  ///
  /// The [configuration] must not be null.
  RenderView({
    RenderBox? child,
    required ViewConfiguration configuration,
    required ui.FlutterView view,
  }) : _configuration = configuration,
       _view = view {
    this.child = child;
  }

  /// The current layout size of the view.
  Size get size => _size;
  Size _size = Size.zero;

  /// The constraints used for the root layout.
  ViewConfiguration get configuration => _configuration;
  ViewConfiguration _configuration;

  /// The configuration is initially set by the [configuration] argument
  /// passed to the constructor.
  ///
  /// Always call [prepareInitialFrame] before changing the configuration.
  set configuration(ViewConfiguration value) {
    if (configuration == value) {
      return;
    }
    final ViewConfiguration oldConfiguration = _configuration;
    _configuration = value;
    if (oldConfiguration.toMatrix() != _configuration.toMatrix()) {
      replaceRootLayer(_updateMatricesAndCreateNewRootLayer());
    }
    assert(_rootTransform != null);
    markNeedsLayout();
  }

  final ui.FlutterView _view;

  /// Whether Flutter should automatically compute the desired system UI.
  ///
  /// When this setting is enabled, Flutter will hit-test the layer tree at the
  /// top and bottom of the screen on each frame looking for an
  /// [AnnotatedRegionLayer] with an instance of a [SystemUiOverlayStyle]. The
  /// hit-test result from the top of the screen provides the status bar settings
  /// and the hit-test result from the bottom of the screen provides the system
  /// nav bar settings.
  ///
  /// If there is no [AnnotatedRegionLayer] on the bottom, the hit-test result
  /// from the top provides the system nav bar settings. If there is no
  /// [AnnotatedRegionLayer] on the top, the hit-test result from the bottom
  /// provides the system status bar settings.
  ///
  /// Setting this to false does not cause previous automatic adjustments to be
  /// reset, nor does setting it to true cause the app to update immediately.
  ///
  /// If you want to imperatively set the system ui style instead, it is
  /// recommended that [automaticSystemUiAdjustment] is set to false.
  ///
  /// See also:
  ///
  ///  * [AnnotatedRegion], for placing [SystemUiOverlayStyle] in the layer tree.
  ///  * [SystemChrome.setSystemUIOverlayStyle], for imperatively setting the system ui style.
  bool automaticSystemUiAdjustment = true;

  /// Bootstrap the rendering pipeline by preparing the first frame.
  ///
  /// This should only be called once, and must be called before changing
  /// [configuration]. It is typically called immediately after calling the
  /// constructor.
  ///
  /// This does not actually schedule the first frame. Call
  /// [PipelineOwner.requestVisualUpdate] on [owner] to do that.
  void prepareInitialFrame() {
    assert(owner != null);
    assert(_rootTransform == null);
    scheduleInitialLayout();
    scheduleInitialPaint(_updateMatricesAndCreateNewRootLayer());
    assert(_rootTransform != null);
  }

  Matrix4? _rootTransform;

  TransformLayer _updateMatricesAndCreateNewRootLayer() {
    _rootTransform = configuration.toMatrix();
    final TransformLayer rootLayer = TransformLayer(transform: _rootTransform);
    rootLayer.attach(this);
    assert(_rootTransform != null);
    return rootLayer;
  }

  // We never call layout() on this class, so this should never get
  // checked. (This class is laid out using scheduleInitialLayout().)
  @override
  void debugAssertDoesMeetConstraints() { assert(false); }

  @override
  void performResize() {
    assert(false);
  }

  @override
  void performLayout() {
    assert(_rootTransform != null);
    _size = configuration.size;
    assert(_size.isFinite);

    if (child != null) {
      child!.layout(BoxConstraints.tight(_size));
    }
  }

  /// Determines the set of render objects located at the given position.
  ///
  /// Returns true if the given point is contained in this render object or one
  /// of its descendants. Adds any render objects that contain the point to the
  /// given hit test result.
  ///
  /// The [position] argument is in the coordinate system of the render view,
  /// which is to say, in logical pixels. This is not necessarily the same
  /// coordinate system as that expected by the root [Layer], which will
  /// normally be in physical (device) pixels.
  bool hitTest(HitTestResult result, { required Offset position }) {
    if (child != null) {
      child!.hitTest(BoxHitTestResult.wrap(result), position: position);
    }
    result.add(HitTestEntry(this));
    return true;
  }

  /// Determines the set of mouse tracker annotations at the given position.
  ///
  /// See also:
  ///
  ///  * [Layer.findAllAnnotations], which is used by this method to find all
  ///    [AnnotatedRegionLayer]s annotated for mouse tracking.
  HitTestResult hitTestMouseTrackers(Offset position) {
    final BoxHitTestResult result = BoxHitTestResult();
    hitTest(result, position: position);
    return result;
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      context.paintChild(child!, offset);
    }
    assert(() {
      final List<DebugPaintCallback> localCallbacks = _debugPaintCallbacks.toList();
      for (final DebugPaintCallback paintCallback in localCallbacks) {
        if (_debugPaintCallbacks.contains(paintCallback)) {
          paintCallback(context, offset, this);
        }
      }
      return true;
    }());
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    assert(_rootTransform != null);
    transform.multiply(_rootTransform!);
    super.applyPaintTransform(child, transform);
  }

  /// Uploads the composited layer tree to the engine.
  ///
  /// Actually causes the output of the rendering pipeline to appear on screen.
  void compositeFrame() {
    if (!kReleaseMode) {
      Timeline.startSync('COMPOSITING');
    }
    try {
      final ui.SceneBuilder builder = ui.SceneBuilder();
      final ui.Scene scene = layer!.buildScene(builder);
      if (automaticSystemUiAdjustment) {
        _updateSystemChrome();
      }
      _view.render(scene);
      scene.dispose();
      assert(() {
        if (debugRepaintRainbowEnabled || debugRepaintTextRainbowEnabled) {
          debugCurrentRepaintColor = debugCurrentRepaintColor.withHue((debugCurrentRepaintColor.hue + 2.0) % 360.0);
        }
        return true;
      }());
    } finally {
      if (!kReleaseMode) {
        Timeline.finishSync();
      }
    }
  }

  /// Sends the provided [SemanticsUpdate] to the [FlutterView] associated with
  /// this [RenderView].
  ///
  /// A [SemanticsUpdate] is produced by a [SemanticsOwner] during the
  /// [EnginePhase.flushSemantics] phase.
  void updateSemantics(ui.SemanticsUpdate update) {
    _view.updateSemantics(update);
  }

  void _updateSystemChrome() {
    // Take overlay style from the place where a system status bar and system
    // navigation bar are placed to update system style overlay.
    // The center of the system navigation bar and the center of the status bar
    // are used to get SystemUiOverlayStyle's to update system overlay appearance.
    //
    //         Horizontal center of the screen
    //                 V
    //    ++++++++++++++++++++++++++
    //    |                        |
    //    |    System status bar   |  <- Vertical center of the status bar
    //    |                        |
    //    ++++++++++++++++++++++++++
    //    |                        |
    //    |        Content         |
    //    ~                        ~
    //    |                        |
    //    ++++++++++++++++++++++++++
    //    |                        |
    //    |  System navigation bar | <- Vertical center of the navigation bar
    //    |                        |
    //    ++++++++++++++++++++++++++ <- bounds.bottom
    final Rect bounds = paintBounds;
    // Center of the status bar
    final Offset top = Offset(
      // Horizontal center of the screen
      bounds.center.dx,
      // The vertical center of the system status bar. The system status bar
      // height is kept as top window padding.
      _view.padding.top / 2.0,
    );
    // Center of the navigation bar
    final Offset bottom = Offset(
      // Horizontal center of the screen
      bounds.center.dx,
      // Vertical center of the system navigation bar. The system navigation bar
      // height is kept as bottom window padding. The "1" needs to be subtracted
      // from the bottom because available pixels are in (0..bottom) range.
      // I.e. for a device with 1920 height, bound.bottom is 1920, but the most
      // bottom drawn pixel is at 1919 position.
      bounds.bottom - 1.0 - _view.padding.bottom / 2.0,
    );
    final SystemUiOverlayStyle? upperOverlayStyle = layer!.find<SystemUiOverlayStyle>(top);
    // Only android has a customizable system navigation bar.
    SystemUiOverlayStyle? lowerOverlayStyle;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        lowerOverlayStyle = layer!.find<SystemUiOverlayStyle>(bottom);
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        break;
    }
    // If there are no overlay style in the UI don't bother updating.
    if (upperOverlayStyle == null && lowerOverlayStyle == null) {
      return;
    }

    // If both are not null, the upper provides the status bar properties and the lower provides
    // the system navigation bar properties. This is done for advanced use cases where a widget
    // on the top (for instance an app bar) will create an annotated region to set the status bar
    // style and another widget on the bottom will create an annotated region to set the system
    // navigation bar style.
    if (upperOverlayStyle != null && lowerOverlayStyle != null) {
      final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
        statusBarBrightness: upperOverlayStyle.statusBarBrightness,
        statusBarIconBrightness: upperOverlayStyle.statusBarIconBrightness,
        statusBarColor: upperOverlayStyle.statusBarColor,
        systemStatusBarContrastEnforced: upperOverlayStyle.systemStatusBarContrastEnforced,
        systemNavigationBarColor: lowerOverlayStyle.systemNavigationBarColor,
        systemNavigationBarDividerColor: lowerOverlayStyle.systemNavigationBarDividerColor,
        systemNavigationBarIconBrightness: lowerOverlayStyle.systemNavigationBarIconBrightness,
        systemNavigationBarContrastEnforced: lowerOverlayStyle.systemNavigationBarContrastEnforced,
      );
      SystemChrome.setSystemUIOverlayStyle(overlayStyle);
      return;
    }
    // If only one of the upper or the lower overlay style is not null, it provides all properties.
    // This is done for developer convenience as it allows setting both status bar style and
    // navigation bar style using only one annotated region layer (for instance the one
    // automatically created by an [AppBar]).
    final bool isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final SystemUiOverlayStyle definedOverlayStyle = (upperOverlayStyle ?? lowerOverlayStyle)!;
    final SystemUiOverlayStyle overlayStyle = SystemUiOverlayStyle(
      statusBarBrightness: definedOverlayStyle.statusBarBrightness,
      statusBarIconBrightness: definedOverlayStyle.statusBarIconBrightness,
      statusBarColor: definedOverlayStyle.statusBarColor,
      systemStatusBarContrastEnforced: definedOverlayStyle.systemStatusBarContrastEnforced,
      systemNavigationBarColor: isAndroid ? definedOverlayStyle.systemNavigationBarColor : null,
      systemNavigationBarDividerColor: isAndroid ? definedOverlayStyle.systemNavigationBarDividerColor : null,
      systemNavigationBarIconBrightness: isAndroid ? definedOverlayStyle.systemNavigationBarIconBrightness : null,
      systemNavigationBarContrastEnforced: isAndroid ? definedOverlayStyle.systemNavigationBarContrastEnforced : null,
    );
    SystemChrome.setSystemUIOverlayStyle(overlayStyle);
  }

  @override
  Rect get paintBounds => Offset.zero & (size * configuration.devicePixelRatio);

  @override
  Rect get semanticBounds {
    assert(_rootTransform != null);
    return MatrixUtils.transformRect(_rootTransform!, Offset.zero & size);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    // call to ${super.debugFillProperties(description)} is omitted because the
    // root superclasses don't include any interesting information for this
    // class
    assert(() {
      properties.add(DiagnosticsNode.message('debug mode enabled - ${kIsWeb ? 'Web' :  Platform.operatingSystem}'));
      return true;
    }());
    properties.add(DiagnosticsProperty<Size>('view size', _view.physicalSize, tooltip: 'in physical pixels'));
    properties.add(DoubleProperty('device pixel ratio', _view.devicePixelRatio, tooltip: 'physical pixels per logical pixel'));
    properties.add(DiagnosticsProperty<ViewConfiguration>('configuration', configuration, tooltip: 'in logical pixels'));
    if (_view.platformDispatcher.semanticsEnabled) {
      properties.add(DiagnosticsNode.message('semantics enabled'));
    }
  }

  static final List<DebugPaintCallback> _debugPaintCallbacks = <DebugPaintCallback>[];

  /// Registers a [DebugPaintCallback] that is called every time a [RenderView]
  /// repaints in debug mode.
  ///
  /// The callback may paint a debug overlay on top of the content of the
  /// [RenderView] provided to the callback. Callbacks are invoked in the
  /// order they were registered in.
  ///
  /// Neither registering a callback nor the continued presence of a callback
  /// changes how often [RenderView]s are repainted. It is up to the owner of
  /// the callback to call [markNeedsPaint] on any [RenderView] for which it
  /// wants to update the painted overlay.
  ///
  /// Does nothing in release mode.
  static void debugAddPaintCallback(DebugPaintCallback callback) {
    assert(() {
      _debugPaintCallbacks.add(callback);
      return true;
    }());
  }

  /// Removes a callback registered with [debugAddPaintCallback].
  ///
  /// It does not schedule a frame to repaint the [RenderView]s without the
  /// overlay painted by the removed callback. It is up to the owner of the
  /// callback to call [markNeedsPaint] on the relevant [RenderView]s to
  /// repaint them without the overlay.
  ///
  /// Does nothing in release mode.
  static void debugRemovePaintCallback(DebugPaintCallback callback) {
    assert(() {
      _debugPaintCallbacks.remove(callback);
      return true;
    }());
  }
}

/// A callback for painting a debug overlay on top of the provided [RenderView].
///
/// Used by [RenderView.debugAddPaintCallback] and
/// [RenderView.debugRemovePaintCallback].
typedef DebugPaintCallback = void Function(PaintingContext context, Offset offset, RenderView renderView);
