// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../foundation/leak_tracking.dart';
import '../widgets/clipboard_utils.dart';
import '../widgets/editable_text_utils.dart';

void main() {
  final MockClipboard mockClipboard = MockClipboard();

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      mockClipboard.handleMethodCall,
    );
    // Fill the clipboard so that the Paste option is available in the text
    // selection menu.
    await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));
  });

  testWidgetsWithLeakTracking('Builds the right toolbar on each platform, including web, and shows buttonItems', (WidgetTester tester) async {
    const String buttonText = 'Click me';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AdaptiveTextSelectionToolbar.buttonItems(
              anchors: const TextSelectionToolbarAnchors(
                primaryAnchor: Offset.zero,
              ),
              buttonItems: <ContextMenuButtonItem>[
                ContextMenuButtonItem(
                  label: buttonText,
                  onPressed: () {
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text(buttonText), findsOneWidget);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        expect(find.byType(TextSelectionToolbar), findsOneWidget);
        expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
      case TargetPlatform.iOS:
        expect(find.byType(TextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbar), findsOneWidget);
        expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
      case TargetPlatform.macOS:
        expect(find.byType(TextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsOneWidget);
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(find.byType(TextSelectionToolbar), findsNothing);
        expect(find.byType(CupertinoTextSelectionToolbar), findsNothing);
        expect(find.byType(DesktopTextSelectionToolbar), findsOneWidget);
        expect(find.byType(CupertinoDesktopTextSelectionToolbar), findsNothing);
    }
  },
    variant: TargetPlatformVariant.all(),
    skip: isBrowser, // [intended] see https://github.com/flutter/flutter/issues/108382
  );

  testWidgetsWithLeakTracking('Can build children directly as well', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AdaptiveTextSelectionToolbar(
              anchors: const TextSelectionToolbarAnchors(
                primaryAnchor: Offset.zero,
              ),
              children: <Widget>[
                Container(key: key),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(key), findsOneWidget);
  });

  testWidgetsWithLeakTracking('Can build from EditableTextState', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: EditableText(
                controller: TextEditingController(),
                backgroundCursorColor: const Color(0xff00ffff),
                focusNode: FocusNode(),
                style: const TextStyle(),
                cursorColor: const Color(0xff00ffff),
                selectionControls: materialTextSelectionHandleControls,
                contextMenuBuilder: (
                  BuildContext context,
                  EditableTextState editableTextState,
                ) {
                  return AdaptiveTextSelectionToolbar.editableText(
                    key: key,
                    editableTextState: editableTextState,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(); // Wait for autofocus to take effect.

    expect(find.byKey(key), findsNothing);

    // Long-press to bring up the context menu.
    final Finder textFinder = find.byType(EditableText);
    await tester.longPress(textFinder);
    tester.state<EditableTextState>(textFinder).showToolbar();
    await tester.pumpAndSettle();

    expect(find.byKey(key), findsOneWidget);
    expect(find.text('Copy'), findsNothing);
    expect(find.text('Cut'), findsNothing);
    expect(find.text('Select all'), findsNothing);
    expect(find.text('Paste'), findsOneWidget);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(find.byType(TextSelectionToolbarTextButton), findsOneWidget);
      case TargetPlatform.iOS:
        expect(find.byType(CupertinoTextSelectionToolbarButton), findsOneWidget);
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(find.byType(DesktopTextSelectionToolbarButton), findsOneWidget);
      case TargetPlatform.macOS:
        expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsOneWidget);
    }
  },
    skip: kIsWeb, // [intended] on web the browser handles the context menu.
    variant: TargetPlatformVariant.all(),
  );

  testWidgetsWithLeakTracking('Can build for editable text from raw parameters', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AdaptiveTextSelectionToolbar.editable(
              key: key,
              anchors: const TextSelectionToolbarAnchors(
                primaryAnchor: Offset.zero,
              ),
              clipboardStatus: ClipboardStatus.pasteable,
              onCopy: () {},
              onCut: () {},
              onPaste: () {},
              onSelectAll: () {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(key), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Cut'), findsOneWidget);
    expect(find.text('Paste'), findsOneWidget);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        expect(find.text('Select all'), findsOneWidget);
        expect(find.byType(TextSelectionToolbarTextButton), findsNWidgets(4));
      case TargetPlatform.iOS:
        expect(find.text('Select All'), findsOneWidget);
        expect(find.byType(CupertinoTextSelectionToolbarButton), findsNWidgets(4));
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        expect(find.text('Select all'), findsOneWidget);
        expect(find.byType(DesktopTextSelectionToolbarButton), findsNWidgets(4));
      case TargetPlatform.macOS:
        expect(find.text('Select All'), findsOneWidget);
        expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNWidgets(4));
    }
  },
    skip: kIsWeb, // [intended] on web the browser handles the context menu.
    variant: TargetPlatformVariant.all(),
  );

  group('buttonItems', () {
    testWidgetsWithLeakTracking('getEditableTextButtonItems builds the correct button items per-platform', (WidgetTester tester) async {
      // Fill the clipboard so that the Paste option is available in the text
      // selection menu.
      await Clipboard.setData(const ClipboardData(text: 'Clipboard data'));

      Set<ContextMenuButtonType> buttonTypes = <ContextMenuButtonType>{};
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: EditableText(
                controller: controller,
                backgroundCursorColor: Colors.grey,
                focusNode: FocusNode(),
                style: const TextStyle(),
                cursorColor: Colors.red,
                selectionControls: materialTextSelectionHandleControls,
                contextMenuBuilder: (
                  BuildContext context,
                  EditableTextState editableTextState,
                ) {
                  buttonTypes = editableTextState.contextMenuButtonItems
                    .map((ContextMenuButtonItem buttonItem) => buttonItem.type)
                    .toSet();
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      final EditableTextState state =
          tester.state<EditableTextState>(find.byType(EditableText));

      // With no text in the field.
      await tester.tapAt(textOffsetToPosition(tester, 0));
      await tester.pump();
      expect(state.showToolbar(), true);
      await tester.pump();

      expect(buttonTypes, isNot(contains(ContextMenuButtonType.cut)));
      expect(buttonTypes, isNot(contains(ContextMenuButtonType.copy)));
      expect(buttonTypes, contains(ContextMenuButtonType.paste));
      expect(buttonTypes, isNot(contains(ContextMenuButtonType.selectAll)));

      // With text but no selection.
      controller.text = 'lorem ipsum';
      await tester.pump();

      expect(buttonTypes, isNot(contains(ContextMenuButtonType.cut)));
      expect(buttonTypes, isNot(contains(ContextMenuButtonType.copy)));
      expect(buttonTypes, contains(ContextMenuButtonType.paste));

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(buttonTypes, contains(ContextMenuButtonType.selectAll));
        case TargetPlatform.macOS:
          expect(buttonTypes, isNot(contains(ContextMenuButtonType.selectAll)));
      }

      // With text and selection.
      controller.value = controller.value.copyWith(
        selection: const TextSelection(
          baseOffset: 0,
          extentOffset: 'lorem'.length,
        ),
      );
      await tester.pump();

      expect(buttonTypes, contains(ContextMenuButtonType.cut));
      expect(buttonTypes, contains(ContextMenuButtonType.copy));
      expect(buttonTypes, contains(ContextMenuButtonType.paste));

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(buttonTypes, contains(ContextMenuButtonType.selectAll));
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          expect(buttonTypes, isNot(contains(ContextMenuButtonType.selectAll)));
      }
    },
      variant: TargetPlatformVariant.all(),
      skip: kIsWeb, // [intended]
    );

    testWidgetsWithLeakTracking('getAdaptiveButtons builds the correct button widgets per-platform', (WidgetTester tester) async {
      const String buttonText = 'Click me';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Builder(
                builder: (BuildContext context) {
                  final List<ContextMenuButtonItem> buttonItems = <ContextMenuButtonItem>[
                    ContextMenuButtonItem(
                      label: buttonText,
                      onPressed: () {
                      },
                    ),
                  ];
                  return ListView(
                    children: AdaptiveTextSelectionToolbar.getAdaptiveButtons(
                      context,
                      buttonItems,
                    ).toList(),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text(buttonText), findsOneWidget);

      switch (defaultTargetPlatform) {
        case TargetPlatform.fuchsia:
        case TargetPlatform.android:
          expect(find.byType(TextSelectionToolbarTextButton), findsOneWidget);
          expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
          expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);
          expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
        case TargetPlatform.iOS:
          expect(find.byType(TextSelectionToolbarTextButton), findsNothing);
          expect(find.byType(CupertinoTextSelectionToolbarButton), findsOneWidget);
          expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);
          expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
        case TargetPlatform.macOS:
          expect(find.byType(TextSelectionToolbarTextButton), findsNothing);
          expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
          expect(find.byType(DesktopTextSelectionToolbarButton), findsNothing);
          expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsOneWidget);
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          expect(find.byType(TextSelectionToolbarTextButton), findsNothing);
          expect(find.byType(CupertinoTextSelectionToolbarButton), findsNothing);
          expect(find.byType(DesktopTextSelectionToolbarButton), findsOneWidget);
          expect(find.byType(CupertinoDesktopTextSelectionToolbarButton), findsNothing);
      }
    },
      variant: TargetPlatformVariant.all(),
    );
  });
}
