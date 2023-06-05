// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Generate component theme data defaults based on the Material
// Design Token database. These tokens were extracted into a
// JSON file from the internal Google database.
//
// ## Usage
//
// Run this program from the root of the git repository.
//
// ```
// dart dev/tools/gen_defaults/bin/gen_defaults.dart
// ```

import 'dart:convert';
import 'dart:io';

import 'package:gen_defaults/action_chip_template.dart';
import 'package:gen_defaults/app_bar_template.dart';
import 'package:gen_defaults/badge_template.dart';
import 'package:gen_defaults/banner_template.dart';
import 'package:gen_defaults/bottom_app_bar_template.dart';
import 'package:gen_defaults/bottom_sheet_template.dart';
import 'package:gen_defaults/button_template.dart';
import 'package:gen_defaults/card_template.dart';
import 'package:gen_defaults/checkbox_template.dart';
import 'package:gen_defaults/chip_template.dart';
import 'package:gen_defaults/color_scheme_template.dart';
import 'package:gen_defaults/date_picker_template.dart';
import 'package:gen_defaults/dialog_template.dart';
import 'package:gen_defaults/divider_template.dart';
import 'package:gen_defaults/drawer_template.dart';
import 'package:gen_defaults/expansion_tile_template.dart';
import 'package:gen_defaults/fab_template.dart';
import 'package:gen_defaults/filter_chip_template.dart';
import 'package:gen_defaults/icon_button_template.dart';
import 'package:gen_defaults/input_chip_template.dart';
import 'package:gen_defaults/input_decorator_template.dart';
import 'package:gen_defaults/list_tile_template.dart';
import 'package:gen_defaults/menu_template.dart';
import 'package:gen_defaults/navigation_bar_template.dart';
import 'package:gen_defaults/navigation_drawer_template.dart';
import 'package:gen_defaults/navigation_rail_template.dart';
import 'package:gen_defaults/popup_menu_template.dart';
import 'package:gen_defaults/progress_indicator_template.dart';
import 'package:gen_defaults/radio_template.dart';
import 'package:gen_defaults/search_bar_template.dart';
import 'package:gen_defaults/search_view_template.dart';
import 'package:gen_defaults/segmented_button_template.dart';
import 'package:gen_defaults/slider_template.dart';
import 'package:gen_defaults/snackbar_template.dart';
import 'package:gen_defaults/surface_tint.dart';
import 'package:gen_defaults/switch_template.dart';
import 'package:gen_defaults/tabs_template.dart';
import 'package:gen_defaults/text_field_template.dart';
import 'package:gen_defaults/time_picker_template.dart';
import 'package:gen_defaults/typography_template.dart';

Map<String, dynamic> _readTokenFile(String fileName) {
  return jsonDecode(File('dev/tools/gen_defaults/data/$fileName').readAsStringSync()) as Map<String, dynamic>;
}

