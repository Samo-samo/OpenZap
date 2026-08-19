import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:openzap/features/device_settings/data/shared_preferences_device_store.dart';
import 'package:openzap/features/discovery/domain/discovered_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesDeviceStore', () {
    test('returns null when nothing was saved', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesDeviceStore();

      expect(await store.loadLastDevice(), isNull);
    });

    test('round-trips a saved device', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesDeviceStore();
      const device = DiscoveredDevice(
        name: 'Living Room TV',
        ipAddress: '192.168.1.10',
        port: 56789,
        manufacturer: 'Vestel',
        model: 'MB180',
      );

      await store.saveLastDevice(device);
      final loaded = await store.loadLastDevice();

      expect(loaded, device);
      expect(loaded!.name, 'Living Room TV');
      expect(loaded.ipAddress, '192.168.1.10');
      expect(loaded.port, 56789);
      expect(loaded.manufacturer, 'Vestel');
      expect(loaded.model, 'MB180');
    });

    test('returns null for corrupted data', () async {
      SharedPreferences.setMockInitialValues({'last_device': 'not-json'});
      final store = SharedPreferencesDeviceStore();

      expect(await store.loadLastDevice(), isNull);
    });

    test('starts with no saved devices', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesDeviceStore();

      expect(await store.loadDevices(), isEmpty);
    });

    test('round-trips saved devices and deduplicates by IP', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesDeviceStore();
      const livingRoom = DiscoveredDevice(
        name: 'Living Room TV',
        ipAddress: '192.168.1.10',
        port: 56789,
      );
      const bedroom = DiscoveredDevice(
        name: 'Bedroom TV',
        ipAddress: '192.168.1.11',
        port: 56789,
      );

      await store.saveDevice(livingRoom);
      await store.saveDevice(bedroom);
      await store.saveDevice(
        const DiscoveredDevice(
          name: 'Living Room TV 2',
          ipAddress: '192.168.1.10',
          port: 56789,
        ),
      );

      final devices = await store.loadDevices();
      expect(devices, hasLength(2));
      expect(
        devices.map((d) => d.ipAddress),
        containsAll(['192.168.1.10', '192.168.1.11']),
      );
      final updated = devices.firstWhere((d) => d.ipAddress == '192.168.1.10');
      expect(updated.name, 'Living Room TV 2');
    });

    test('removes a saved device', () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesDeviceStore();
      const livingRoom = DiscoveredDevice(
        name: 'Living Room TV',
        ipAddress: '192.168.1.10',
        port: 56789,
      );
      const bedroom = DiscoveredDevice(
        name: 'Bedroom TV',
        ipAddress: '192.168.1.11',
        port: 56789,
      );

      await store.saveDevice(livingRoom);
      await store.saveDevice(bedroom);
      await store.removeDevice('192.168.1.10');

      final devices = await store.loadDevices();
      expect(devices, hasLength(1));
      expect(devices.single.ipAddress, '192.168.1.11');
    });
  });
}
