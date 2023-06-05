// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'template.dart';

class FilterChipTemplate extends TokenTemplate {
  const FilterChipTemplate(super.blockName, super.fileName, super.tokens, {
    super.colorSchemePrefix = '_colors.',
    super.textThemePrefix = '_textTheme.'
  });

  static const String tokenGroup = 'md.comp.filter-chip';
  static const String flatVariant = '.flat';
  static const String elevatedVariant = '.elevated';

  @override
  String generate() => '''
class _${blockName}DefaultsM3 extends ChipThemeData {
  _${blockName}DefaultsM3(
    this.context,
    this.isEnabled,
    this.isSelected,
    this._chipVariant,
  ) : super(
        shape: ${shape("$tokenGroup.container")},
        showCheckmark: true,
      );

  final BuildContext context;
  final bool isEnabled;
  final bool isSelected;
  final _ChipVariant _chipVariant;
  late final ColorScheme _colors = Theme.of(context).colorScheme;
  late final TextTheme _textTheme = Theme.of(context).textTheme;

  @override
  double? get elevation => _chipVariant == _ChipVariant.flat
    ? ${elevation("$tokenGroup$flatVariant.container")}
    : isEnabled ? ${elevation("$tokenGroup$elevatedVariant.container")} : ${elevation("$tokenGroup$elevatedVariant.disabled.container")};

  @override
  double? get pressElevation => ${elevation("$tokenGroup$elevatedVariant.pressed.container")};

  @override
  TextStyle? get labelStyle => ${textStyle("$tokenGroup.label-text")};

  @override
  Color? get backgroundColor => ${componentColor("$tokenGroup$flatVariant.container")};

  @override
  Color? get shadowColor => _chipVariant == _ChipVariant.flat
    ? ${colorOrTransparent("$tokenGroup$flatVariant.container.shadow-color")}
    : ${colorOrTransparent("$tokenGroup$elevatedVariant.container.shadow-color")};

  @override
  Color? get surfaceTintColor => ${colorOrTransparent("$tokenGroup.container.surface-tint-layer.color")};

  @override
  Color? get selectedColor => _chipVariant == _ChipVariant.flat
    ? isEnabled
      ? ${componentColor("$tokenGroup$flatVariant.selected.container")}
      : ${componentColor("$tokenGroup$flatVariant.disabled.selected.container")}
    : isEnabled
      ? ${componentColor("$tokenGroup$elevatedVariant.selected.container")}
      : ${componentColor("$tokenGroup$elevatedVariant.disabled.container")};

  @override
  Color? get checkmarkColor => ${color("$tokenGroup.with-leading-icon.selected.leading-icon.color")};

  @override
  Color? get disabledColor => _chipVariant == _ChipVariant.flat
    ? isSelected
      ? ${componentColor("$tokenGroup$flatVariant.disabled.selected.container")}
      : ${componentColor("$tokenGroup$flatVariant.disabled.unselected.container")}
    : ${componentColor("$tokenGroup$elevatedVariant.disabled.container")};

  @override
  Color? get deleteIconColor => ${color("$tokenGroup.with-trailing-icon.selected.trailing-icon.color")};

  @override
  BorderSide? get side => _chipVariant == _ChipVariant.flat && !isSelected
    ? isEnabled
      ? ${border('$tokenGroup$flatVariant.unselected.outline')}
      : ${border('$tokenGroup$flatVariant.disabled.unselected.outline')}
    : const BorderSide(color: Colors.transparent);

  @override
  IconThemeData? get iconTheme => IconThemeData(
    color: isEnabled
      ? ${color("$tokenGroup.with-icon.icon.color")}
      : ${color("$tokenGroup.with-leading-icon.disabled.leading-icon.color")},
    size: ${tokens["$tokenGroup.with-icon.icon.size"]},
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
''';
}
