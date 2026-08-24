import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openzap/app/providers.dart';
import 'package:openzap/features/discovery/domain/discovered_device.dart';
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

  Widget wrap() => ProviderScope(
    overrides: [selectedDeviceProvider.overrideWith((ref) => device)],
    child: MaterialApp(
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

  testWidgets('custom layout renders the saved grid', (tester) async {
    SharedPreferences.setMockInitialValues({
      'use_custom_layout': true,
      'custom_layout_json':
          '{"version":1,"items":['
          '{"type":"key","key":"power","row":0,"column":0},'
          '{"type":"block","block":"sleepTimer","row":1,"column":0}'
          ']}',
    });
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Power'), findsOneWidget);
    // Only the placed items are rendered: no digit keys from the sections.
    expect(find.text('0'), findsNothing);
    expect(find.byTooltip('Picture format'), findsNothing);
  });

  testWidgets('more menu offers presets, editing, apps and key test', (
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
    expect(find.text('Custom'), findsOneWidget);
    expect(find.text('Edit layout'), findsOneWidget);
    expect(find.text('Apps'), findsOneWidget);
    expect(find.text('Key test'), findsOneWidget);
  });

  testWidgets('edit layout opens the layout editor', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit layout'));
    await tester.pumpAndSettle();

    expect(find.byType(LayoutEditorScreen), findsOneWidget);
    expect(find.text('Add buttons'), findsOneWidget);
  });
}
