import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:openzap/core/networking/http_probe.dart';
import 'package:openzap/integrations/vestel/vestel_device_discovery.dart';

class _FakeProbe implements HttpProbe {
  _FakeProbe(this.responses);

  final Map<String, String?> responses;
  final List<String> requestedUrls = [];

  @override
  Future<String?> get(String url, {required Duration timeout}) async {
    requestedUrls.add(url);
    return responses[Uri.parse(url).host];
  }

  @override
  Future<String?> post(
    String url, {
    required String body,
    Map<String, String>? headers,
    required Duration timeout,
  }) async {
    requestedUrls.add(url);
    return responses[Uri.parse(url).host];
  }

  @override
  Future<void> close() async {}
}

const _ddXml = '''
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <friendlyName>Living Room TV</friendlyName>
    <modelName>17MB95</modelName>
  </device>
</root>
''';

VestelDeviceDiscovery _discovery(
  _FakeProbe probe,
  List<String> hosts,
) {
  return VestelDeviceDiscovery(
    probe: probe,
    hostResolver: () async => hosts,
  );
}

void main() {
  group('VestelDeviceDiscovery', () {
    test('yields devices for responding hosts', () async {
      final probe = _FakeProbe({
        '192.168.1.10': _ddXml,
        '192.168.1.11': null,
      });
      final discovery = _discovery(probe, ['192.168.1.10', '192.168.1.11']);

      final devices = await discovery.discover().toList();

      expect(devices, hasLength(1));
      final device = devices.single;
      expect(device.ipAddress, '192.168.1.10');
      expect(device.name, 'Living Room TV');
      expect(device.model, '17MB95');
      expect(device.manufacturer, 'Vestel');
      expect(device.port, 56789);
    });

    test('uses the host address as name when there is no friendlyName',
        () async {
      final probe = _FakeProbe({
        '192.168.1.10': '<?xml version="1.0"?><root/>',
      });
      final discovery = _discovery(probe, ['192.168.1.10']);

      final devices = await discovery.discover().toList();

      expect(devices.single.name, '192.168.1.10');
    });

    test('probes every candidate host on every known port', () async {
      final probe = _FakeProbe({});
      final discovery = _discovery(probe, ['192.168.1.10', '192.168.1.11']);

      await discovery.discover().toList();

      expect(probe.requestedUrls, hasLength(4));
      expect(probe.requestedUrls[0], contains('192.168.1.10'));
      expect(probe.requestedUrls[2], contains('192.168.1.11'));
      expect(probe.requestedUrls, everyElement(contains('/dd.xml')));
    });

    test('yields nothing when there are no candidate hosts', () async {
      final probe = _FakeProbe({});
      final discovery = _discovery(probe, []);

      final devices = await discovery.discover().toList();

      expect(devices, isEmpty);
    });

    test('scans the configured subnets when given', () async {
      final probe = _FakeProbe({});
      final discovery = VestelDeviceDiscovery(
        probe: probe,
        subnets: ['192.168.0', '192.168.1'],
      );

      final devices = await discovery.discover().toList();
      await discovery.close();

      expect(devices, isEmpty);
      expect(probe.requestedUrls, hasLength(1016));
      expect(probe.requestedUrls, contains(contains('192.168.0.1')));
      expect(probe.requestedUrls, contains(contains('192.168.1.254')));
    });

    test('discovers a real device through the HTTP probe end-to-end',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(() async {
        final request = await server.first;
        expect(request.uri.path, '/dd.xml');
        request.response.write(_ddXml);
        await request.response.close();
      }());

      final discovery = VestelDeviceDiscovery(
        hostResolver: () async => ['127.0.0.1'],
        deviceDescriptionPorts: [server.port],
      );

      final devices = await discovery.discover().toList();
      await discovery.close();
      await server.close(force: true);

      expect(devices, hasLength(1));
      expect(devices.single.name, 'Living Room TV');
      expect(devices.single.model, '17MB95');
    });
  });

  group('hostsFor', () {
    test('enumerates all usable hosts of the assumed /24 subnet', () {
      final hosts = hostsFor(InternetAddress('192.168.1.5'));

      expect(hosts, hasLength(254));
      expect(hosts.first, '192.168.1.1');
      expect(hosts.last, '192.168.1.254');
    });

    test('handles 10.x addresses', () {
      final hosts = hostsFor(InternetAddress('10.0.0.5'));

      expect(hosts, hasLength(254));
      expect(hosts.first, '10.0.0.1');
      expect(hosts.last, '10.0.0.254');
    });

    test('handles 172.16-31 addresses', () {
      final hosts = hostsFor(InternetAddress('172.17.0.5'));

      expect(hosts, hasLength(254));
      expect(hosts.first, '172.17.0.1');
    });

    test('returns an empty list for public addresses', () {
      final hosts = hostsFor(InternetAddress('8.8.8.8'));

      expect(hosts, isEmpty);
    });

    test('returns an empty list for loopback addresses', () {
      final hosts = hostsFor(InternetAddress('127.0.0.1'));

      expect(hosts, isEmpty);
    });
  });

  group('hostsForPrefix', () {
    test('enumerates the hosts of the given prefix', () {
      final hosts = hostsForPrefix('192.168.0');

      expect(hosts, hasLength(254));
      expect(hosts.first, '192.168.0.1');
      expect(hosts.last, '192.168.0.254');
    });

    test('rejects malformed prefixes', () {
      expect(() => hostsForPrefix('192.168'), throwsArgumentError);
      expect(() => hostsForPrefix('192.168.0.1'), throwsArgumentError);
    });
  });
}