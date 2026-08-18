import 'package:flutter_test/flutter_test.dart';

import 'package:openzap/features/discovery/application/discovery_service.dart';
import 'package:openzap/features/discovery/domain/device_discovery.dart';
import 'package:openzap/features/discovery/domain/discovered_device.dart';
import 'package:openzap/features/discovery/domain/discovery_error.dart';

class _FakeDiscovery implements DeviceDiscovery {
  _FakeDiscovery(this.devices, {this.error});

  final List<DiscoveredDevice> devices;
  final DiscoveryError? error;

  @override
  Stream<DiscoveredDevice> discover({
    void Function(int scanned, int total)? onProgress,
  }) async* {
    if (error != null) {
      throw error!;
    }
    for (final device in devices) {
      yield device;
    }
  }
}

DiscoveredDevice _device(String ipAddress, {String name = 'TV'}) {
  return DiscoveredDevice(name: name, ipAddress: ipAddress, port: 4567);
}

void main() {
  group('DiscoveryService', () {
    test('yields devices from all strategies', () async {
      final service = DiscoveryService(strategies: [
        _FakeDiscovery([_device('192.168.1.10')]),
        _FakeDiscovery([_device('192.168.1.11')]),
      ]);

      final devices = await service.discover().toList();

      expect(devices.map((d) => d.ipAddress), ['192.168.1.10', '192.168.1.11']);
    });

    test('deduplicates devices by IP address', () async {
      final service = DiscoveryService(strategies: [
        _FakeDiscovery([_device('192.168.1.10', name: 'TV 1')]),
        _FakeDiscovery([_device('192.168.1.10', name: 'TV 2')]),
      ]);

      final devices = await service.discover().toList();

      expect(devices, hasLength(1));
      expect(devices.single.ipAddress, '192.168.1.10');
    });

    test('reports strategy failures without stopping the others', () async {
      final reported = <DiscoveryError>[];
      final service = DiscoveryService(strategies: [
        _FakeDiscovery([], error: const DiscoveryError('boom')),
        _FakeDiscovery([_device('192.168.1.10')]),
      ]);

      final devices =
          await service.discover(onError: reported.add).toList();

      expect(reported, hasLength(1));
      expect(devices, hasLength(1));
      expect(devices.single.ipAddress, '192.168.1.10');
    });

    test('yields nothing when there are no strategies', () async {
      final service = DiscoveryService(strategies: []);

      final devices = await service.discover().toList();

      expect(devices, isEmpty);
    });
  });
}