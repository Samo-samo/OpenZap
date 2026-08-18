import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/discovery/domain/device_discovery.dart';
import '../features/discovery/domain/discovered_device.dart';
import '../features/remote_control/domain/remote_control.dart';
import '../integrations/vestel/vestel_device_discovery.dart';
import '../integrations/vestel/vestel_remote_control.dart';

/// Central dependency registration for TV-brand integrations.
///
/// Integrations implement domain-layer contracts only; the rest of the app
/// depends on the abstract [DeviceDiscovery] / [RemoteControl] interfaces.
final deviceDiscoveryProvider = Provider<DeviceDiscovery>((ref) {
  final discovery = VestelDeviceDiscovery();
  ref.onDispose(() => discovery.close());
  return discovery;
});

/// The TV currently controlled by the remote screen.
final selectedDeviceProvider = StateProvider<DiscoveredDevice?>((ref) => null);

/// Remote control for the selected TV, or `null` when none is selected.
final remoteControlProvider = Provider<RemoteControl?>((ref) {
  final device = ref.watch(selectedDeviceProvider);
  if (device == null) {
    return null;
  }
  final remote = VestelRemoteControl(host: device.ipAddress, port: device.port);
  ref.onDispose(() => remote.close());
  return remote;
});