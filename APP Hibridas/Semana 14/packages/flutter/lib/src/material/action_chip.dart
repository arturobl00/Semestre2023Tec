// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/widgets.dart';

import 'chip.dart';
import 'chip_theme.dart';
import 'color_scheme.dart';
import 'colors.dart';
import 'debug.dart';
import 'text_theme.dart';
import 'theme.dart';
import 'theme_data.dart';

enum _ChipVariant { flat, elevated }

/// A Material Design action chip.
///
/// Action chips are a set of options which trigger an action related to primary
/// content. Action chips should appear dynamically and contextually in a UI.
///
/// Action chips can be tapped to trigger an action or show progress and
/// confirmation. For Material 3, a disabled state is supported for Action
/// chips and is specified with [onPressed] being null. For previous versions
/// of Material Design, it is recommended to remove the Action chip from
/// the interface entirely rather than display a disabled chip.
///
/// Action chips are displayed after primary content, such as below a card or
/// persistently at the bottom of a screen.
///
/// The material button widgets, [ElevatedButton], [TextButton], and
/// [OutlinedButton], are an alternative to action chips, which should appear
/// statically and consistently in a UI.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// {@tool dartpad}
/// This example shows how to create an [ActionChip] with a leading icon.
/// The icon is updated when the [ActionChip] is pressed.
///
/// ** See code in examples/api/lib/material/action_chip/action_chip.0.dart **
/// {@end-tool}
///
/// ## Material Design 3
///
/// [ActionChip] can be used for both the Assist and Suggestion chips from
/// Material Design 3. If [ThemeData.useMaterial3] is true, then [ActionChip]
/// will be styled to match the Material Design 3 Assist and Suggestion chips.
///
/// See also:
///
///  * [Chip], a chip that displays information and can be deleted.
///  * [InputChip], a chip that represents a complex piece of information, such
///    as an entity (person, place, or thing) or conversational text, in a
///    compact form.
///  * [ChoiceChip], allows a single selection from a set of options. Choice
///    chips contain related descriptive text or categories.
///  * [CircleAvatar], which shows images or initials of people.
///  * [Wrap], A widget that displays its children in multiple horizontal or
///    vertical runs.
///  * <https://material.io/design/components/chips.html>
class ActionChip extends StatelessWidget implements ChipAttributes, TappableChipAttributes, DisabledChipAttributes {
  /// Create a chip that acts like a button.
  ///
  /// The [label], [onPressed], [autofocus], and [clipBehavior] arguments must
  /// not be null. The [pressElevation] and [elevation] must be null or
  /// non-negative. Typically, [pressElevation] is greater than [elevation].
  const ActionChip({
    super.key,
    this.avatar,
    required this.label,
    this.labelStyle,
    this.labelPadding,
    this.onPressed,
    this.pressElevation,
    this.tooltip,
    this.side,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.backgroundColor,
    this.disabledColor,
    this.padding,
    this.visualDensity,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.iconTheme,
  }) : assert(pressElevation == null || pressElevation >= 0.0),
       assert(elevation == null || elevation >= 0.0),
       _chipVariant = _ChipVariant.flat;

  /// Create an elevated chip that acts like a button.
  ///
  /// The [label], [onPressed], [autofocus], and [clipBehavior] arguments must
  /// not be null. The [pressElevation] and [elevation] must be null or
  /// non-negative. Typically, [pressElevation] is greater than [elevation].
  const ActionChip.elevated({
    super.key,
    this.avatar,
    required this.label,
    this.labelStyle,
    this.labelPadding,
    this.onPressed,
    this.pressElevation,
    this.tooltip,
    this.side,
    this.shape,
    this.clipBehavior = Clip.none,
    this.focusNode,
    this.autofocus = false,
    this.backgroundColor,
    this.disabledColor,
    this.padding,
    this.visualDensity,
    this.materialTapTargetSize,
    this.elevation,
    this.shadowColor,
    this.surfaceTintColor,
    this.iconTheme,
  }) : assert(pressElevation == null || pressElevation >= 0.0),
       assert(elevation == null || elevation >= 0.0),
       _chipVariant = _ChipVariant.elevated;

