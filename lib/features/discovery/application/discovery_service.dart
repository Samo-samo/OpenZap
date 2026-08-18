import 'dart:async';

import '../domain/device_discovery.dart';
import '../domain/discovered_device.dart';
import '../domain/discovery_error.dart';

/// Orchestrates discovery strategies and aggregates their results.
///
/// All strategies run concurrently. Devices are deduplicated by IP address,
/// and a failing strategy is reported through [onError] without stopping the
/// remaining strategies.
class DiscoveryService {
  DiscoveryService({required List<DeviceDiscovery> strategies})
      : _strategies = List.unmodifiable(strategies);

  final List<DeviceDiscovery> _strategies;

  Stream<DiscoveredDevice> discover({
    void Function(DiscoveryError error)? onError,
  }) async* {
    if (_strategies.isEmpty) {
      return;
    }

    final controller = StreamController<DiscoveredDevice>();
    final seen = <String>{};
    var pending = _strategies.length;

    void onDevice(DiscoveredDevice device) {
      if (seen.add(device.ipAddress)) {
        controller.add(device);
      }
    }

    void onFailure(Object error, StackTrace stackTrace) {
      onError?.call(
        error is DiscoveryError
            ? error
            : DiscoveryError('Discovery strategy failed.', cause: error),
      );
    }

    void onDone() {
      pending--;
      if (pending == 0) {
        controller.close();
      }
    }

    for (final strategy in _strategies) {
      strategy.discover().listen(onDevice, onError: onFailure, onDone: onDone);
    }

    await for (final device in controller.stream) {
      yield device;
    }
  }
}