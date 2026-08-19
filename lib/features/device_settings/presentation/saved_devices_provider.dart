import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../discovery/domain/discovered_device.dart';

/// User-managed list of known devices, backed by the persisted [DeviceStore].
class SavedDevicesNotifier extends AsyncNotifier<List<DiscoveredDevice>> {
  @override
  Future<List<DiscoveredDevice>> build() =>
      ref.watch(deviceStoreProvider).loadDevices();

  Future<void> add(DiscoveredDevice device) async {
    final store = ref.read(deviceStoreProvider);
    await store.saveDevice(device);
    state = AsyncData(await store.loadDevices());
  }

  Future<void> remove(String ipAddress) async {
    final store = ref.read(deviceStoreProvider);
    await store.removeDevice(ipAddress);
    state = AsyncData(await store.loadDevices());
  }
}

final savedDevicesProvider =
    AsyncNotifierProvider<SavedDevicesNotifier, List<DiscoveredDevice>>(
  SavedDevicesNotifier.new,
);