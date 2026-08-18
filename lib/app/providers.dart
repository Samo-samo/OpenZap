import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/device_settings/data/shared_preferences_device_store.dart';
import '../features/device_settings/domain/device_store.dart';
import '../features/discovery/domain/device_discovery.dart';
import '../features/discovery/domain/discovered_device.dart';
import '../features/remote_control/domain/remote_control.dart';
import '../features/settings/data/shared_preferences_settings_store.dart';
import '../features/settings/domain/settings_store.dart';
import '../features/tv_status/domain/tv_status.dart';
import '../features/tv_status/domain/tv_status_service.dart';
import '../integrations/vestel/vestel_device_discovery.dart';
import '../integrations/vestel/vestel_remote_control.dart';
import '../integrations/vestel/vestel_tv_status.dart';

/// Central dependency registration for TV-brand integrations.
///
/// Integrations implement domain-layer contracts only; the rest of the app
/// depends on the abstract [DeviceDiscovery] / [RemoteControl] /
/// [TvStatusService] interfaces.
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

/// Persistence for the last controlled TV.
final deviceStoreProvider = Provider<DeviceStore>(
  (ref) => SharedPreferencesDeviceStore(),
);

/// Persistence for user settings.
final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SharedPreferencesSettingsStore(),
);

/// The device last controlled across app launches, if any.
final lastDeviceProvider = FutureProvider<DiscoveredDevice?>(
  (ref) => ref.watch(deviceStoreProvider).loadLastDevice(),
);

/// Live status of the selected TV, or `null` when none is selected.
final tvStatusProvider = StreamProvider.autoDispose<TvStatus?>((ref) {
  final device = ref.watch(selectedDeviceProvider);
  if (device == null) {
    return Stream.value(null);
  }
  final service = VestelTvStatus(host: device.ipAddress);
  ref.onDispose(() => service.close());
  return service.watch();
});