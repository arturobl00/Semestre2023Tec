// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

RenderBox getMaterialBox(WidgetTester tester) {
  return tester.firstRenderObject<RenderBox>(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(CustomPaint),
    ),
  );
}

Material getMaterial(WidgetTester tester) {
  return tester.widget<Material>(
    find.descendant(
      of: find.byType(RawChip),
      matching: find.byType(Material),
    ),
  );
}

DefaultTextStyle getLabelStyle(WidgetTester tester, String labelText) {
  return tester.widget(
    find.ancestor(
      of: find.text(labelText),
      matching: find.byType(DefaultTextStyle),
    ).first,
  );
}

/// Adds the basic requirements for a Chip.
Widget wrapForChip({
  required Widget child,
  TextDirection textDirection = TextDirection.ltr,
  double textScaleFactor = 1.0,
  Brightness brightness = Brightness.light,
}) {
  return MaterialApp(
    theme: ThemeData(brightness: brightness),
    home: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: MediaQueryData(textScaleFactor: textScaleFactor),
        child: Material(child: child),
      ),
    ),
  );
}

void checkChipMaterialClipBehavior(WidgetTester tester, Clip clipBehavior) {
  final Iterable<Material> materials = tester.widgetList<Material>(find.byType(Material));
  // There should be two Material widgets, first Material is from the "_wrapForChip" and
  // last Material is from the "RawChip".
  expect(materials.length, 2);
  // The last Material from `RawChip` should have the clip behavior.
  expect(materials.last.clipBehavior, clipBehavior);
}

