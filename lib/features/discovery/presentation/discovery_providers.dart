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
  List<DiscoveredDevice> _results = const [];

  @override
  Future<List<DiscoveredDevice>> build() async => const [];

  Future<void> refresh() async {
    await cancelScan();
    state = const AsyncLoading();
    final progress = ref.read(scanProgressProvider.notifier);
    progress.state = null;
    _results = [];
    final discovery = ref.read(deviceDiscoveryProvider);
    _subscription = discovery
        .discover(onProgress: (scanned, total) {
          progress.state = (scanned: scanned, total: total);
        })
        .listen(
          _results.add,
          onError: (Object error, StackTrace stackTrace) {
            progress.state = null;
            state = AsyncError(error, stackTrace);
          },
          onDone: () {
            progress.state = null;
            state = AsyncData(List.unmodifiable(_results));
          },
          cancelOnError: true,
        );
  }

  /// Stops a running scan, keeping any devices found so far.
  Future<void> cancelScan() async {
    await _subscription?.cancel();
    _subscription = null;
    ref.read(scanProgressProvider.notifier).state = null;
    state = AsyncData(List.unmodifiable(_results));
  }
}

final deviceListProvider =
    AsyncNotifierProvider<DeviceDiscoveryNotifier, List<DiscoveredDevice>>(
  DeviceDiscoveryNotifier.new,
);