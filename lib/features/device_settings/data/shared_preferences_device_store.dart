import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../discovery/domain/discovered_device.dart';
import '../domain/device_store.dart';

class SharedPreferencesDeviceStore implements DeviceStore {
  static const _lastDeviceKey = 'last_device';

  @override
  Future<DiscoveredDevice?> loadLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastDeviceKey);
    if (raw == null) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return DiscoveredDevice(
        name: json['name'] as String,
        ipAddress: json['ip'] as String,
        port: json['port'] as int,
        manufacturer: json['manufacturer'] as String?,
        model: json['model'] as String?,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  @override
  Future<void> saveLastDevice(DiscoveredDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastDeviceKey,
      jsonEncode({
        'name': device.name,
        'ip': device.ipAddress,
        'port': device.port,
        'manufacturer': device.manufacturer,
        'model': device.model,
      }),
    );
  }
}