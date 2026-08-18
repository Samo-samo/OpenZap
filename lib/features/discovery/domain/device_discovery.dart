import 'discovered_device.dart';

/// Contract for discovering compatible devices on the local network.
///
/// Concrete implementations are provided by TV-brand integrations and are
/// free to combine strategies (broadcast, multicast, mDNS, ...) as needed.
abstract class DeviceDiscovery {
  /// Runs one discovery pass and yields devices as they are found.
  Stream<DiscoveredDevice> discover();
}