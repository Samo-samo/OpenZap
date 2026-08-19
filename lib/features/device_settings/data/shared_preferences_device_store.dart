import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../discovery/domain/discovered_device.dart';
import '../domain/device_store.dart';

class SharedPreferencesDeviceStore implements DeviceStore {
  static const _lastDeviceKey = 'last_device';
  static const _savedDevicesKey = 'saved_devices';

  @override
  Future<DiscoveredDevice?> loadLastDevice() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeDevice(prefs.getString(_lastDeviceKey));
  }

  @override
  Future<void> saveLastDevice(DiscoveredDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastDeviceKey, _encodeDevice(device));
  }

  @override
  Future<List<DiscoveredDevice>> loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedDevicesKey);
    if (raw == null) {
      return const [];
    }
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [for (final entry in list) ?_decodeDevice(jsonEncode(entry))];
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> saveDevice(DiscoveredDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    final devices = [
      for (final existing in await loadDevices())
        if (existing.ipAddress != device.ipAddress) existing,
      device,
    ];
    await prefs.setString(
      _savedDevicesKey,
      jsonEncode([for (final d in devices) jsonDecode(_encodeDevice(d))]),
    );
  }

  @override
  Future<void> removeDevice(String ipAddress) async {
    final prefs = await SharedPreferences.getInstance();
    final devices = [
      for (final existing in await loadDevices())
        if (existing.ipAddress != ipAddress) existing,
    ];
    await prefs.setString(
      _savedDevicesKey,
      jsonEncode([for (final d in devices) jsonDecode(_encodeDevice(d))]),
    );
  }

  static DiscoveredDevice? _decodeDevice(String? raw) {
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

  static String _encodeDevice(DiscoveredDevice device) => jsonEncode({
    'name': device.name,
    'ip': device.ipAddress,
    'port': device.port,
    'manufacturer': device.manufacturer,
    'model': device.model,
  });
}