void main() {
  testWidgets('ChoiceChip defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    const String label = 'choice chip';

    // Test enabled ChoiceChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: ChoiceChip(
              selected: false,
              onSelected: (bool valueChanged) { },
              label: const Text(label),
            ),
          ),
        ),
      ),
    );

    // Test default chip size.
    expect(tester.getSize(find.byType(ChoiceChip)), const Size(190.0, 48.0));
    // Test default label style.
    expect(
      getLabelStyle(tester, label).style.color!.value,
      theme.textTheme.labelLarge!.color!.value,
    );

    Material chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, Colors.transparent);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
    );

    ShapeDecoration decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, null);

    // Test disabled ChoiceChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: ChoiceChip(
            selected: false,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, Colors.transparent);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.12)),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, null);

    // Test selected enabled ChoiceChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: ChoiceChip(
            selected: true,
            onSelected: (bool valueChanged) { },
            label: const Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.secondaryContainer);

    // Test selected disabled ChoiceChip defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: ChoiceChip(
            selected: true,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.onSurface.withOpacity(0.12));
  });

  testWidgets('ChoiceChip.elevated defaults', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(useMaterial3: true);
    const String label = 'choice chip';

    // Test enabled ChoiceChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: Center(
            child: ChoiceChip.elevated(
              selected: false,
              onSelected: (bool valueChanged) { },
              label: const Text(label),
            ),
          ),
        ),
      ),
    );

    // Test default chip size.
    expect(tester.getSize(find.byType(ChoiceChip)), const Size(190.0, 48.0));
    // Test default label style.
    expect(
      getLabelStyle(tester, label).style.color!.value,
      theme.textTheme.labelLarge!.color!.value,
    );

    Material chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 1);
    expect(chipMaterial.shadowColor, theme.colorScheme.shadow);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    ShapeDecoration decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, null);

    // Test disabled ChoiceChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: ChoiceChip.elevated(
            selected: false,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, theme.colorScheme.shadow);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.onSurface.withOpacity(0.12));

    // Test selected enabled ChoiceChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Material(
          child: ChoiceChip.elevated(
            selected: true,
            onSelected: (bool valueChanged) { },
            label: const Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 1);
    expect(chipMaterial.shadowColor, null);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.secondaryContainer);

    // Test selected disabled ChoiceChip.elevated defaults.
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Material(
          child: ChoiceChip.elevated(
            selected: false,
            label: Text(label),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    chipMaterial = getMaterial(tester);
    expect(chipMaterial.elevation, 0);
    expect(chipMaterial.shadowColor, theme.colorScheme.shadow);
    expect(chipMaterial.surfaceTintColor, theme.colorScheme.surfaceTint);
    expect(
      chipMaterial.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        side: BorderSide(color: Colors.transparent),
      ),
    );

    decoration = tester.widget<Ink>(find.byType(Ink)).decoration! as ShapeDecoration;
    expect(decoration.color, theme.colorScheme.onSurface.withOpacity(0.12));
  });

  testWidgets('ChoiceChip can be tapped', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Material(
          child: ChoiceChip(
            selected: false,
            label: Text('choice chip'),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ChoiceChip));
    expect(tester.takeException(), null);
  });

  testWidgets('ChoiceChip clipBehavior properly passes through to the Material', (WidgetTester tester) async {
    const Text label = Text('label');
    await tester.pumpWidget(wrapForChip(child: const ChoiceChip(label: label, selected: false)));
    checkChipMaterialClipBehavior(tester, Clip.none);

    await tester.pumpWidget(wrapForChip(child: const ChoiceChip(label: label, selected: false, clipBehavior: Clip.antiAlias)));
    checkChipMaterialClipBehavior(tester, Clip.antiAlias);
  });

  testWidgets('ChoiceChip passes iconTheme property to RawChip', (WidgetTester tester) async {
    const IconThemeData iconTheme = IconThemeData(color: Colors.red);
    await tester.pumpWidget(wrapForChip(
      child: const ChoiceChip(
      label: Text('Test'),
      selected: true,
      iconTheme: iconTheme,
    )));
    final RawChip rawChip = tester.widget(find.byType(RawChip));
    expect(rawChip.iconTheme, iconTheme);
  });

  testWidgets('ChoiceChip passes showCheckmark from ChipTheme to RawChip', (WidgetTester tester) async {
    const bool showCheckmark = false;
    await tester.pumpWidget(wrapForChip(
        child: const ChipTheme(
          data: ChipThemeData(
            showCheckmark: showCheckmark,
          ),
          child: ChoiceChip(
            label: Text('Test'),
            selected: true,
          ),
        )));
    final RawChip rawChip = tester.widget(find.byType(RawChip));
    expect(rawChip.showCheckmark, showCheckmark);
  });

  testWidgets('ChoiceChip passes checkmark properties to RawChip', (WidgetTester tester) async {
    const bool showCheckmark = false;
    const Color checkmarkColor = Color(0xff0000ff);
    await tester.pumpWidget(wrapForChip(
      child: const ChoiceChip(
        label: Text('Test'),
        selected: true,
        showCheckmark: showCheckmark,
        checkmarkColor: checkmarkColor,
    )));
    final RawChip rawChip = tester.widget(find.byType(RawChip));
    expect(rawChip.showCheckmark, showCheckmark);
    expect(rawChip.checkmarkColor, checkmarkColor);
  });

  group('Material 2', () {
    // These tests are only relevant for Material 2. Once Material 2
    // support is deprecated and the APIs are removed, these tests
    // can be deleted.

    testWidgets('ChoiceChip defaults', (WidgetTester tester) async {
      Widget buildFrame(Brightness brightness) {
        return MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: const Scaffold(
            body: Center(
              child: ChoiceChip(
                label: Text('Chip A'),
                selected: true,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildFrame(Brightness.light));
      expect(getMaterialBox(tester), paints..rrect(color: const Color(0x3d000000)));
      expect(tester.getSize(find.byType(ChoiceChip)), const Size(108.0, 48.0));
      expect(getMaterial(tester).color, null);
      expect(getMaterial(tester).elevation, 0);
      expect(getMaterial(tester).shape, const StadiumBorder());
      expect(getLabelStyle(tester, 'Chip A').style.color?.value, 0xde000000);

      await tester.pumpWidget(buildFrame(Brightness.dark));
      await tester.pumpAndSettle(); // Theme transition animation
      expect(getMaterialBox(tester), paints..rrect(color: const Color(0x3dffffff)));
      expect(tester.getSize(find.byType(ChoiceChip)), const Size(108.0, 48.0));
      expect(getMaterial(tester).color, null);
      expect(getMaterial(tester).elevation, 0);
      expect(getMaterial(tester).shape, const StadiumBorder());
      expect(getLabelStyle(tester, 'Chip A').style.color?.value, 0xdeffffff);
    });
  });
}
