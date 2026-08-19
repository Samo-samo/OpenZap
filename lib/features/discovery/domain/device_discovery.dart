import 'discovered_device.dart';

/// Contract for discovering compatible devices on the local network.
///
/// Concrete implementations are provided by TV-brand integrations and are
/// free to combine strategies (broadcast, multicast, mDNS, ...) as needed.
abstract class DeviceDiscovery {
  /// Runs one discovery pass and yields devices as they are found.
  ///
  /// [onProgress], when given, reports how many of the total candidate hosts
  /// have been scanned so far, allowing the UI to show scan progress.
  Stream<DiscoveredDevice> discover({
    void Function(int scanned, int total)? onProgress,
  });
}
