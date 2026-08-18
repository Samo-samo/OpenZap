import '../../discovery/domain/discovered_device.dart';

/// Persists the last controlled device so it can be reused across launches.
abstract class DeviceStore {
  /// Returns the last controlled device, or `null` if none was saved.
  Future<DiscoveredDevice?> loadLastDevice();

  /// Remembers [device] as the last controlled device.
  Future<void> saveLastDevice(DiscoveredDevice device);
}