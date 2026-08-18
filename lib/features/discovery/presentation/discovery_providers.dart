import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/discovered_device.dart';

/// Runs discovery passes and holds the latest results.
///
/// Starts empty; the user triggers a scan through [refresh], which avoids
/// scanning the whole subnet on every app launch.
class DeviceDiscoveryNotifier extends AsyncNotifier<List<DiscoveredDevice>> {
  @override
  Future<List<DiscoveredDevice>> build() async => const [];

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final discovery = ref.read(deviceDiscoveryProvider);
      return discovery.discover().toList();
    });
  }
}

final deviceListProvider =
    AsyncNotifierProvider<DeviceDiscoveryNotifier, List<DiscoveredDevice>>(
  DeviceDiscoveryNotifier.new,
);