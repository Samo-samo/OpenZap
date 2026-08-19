import '../../discovery/domain/discovered_device.dart';

/// Persists devices across launches: the last controlled device plus a
/// user-managed list of known devices.
abstract class DeviceStore {
  /// Returns the last controlled device, or `null` if none was saved.
  Future<DiscoveredDevice?> loadLastDevice();

  /// Remembers [device] as the last controlled device.
  Future<void> saveLastDevice(DiscoveredDevice device);

  /// Returns all user-saved devices.
  Future<List<DiscoveredDevice>> loadDevices();

  /// Adds [device] to the saved list, replacing any entry with the same IP.
  Future<void> saveDevice(DiscoveredDevice device);

  /// Removes the saved device with [ipAddress], if present.
  Future<void> removeDevice(String ipAddress);
}
