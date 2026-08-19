import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openzap/app/providers.dart';
import 'package:openzap/features/discovery/domain/discovered_device.dart';
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
}
