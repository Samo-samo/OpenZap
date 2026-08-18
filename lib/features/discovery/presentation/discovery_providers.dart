import 'dart:async';

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
/// scanning the whole subnet on every app launch. A running scan can be
/// aborted with [cancelScan].
class DeviceDiscoveryNotifier extends AsyncNotifier<List<DiscoveredDevice>> {
  StreamSubscription<DiscoveredDevice>? _subscription;

  @override
  Future<List<DiscoveredDevice>> build() async => const [];

  Future<void> refresh() async {
    await _subscription?.cancel();
    state = const AsyncLoading();
    final progress = ref.read(scanProgressProvider.notifier);
    progress.state = null;
    final results = <DiscoveredDevice>[];
    final discovery = ref.read(deviceDiscoveryProvider);
    _subscription = discovery
        .discover(onProgress: (scanned, total) {
          progress.state = (scanned: scanned, total: total);
        })
        .listen(
          results.add,
          onError: (Object error, StackTrace stackTrace) {
            progress.state = null;
            state = AsyncError(error, stackTrace);
          },
          onDone: () {
            progress.state = null;
            state = AsyncData(List.unmodifiable(results));
          },
          cancelOnError: true,
        );
  }

  Future<void> cancelScan() async {
    await _subscription?.cancel();
    _subscription = null;
    ref.read(scanProgressProvider.notifier).state = null;
    state = AsyncData(const []);
  }
}

final deviceListProvider =
    AsyncNotifierProvider<DeviceDiscoveryNotifier, List<DiscoveredDevice>>(
  DeviceDiscoveryNotifier.new,
);