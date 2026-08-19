import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openzap/features/discovery/domain/discovered_device.dart';
import 'package:openzap/features/discovery/presentation/device_list_screen.dart';
import 'package:openzap/features/discovery/presentation/discovery_providers.dart';
import 'package:openzap/l10n/app_localizations.dart';

class _FixedDeviceList extends DeviceDiscoveryNotifier {
  _FixedDeviceList(this.devices);

  final List<DiscoveredDevice> devices;

  @override
  Future<List<DiscoveredDevice>> build() async => devices;
}

void main() {
  final device = DiscoveredDevice(
    name: 'Salon TV',
    ipAddress: '192.168.0.101',
    port: 56789,
    manufacturer: 'Vestel',
  );

  Widget wrap() => ProviderScope(
    overrides: [
      deviceListProvider.overrideWith(() => _FixedDeviceList([device])),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const DeviceListScreen(),
    ),
  );

  testWidgets('long press offers save, then rename and remove', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(find.text('Save device'), findsOneWidget);

    await tester.tap(find.text('Save device'));
    await tester.pumpAndSettle();
    expect(find.text('Device saved'), findsOneWidget);

    await tester.longPress(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Remove'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.text('Device removed'), findsOneWidget);
  });

  testWidgets('rename updates the saved device name', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(ListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save device'));
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(ListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Living Room TV');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Device renamed'), findsOneWidget);
    expect(find.text('Living Room TV'), findsOneWidget);
  });
}
