import 'dart:io';

import '../../core/networking/http_probe.dart';
import '../../features/discovery/domain/device_discovery.dart';
import '../../features/discovery/domain/discovered_device.dart';

const int _deviceDescriptionPort = 56792;
const int _remoteControlPort = 56791;

/// Discovers Vestel-based TVs by probing hosts on the local subnet.
///
/// Based on observed Vestel TV behavior: a host that answers
/// `GET /dd.xml` on port 56792 is treated as a compatible device.
class VestelDeviceDiscovery implements DeviceDiscovery {
  VestelDeviceDiscovery({
    HttpProbe? probe,
    Future<List<String>> Function()? hostResolver,
    this.deviceDescriptionPort = _deviceDescriptionPort,
    this.probeTimeout = const Duration(milliseconds: 800),
    this.maxConcurrency = 30,
  })  : _probe = probe ?? DartHttpProbe(),
        _hostResolver = hostResolver ?? _resolveCandidateHosts;

  final HttpProbe _probe;
  final Future<List<String>> Function() _hostResolver;
  final int deviceDescriptionPort;
  final Duration probeTimeout;
  final int maxConcurrency;

  @override
  Stream<DiscoveredDevice> discover() async* {
    final hosts = await _hostResolver();
    final bodies = await _probeAll(hosts);
    for (var i = 0; i < hosts.length; i++) {
      final body = bodies[i];
      if (body != null) {
        yield _deviceFor(hosts[i], body);
      }
    }
  }

  Future<void> close() => _probe.close();

  Future<List<String?>> _probeAll(List<String> hosts) async {
    if (hosts.isEmpty) {
      return const [];
    }
    final results = List<String?>.filled(hosts.length, null);
    var next = 0;
    final workers = maxConcurrency < 1 ? 1 : maxConcurrency;
    final count = workers > hosts.length ? hosts.length : workers;
    await Future.wait(List.generate(count, (_) async {
      while (true) {
        final index = next++;
        if (index >= hosts.length) {
          return;
        }
        results[index] = await _probe.get(
          'http://${hosts[index]}:$deviceDescriptionPort/dd.xml',
          timeout: probeTimeout,
        );
      }
    }));
    return results;
  }

  DiscoveredDevice _deviceFor(String host, String body) {
    return DiscoveredDevice(
      name: _extractTag('<friendlyName>', body) ?? host,
      ipAddress: host,
      port: _remoteControlPort,
      manufacturer: 'Vestel',
      model: _extractTag('<modelName>', body),
    );
  }

  static String? _extractTag(String tag, String xml) {
    final match = RegExp('$tag([^<]+)</').firstMatch(xml);
    return match?.group(1)?.trim();
  }
}

Future<List<String>> _resolveCandidateHosts() async {
  final hosts = <String>{};
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  for (final interface in interfaces) {
    for (final address in interface.addresses) {
      hosts.addAll(hostsFor(address));
    }
  }
  return hosts.toList();
}

/// Computes the candidate host addresses of the assumed `/24` subnet that
/// contains [address], excluding the network and broadcast addresses.
///
/// The OS does not expose the interface netmask on this SDK, so discovery
/// assumes a `/24` network, which covers typical home LANs. Returns an empty
/// list for addresses outside the private ranges, since scanning public
/// networks is out of scope.
List<String> hostsFor(InternetAddress address) {
  final raw = address.rawAddress;
  if (raw.length != 4 || !_isPrivate(raw)) {
    return const [];
  }
  final network = '${raw[0]}.${raw[1]}.${raw[2]}';
  return List.generate(254, (i) => '$network.${i + 1}');
}

bool _isPrivate(List<int> raw) {
  if (raw[0] == 10) {
    return true;
  }
  if (raw[0] == 172 && raw[1] >= 16 && raw[1] <= 31) {
    return true;
  }
  if (raw[0] == 192 && raw[1] == 168) {
    return true;
  }
  return false;
}