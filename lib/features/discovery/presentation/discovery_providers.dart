import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/discovered_device.dart';

/// Live scan progress (`scanned`/`total` candidate hosts), set while a
/// discovery pass is running.
final scanProgressProvider =
    StateProvider<({int scanned, int total})?>((ref) => null);

/// Runs discovery passes and holds the latest results.
///
/// Starts empty; the user triggers a scan through [refresh], which avoids
/// scanning the whole subnet on every app launch.
class DeviceDiscoveryNotifier extends AsyncNotifier<List<DiscoveredDevice>> {
  @override
  Future<List<DiscoveredDevice>> build() async => const [];

  Future<void> refresh() async {
    state = const AsyncLoading();
    final progress = ref.read(scanProgressProvider.notifier);
    progress.state = null;
    state = await AsyncValue.guard(() async {
      final discovery = ref.read(deviceDiscoveryProvider);
      return discovery
          .discover(onProgress: (scanned, total) {
            progress.state = (scanned: scanned, total: total);
          })
          .toList();
    });
    progress.state = null;
  }
}

final deviceListProvider =
    AsyncNotifierProvider<DeviceDiscoveryNotifier, List<DiscoveredDevice>>(
  DeviceDiscoveryNotifier.new,
);