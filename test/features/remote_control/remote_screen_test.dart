import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openzap/app/providers.dart';
import 'package:openzap/features/discovery/domain/discovered_device.dart';
import 'package:openzap/features/remote_control/domain/remote_key.dart';
import 'package:openzap/features/remote_control/domain/remote_layout.dart';
import 'package:openzap/features/remote_control/presentation/layout_editor_screen.dart';
import 'package:openzap/features/remote_control/presentation/remote_screen.dart';
import 'package:openzap/l10n/app_localizations.dart';

void main() {
  final device = DiscoveredDevice(
    name: 'Salon TV',
    ipAddress: '192.168.0.101',
    port: 56789,
    manufacturer: 'Vestel',
  );

  /// Builds the prefs payload for one saved layout containing [items].
  Map<String, Object> layoutPrefs({
    required List<LayoutItem> items,
    String id = 'l1',
    String name = 'Salon',
    bool active = true,
  }) {
    final gridJson = jsonEncode(FreeRemoteLayout(items).toJson());
    return {
      'custom_layouts_v1': jsonEncode([
        SavedRemoteLayout(id: id, name: name, gridJson: gridJson).toJson(),
      ]),
      if (active) 'active_custom_layout_id': id,
    };
  }

  Widget wrap({TargetPlatform? platform}) => ProviderScope(
    overrides: [selectedDeviceProvider.overrideWith((ref) => device)],
    child: MaterialApp(
      theme: platform == null ? null : ThemeData(platform: platform),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const RemoteScreen(),
    ),
  );

  testWidgets('classic layout shows the quick controls', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Settings'), findsOneWidget);
    expect(find.byTooltip('Picture format'), findsOneWidget);
    expect(find.byTooltip('Subtitles'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('hides the quick controls when disabled in settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'show_extras': false});
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Settings'), findsNothing);
    expect(find.byTooltip('Picture format'), findsNothing);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('minimal preset hides digits, extras and sleep timer', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'show_tv_status': false,
      'show_digits': false,
      'show_sleep_timer': false,
      'show_extras': false,
    });
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNothing);
    expect(find.byTooltip('Settings'), findsNothing);
    expect(find.byTooltip('Sleep timer'), findsNothing);
    expect(find.byTooltip('Power'), findsOneWidget);
  });

  testWidgets('active custom layout renders the saved grid', (tester) async {
    SharedPreferences.setMockInitialValues(
      layoutPrefs(
        items: [
          LayoutItem.key(remoteKey: RemoteKey.power, x: 8, y: 8),
          LayoutItem.block(block: LayoutBlock.sleepTimer, x: 8, y: 80),
        ],
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Power'), findsOneWidget);
    // Only the placed items are rendered: no digit keys from the sections.
    expect(find.text('0'), findsNothing);
    expect(find.byTooltip('Picture format'), findsNothing);
  });

  testWidgets('more menu offers presets, layouts and management', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Classic'), findsOneWidget);
    expect(find.text('Compact'), findsOneWidget);
    expect(find.text('Minimal'), findsOneWidget);
    expect(find.text('New layout'), findsOneWidget);
    expect(find.text('Manage layouts'), findsOneWidget);
    expect(find.text('Apps'), findsOneWidget);
    expect(find.text('Key test'), findsOneWidget);
  });

  testWidgets('saved layouts appear in the menu and activate', (tester) async {
    SharedPreferences.setMockInitialValues(
      layoutPrefs(items: const [], active: false),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    expect(find.text('Salon'), findsOneWidget);

    await tester.tap(find.text('Salon'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('active_custom_layout_id'), 'l1');
  });

  testWidgets('create layout opens the editor with a template', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New layout'));
    await tester.pumpAndSettle();

    expect(find.byType(LayoutEditorScreen), findsOneWidget);
    // Default template content: power button tooltip is present in the
    // editor preview as well.
    expect(find.text('Custom 1'), findsOneWidget);
  });

  testWidgets('editor undo removes a palette-added tile', (tester) async {
    SharedPreferences.setMockInitialValues(
      layoutPrefs(
        items: [LayoutItem.key(remoteKey: RemoteKey.power, x: 8, y: 8)],
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage layouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit layout').first);
    await tester.pumpAndSettle();

    IconButton toolbarButton(IconData icon) =>
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, icon));
    expect(toolbarButton(Icons.undo).onPressed, isNull);

    // Add a mute tile from the palette.
    await tester.tap(find.byTooltip('Add buttons'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mute').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mute'), findsOneWidget);
    expect(toolbarButton(Icons.undo).onPressed, isNotNull);

    await tester.tap(find.byTooltip('Undo'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mute'), findsNothing);

    await tester.tap(find.byTooltip('Redo'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mute'), findsOneWidget);
  });

  testWidgets('editor toolbar toggles default to on', (tester) async {
    SharedPreferences.setMockInitialValues(
      layoutPrefs(
        items: [LayoutItem.key(remoteKey: RemoteKey.power, x: 8, y: 8)],
      ),
    );
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage layouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit layout').first);
    await tester.pumpAndSettle();

    FilterChip chip(String label) => tester.widget<FilterChip>(
      find.ancestor(of: find.text(label), matching: find.byType(FilterChip)),
    );
    expect(chip('Keep ratio').selected, isTrue);
    expect(chip('Snap').selected, isTrue);

    await tester.tap(find.text('Snap'));
    await tester.pumpAndSettle();
    expect(chip('Snap').selected, isFalse);
  });

  testWidgets('editor corner badges appear on selection', (tester) async {
    // The resize badge is desktop-only.
    SharedPreferences.setMockInitialValues(
      layoutPrefs(
        items: [LayoutItem.key(remoteKey: RemoteKey.power, x: 8, y: 8)],
      ),
    );
    await tester.pumpWidget(wrap(platform: TargetPlatform.windows));
    await tester.pumpAndSettle();

    // Open the editor through the management sheet.
    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage layouts'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Edit layout').first);
    await tester.pumpAndSettle();

    // Tap the power tile to select it; both corner badges show up.
    await tester.tap(find.byTooltip('Power').last);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Resize'), findsOneWidget);
    expect(find.byTooltip('Remove'), findsOneWidget);
  });
}