  @override
  final Widget? avatar;
  @override
  final Widget label;
  @override
  final TextStyle? labelStyle;
  @override
  final EdgeInsetsGeometry? labelPadding;
  @override
  final VoidCallback? onPressed;
  @override
  final double? pressElevation;
  @override
  final String? tooltip;
  @override
  final BorderSide? side;
  @override
  final OutlinedBorder? shape;
  @override
  final Clip clipBehavior;
  @override
  final FocusNode? focusNode;
  @override
  final bool autofocus;
  @override
  final Color? backgroundColor;
  @override
  final Color? disabledColor;
  @override
  final EdgeInsetsGeometry? padding;
  @override
  final VisualDensity? visualDensity;
  @override
  final MaterialTapTargetSize? materialTapTargetSize;
  @override
  final double? elevation;
  @override
  final Color? shadowColor;
  @override
  final Color? surfaceTintColor;
  @override
  final IconThemeData? iconTheme;

  @override
  bool get isEnabled => onPressed != null;

  final _ChipVariant _chipVariant;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ChipThemeData? defaults = Theme.of(context).useMaterial3
      ? _ActionChipDefaultsM3(context, isEnabled, _chipVariant)
      : null;
    return RawChip(
      defaultProperties: defaults,
      avatar: avatar,
      label: label,
      onPressed: onPressed,
      pressElevation: pressElevation,
      tooltip: tooltip,
      labelStyle: labelStyle,
      backgroundColor: backgroundColor,
      side: side,
      shape: shape,
      clipBehavior: clipBehavior,
      focusNode: focusNode,
      autofocus: autofocus,
      disabledColor: disabledColor,
      padding: padding,
      visualDensity: visualDensity,
      isEnabled: isEnabled,
      labelPadding: labelPadding,
      materialTapTargetSize: materialTapTargetSize,
      elevation: elevation,
      shadowColor: shadowColor,
      surfaceTintColor: surfaceTintColor,
    );
  }
}

// BEGIN GENERATED TOKEN PROPERTIES - ActionChip

// Do not edit by hand. The code between the "BEGIN GENERATED" and
// "END GENERATED" comments are generated from data in the Material
// Design token database by the script:
//   dev/tools/gen_defaults/bin/gen_defaults.dart.

// Token database version: v0_162

class _ActionChipDefaultsM3 extends ChipThemeData {
  _ActionChipDefaultsM3(this.context, this.isEnabled, this._chipVariant)
    : super(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
        showCheckmark: true,
      );

  final BuildContext context;
  final bool isEnabled;
  final _ChipVariant _chipVariant;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  double? get elevation => _chipVariant == _ChipVariant.flat
    ? 0.0
    : isEnabled ? 1.0 : 0.0;

  @override
  double? get pressElevation => 1.0;

  @override
  TextStyle? get labelStyle => _textTheme.labelLarge;

  @override
  Color? get backgroundColor => null;

  @override
  Color? get shadowColor => _chipVariant == _ChipVariant.flat
    ? Colors.transparent
    : _colors.shadow;

  @override
  Color? get surfaceTintColor => _colors.surfaceTint;

  @override
  Color? get selectedColor => null;

  @override
  Color? get checkmarkColor => null;

  @override
  Color? get disabledColor => _chipVariant == _ChipVariant.flat
    ? null
    : _colors.onSurface.withOpacity(0.12);

  @override
  Color? get deleteIconColor => null;

  @override
  BorderSide? get side => _chipVariant == _ChipVariant.flat
    ? isEnabled
        ? BorderSide(color: _colors.outline)
        : BorderSide(color: _colors.onSurface.withOpacity(0.12))
    : const BorderSide(color: Colors.transparent);

  @override
  IconThemeData? get iconTheme => IconThemeData(
    color: isEnabled
      ? _colors.primary
      : _colors.onSurface,
    size: 18.0,
  );

  @override
  EdgeInsetsGeometry? get padding => const EdgeInsets.all(8.0);

  /// The chip at text scale 1 starts with 8px on each side and as text scaling
  /// gets closer to 2 the label padding is linearly interpolated from 8px to 4px.
  /// Once the widget has a text scaling of 2 or higher than the label padding
  /// remains 4px.
  @override
  EdgeInsetsGeometry? get labelPadding => EdgeInsets.lerp(
    const EdgeInsets.symmetric(horizontal: 8.0),
    const EdgeInsets.symmetric(horizontal: 4.0),
    clampDouble(MediaQuery.textScaleFactorOf(context) - 1.0, 0.0, 1.0),
  )!;
}

// END GENERATED TOKEN PROPERTIES - ActionChip
