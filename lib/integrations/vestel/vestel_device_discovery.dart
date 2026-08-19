import 'dart:io';

import '../../core/networking/http_probe.dart';
import '../../features/discovery/domain/device_discovery.dart';
import '../../features/discovery/domain/discovered_device.dart';

const List<int> _deviceDescriptionPorts = [56790, 56792];
const int _remoteControlPort = 56789;
const int _maxScannedHosts = 1024;

const List<String> _virtualAdapterKeywords = [
  'wsl',
  'vmware',
  'vmnet',
  'virtualbox',
  'vbox',
  'hyper-v',
  'docker',
  'radmin',
  'tailscale',
  'zerotier',
  'wireguard',
  'loopback',
  'vEthernet',
  'virtual ethernet',
  'host-only',
  'hostonly',
];

/// Discovers Vestel-based TVs by probing hosts on the local network.
///
/// Based on observed Vestel TV behavior: a host that answers
/// `GET /dd.xml` on one of the known device-description ports is treated as
/// a compatible device. The port varies by model generation (e.g. 56790 on
/// MB180, 56792 on older models), so several ports are probed per host.
///
/// By default the candidates are derived from the subnet of the interface
/// that owns the default route (the LAN the TV lives on), so virtual-adapter
/// subnets (Hyper-V, VirtualBox, VMware, VPNs, ...) are not scanned. If the
/// route cannot be read, all non-virtual interfaces are used instead. Pass
/// [subnets] to scan specific subnet prefixes (e.g. when the TV sits on a
/// different subnet); this is the hook that will later back a user-facing
/// setting.
class VestelDeviceDiscovery implements DeviceDiscovery {
  VestelDeviceDiscovery({
    HttpProbe? probe,
    List<String>? subnets,
    Future<List<String>> Function()? hostResolver,
    this.deviceDescriptionPorts = _deviceDescriptionPorts,
    this.probeTimeout = const Duration(milliseconds: 500),
    this.maxConcurrency = 30,
  })  : _probe = probe ?? DartHttpProbe(),
        _hostResolver = hostResolver ??
            (subnets != null ? () => _hostsFromSubnets(subnets) : _resolveCandidateHosts);

  final HttpProbe _probe;
  final Future<List<String>> Function() _hostResolver;
  final List<int> deviceDescriptionPorts;
  final Duration probeTimeout;
  final int maxConcurrency;

  @override
  Stream<DiscoveredDevice> discover({
    void Function(int scanned, int total)? onProgress,
  }) async* {
    final hosts = await _hostResolver();
    onProgress?.call(0, hosts.length);
    var scanned = 0;
    final batchSize = maxConcurrency < 1 ? 1 : maxConcurrency;
    // Probing is done in batches so that cancelling the stream subscription
    // (the UI's "Cancel" button) stops the scan after the current batch
    // instead of after all hosts. Progress is reported per host so the UI
    // advances smoothly instead of jumping in batch-sized steps.
    for (var i = 0; i < hosts.length; i += batchSize) {
      final end = i + batchSize > hosts.length ? hosts.length : i + batchSize;
      final batch = hosts.sublist(i, end);
      final bodies = await Future.wait([
        for (final host in batch) _probeHost(host, () {
          scanned++;
          onProgress?.call(scanned, hosts.length);
        }),
      ]);
      for (var j = 0; j < batch.length; j++) {
        final body = bodies[j];
        if (body != null) {
          yield _deviceFor(batch[j], body);
        }
      }
    }
  }

  Future<void> close() => _probe.close();

  Future<String?> _probeHost(String host, void Function() onComplete) async {
    final bodies = await Future.wait([
      for (final port in deviceDescriptionPorts)
        _probe.get('http://$host:$port/dd.xml', timeout: probeTimeout),
    ]);
    onComplete();
    for (final body in bodies) {
      if (body != null) {
        return body;
      }
    }
    return null;
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
  // The default-route trick relies on `route print`, which only exists on
  // Windows. On other platforms (e.g. Android) enumerate the interfaces
  // directly; a phone's WiFi adapter is the relevant one.
  if (Platform.isWindows) {
    final defaultRouteHosts = await _defaultRouteSubnetHosts();
    if (defaultRouteHosts != null) {
      return defaultRouteHosts;
    }
  }
  final hosts = <String>{};
  final interfaces = await NetworkInterface.list(
    type: InternetAddressType.IPv4,
    includeLoopback: false,
  );
  for (final interface in interfaces) {
    if (_isVirtualAdapter(interface)) {
      continue;
    }
    for (final address in interface.addresses) {
      hosts.addAll(hostsFor(address));
    }
  }
  if (hosts.length > _maxScannedHosts) {
    return hosts.take(_maxScannedHosts).toList();
  }
  return hosts.toList();
}

/// Returns the candidate hosts of the subnet that owns the default route,
/// or `null` when the routing table cannot be read.
///
/// Reading the table (`route print` on Windows) lets discovery skip the
/// subnets of virtual adapters entirely, scanning only the LAN the TV
/// actually sits on.
Future<List<String>?> _defaultRouteSubnetHosts() async {
  final interfaceAddress = await _defaultRouteInterfaceAddress();
  if (interfaceAddress == null) {
    return null;
  }
  final address = InternetAddress.tryParse(interfaceAddress);
  if (address == null) {
    return null;
  }
  final hosts = hostsFor(address);
  return hosts.isEmpty ? null : hosts;
}

Future<String?> _defaultRouteInterfaceAddress() async {
  try {
    final result = await Process.run('route', ['print', '-4']);
    if (result.exitCode != 0) {
      return null;
    }
    final lines = (result.stdout as String).split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('0.0.0.0 ')) {
        continue;
      }
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length < 4) {
        continue;
      }
      final address = InternetAddress.tryParse(parts[3]);
      if (address != null && _isPrivate(address.rawAddress)) {
        return parts[3];
      }
    }
  } on ProcessException {
    return null;
  }
  return null;
}

/// Returns `true` for virtual adapters (Hyper-V, VirtualBox, VMware, WSL,
/// VPNs, ...) whose subnets are irrelevant to TV discovery.
///
/// The check runs on the adapter name, which is the only reliable metadata
/// exposed by the SDK.
bool _isVirtualAdapter(NetworkInterface interface) {
  final name = interface.name.toLowerCase();
  return _virtualAdapterKeywords.any(name.contains);
}

Future<List<String>> _hostsFromSubnets(List<String> subnets) async {
  final hosts = <String>{};
  for (final subnet in subnets) {
    hosts.addAll(hostsForPrefix(subnet));
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
  return hostsForPrefix('${raw[0]}.${raw[1]}.${raw[2]}');
}

/// Computes the candidate hosts `x.y.z.1` through `x.y.z.254` for the given
/// [subnetPrefix] (three octets, e.g. `192.168.0`).
List<String> hostsForPrefix(String subnetPrefix) {
  final parts = subnetPrefix.split('.');
  if (parts.length != 3) {
    throw ArgumentError.value(
      subnetPrefix,
      'subnet',
      'Expected a three-octet prefix such as 192.168.0.',
    );
  }
  final network = parts.join('.');
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