Future<void> main(List<String> args) async {
  const String materialLib = 'packages/flutter/lib/src/material';
  const List<String> tokenFiles = <String>[
    'badge.json',
    'banner.json',
    'badge.json',
    'bottom_app_bar.json',
    'button_elevated.json',
    'button_filled.json',
    'button_filled_tonal.json',
    'button_outlined.json',
    'button_text.json',
    'card_elevated.json',
    'card_filled.json',
    'card_outlined.json',
    'checkbox.json',
    'chip_assist.json',
    'chip_filter.json',
    'chip_input.json',
    'chip_suggestion.json',
    'color_dark.json',
    'color_light.json',
    'date_picker_docked.json',
    'date_picker_modal.json',
    'dialog.json',
    'dialog_fullscreen.json',
    'divider.json',
    'elevation.json',
    'fab_extended_primary.json',
    'fab_large_primary.json',
    'fab_primary.json',
    'fab_small_primary.json',
    'icon_button.json',
    'icon_button_filled.json',
    'icon_button_filled_tonal.json',
    'icon_button_outlined.json',
    'list.json',
    'menu.json',
    'motion.json',
    'navigation_bar.json',
    'navigation_drawer.json',
    'navigation_rail.json',
    'navigation_tab_primary.json',
    'navigation_tab_secondary.json',
    'palette.json',
    'progress_indicator_circular.json',
    'progress_indicator_linear.json',
    'radio_button.json',
    'search_bar.json',
    'search_view.json',
    'segmented_button_outlined.json',
    'shape.json',
    'sheet_bottom.json',
    'slider.json',
    'snackbar.json',
    'state.json',
    'switch.json',
    'text_field_filled.json',
    'text_field_outlined.json',
    'text_style.json',
    'time_picker.json',
    'top_app_bar_large.json',
    'top_app_bar_medium.json',
    'top_app_bar_small.json',
    'typeface.json',
  ];

  // Generate a map with all the tokens to simplify the template interface.
  final Map<String, dynamic> tokens = <String, dynamic>{};
  for (final String tokenFile in tokenFiles) {
    tokens.addAll(_readTokenFile(tokenFile));
  }

  // Special case the light and dark color schemes.
  tokens['colorsLight'] = _readTokenFile('color_light.json');
  tokens['colorsDark'] = _readTokenFile('color_dark.json');

  ChipTemplate('Chip', '$materialLib/chip.dart', tokens).updateFile();
  ActionChipTemplate('ActionChip', '$materialLib/action_chip.dart', tokens).updateFile();
  AppBarTemplate('AppBar', '$materialLib/app_bar.dart', tokens).updateFile();
  BottomAppBarTemplate('BottomAppBar', '$materialLib/bottom_app_bar.dart', tokens).updateFile();
  BadgeTemplate('Badge', '$materialLib/badge.dart', tokens).updateFile();
  BannerTemplate('Banner', '$materialLib/banner.dart', tokens).updateFile();
  BottomAppBarTemplate('BottomAppBar', '$materialLib/bottom_app_bar.dart', tokens).updateFile();
  BottomSheetTemplate('BottomSheet', '$materialLib/bottom_sheet.dart', tokens).updateFile();
  ButtonTemplate('md.comp.elevated-button', 'ElevatedButton', '$materialLib/elevated_button.dart', tokens).updateFile();
  ButtonTemplate('md.comp.filled-button', 'FilledButton', '$materialLib/filled_button.dart', tokens).updateFile();
  ButtonTemplate('md.comp.filled-tonal-button', 'FilledTonalButton', '$materialLib/filled_button.dart', tokens).updateFile();
  ButtonTemplate('md.comp.outlined-button', 'OutlinedButton', '$materialLib/outlined_button.dart', tokens).updateFile();
  ButtonTemplate('md.comp.text-button', 'TextButton', '$materialLib/text_button.dart', tokens).updateFile();
  CardTemplate('Card', '$materialLib/card.dart', tokens).updateFile();
  CheckboxTemplate('Checkbox', '$materialLib/checkbox.dart', tokens).updateFile();
  ColorSchemeTemplate('ColorScheme', '$materialLib/theme_data.dart', tokens).updateFile();
  DatePickerTemplate('DatePicker', '$materialLib/date_picker_theme.dart', tokens).updateFile();
  DialogFullscreenTemplate('DialogFullscreen', '$materialLib/dialog.dart', tokens).updateFile();
  DialogTemplate('Dialog', '$materialLib/dialog.dart', tokens).updateFile();
  DividerTemplate('Divider', '$materialLib/divider.dart', tokens).updateFile();
  DrawerTemplate('Drawer', '$materialLib/drawer.dart', tokens).updateFile();
  ExpansionTileTemplate('ExpansionTile', '$materialLib/expansion_tile.dart', tokens).updateFile();
  FABTemplate('FAB', '$materialLib/floating_action_button.dart', tokens).updateFile();
  FilterChipTemplate('ChoiceChip', '$materialLib/choice_chip.dart', tokens).updateFile();
  FilterChipTemplate('FilterChip', '$materialLib/filter_chip.dart', tokens).updateFile();
  IconButtonTemplate('md.comp.icon-button', 'IconButton', '$materialLib/icon_button.dart', tokens).updateFile();
  IconButtonTemplate('md.comp.filled-icon-button', 'FilledIconButton', '$materialLib/icon_button.dart', tokens).updateFile();
  IconButtonTemplate('md.comp.filled-tonal-icon-button', 'FilledTonalIconButton', '$materialLib/icon_button.dart', tokens).updateFile();
  IconButtonTemplate('md.comp.outlined-icon-button', 'OutlinedIconButton', '$materialLib/icon_button.dart', tokens).updateFile();
  InputChipTemplate('InputChip', '$materialLib/input_chip.dart', tokens).updateFile();
  ListTileTemplate('LisTile', '$materialLib/list_tile.dart', tokens).updateFile();
  InputDecoratorTemplate('InputDecorator', '$materialLib/input_decorator.dart', tokens).updateFile();
  MenuTemplate('Menu', '$materialLib/menu_anchor.dart', tokens).updateFile();
  NavigationBarTemplate('NavigationBar', '$materialLib/navigation_bar.dart', tokens).updateFile();
  NavigationDrawerTemplate('NavigationDrawer', '$materialLib/navigation_drawer.dart', tokens).updateFile();
  NavigationRailTemplate('NavigationRail', '$materialLib/navigation_rail.dart', tokens).updateFile();
  PopupMenuTemplate('PopupMenu', '$materialLib/popup_menu.dart', tokens).updateFile();
  ProgressIndicatorTemplate('ProgressIndicator', '$materialLib/progress_indicator.dart', tokens).updateFile();
  RadioTemplate('Radio<T>', '$materialLib/radio.dart', tokens).updateFile();
  SearchBarTemplate('SearchBar', '$materialLib/search_anchor.dart', tokens).updateFile();
  SearchViewTemplate('SearchView', '$materialLib/search_anchor.dart', tokens).updateFile();
  SegmentedButtonTemplate('md.comp.outlined-segmented-button', 'SegmentedButton', '$materialLib/segmented_button.dart', tokens).updateFile();
  SnackbarTemplate('md.comp.snackbar', 'Snackbar', '$materialLib/snack_bar.dart', tokens).updateFile();
  SliderTemplate('md.comp.slider', 'Slider', '$materialLib/slider.dart', tokens).updateFile();
  SurfaceTintTemplate('SurfaceTint', '$materialLib/elevation_overlay.dart', tokens).updateFile();
  SwitchTemplate('Switch', '$materialLib/switch.dart', tokens).updateFile();
  TimePickerTemplate('TimePicker', '$materialLib/time_picker.dart', tokens).updateFile();
  TextFieldTemplate('TextField', '$materialLib/text_field.dart', tokens).updateFile();
  TabsTemplate('Tabs', '$materialLib/tabs.dart', tokens).updateFile();
  TypographyTemplate('Typography', '$materialLib/typography.dart', tokens).updateFile();
}
