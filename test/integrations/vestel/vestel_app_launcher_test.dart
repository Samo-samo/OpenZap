import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:openzap/core/networking/http_probe.dart';
import 'package:openzap/features/quick_launch/domain/quick_launch_error.dart';
import 'package:openzap/features/quick_launch/domain/quick_launch_service.dart';
import 'package:openzap/integrations/vestel/vestel_app_launcher.dart';

class _FakeProbe implements HttpProbe {
  String? response;
  String? lastUrl;
  String? lastBody;
  Map<String, String>? lastHeaders;

  @override
  Future<String?> get(String url, {required Duration timeout}) async => null;

  @override
  Future<String?> post(
    String url, {
    required String body,
    Map<String, String>? headers,
    required Duration timeout,
  }) async {
    lastUrl = url;
    lastBody = body;
    lastHeaders = headers;
    return response;
  }

  @override
  Future<void> close() async {}
}

void main() {
  group('VestelAppLauncher', () {
    test(
      'launches YouTube through the DIAL endpoint with an empty body',
      () async {
        final probe = _FakeProbe()..response = '';
        final launcher = VestelAppLauncher(host: '192.168.0.101', probe: probe);

        await launcher.launch(QuickLaunchTarget.youtube);

        expect(probe.lastUrl, 'http://192.168.0.101:56789/apps/YouTube');
        expect(probe.lastBody, '');
        expect(
          probe.lastHeaders?['Content-Type'],
          'text/plain; charset=ISO-8859-1',
        );
        expect(probe.lastHeaders?['Connection'], 'Keep-Alive');
      },
    );

    test('launches Netflix through the DIAL endpoint', () async {
      final probe = _FakeProbe()..response = '';
      final launcher = VestelAppLauncher(host: '192.168.0.101', probe: probe);

      await launcher.launch(QuickLaunchTarget.netflix);

      expect(probe.lastUrl, 'http://192.168.0.101:56789/apps/Netflix');
      expect(probe.lastBody, '');
    });

    test('opens the portal through SmartCenter', () async {
      final probe = _FakeProbe()..response = '';
      final launcher = VestelAppLauncher(host: '192.168.0.101', probe: probe);

      await launcher.launch(QuickLaunchTarget.portal);

      expect(probe.lastUrl, 'http://192.168.0.101:56789/apps/SmartCenter');
      expect(probe.lastBody, '');
    });

    test('switches to HDMI via the INPUT_SOURCE key', () async {
      final probe = _FakeProbe()..response = '';
      final launcher = VestelAppLauncher(host: '192.168.0.101', probe: probe);

      await launcher.launch(QuickLaunchTarget.hdmi);

      expect(probe.lastUrl, 'http://192.168.0.101:56789/apps/SmartCenter');
      expect(probe.lastBody, contains("code='1056'"));
    });

    test('throws when the TV does not accept the app launch', () async {
      final probe = _FakeProbe()..response = null;
      final launcher = VestelAppLauncher(host: '192.168.0.101', probe: probe);

      expect(
        () => launcher.launch(QuickLaunchTarget.youtube),
        throwsA(isA<QuickLaunchException>()),
      );
    });

    test('launches an app against a real TV endpoint end-to-end', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(() async {
        final request = await server.first;
        expect(request.method, 'POST');
        expect(request.uri.path, '/apps/YouTube');
        expect(await utf8.decodeStream(request), '');
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
      }());

      final launcher = VestelAppLauncher(host: '127.0.0.1', port: server.port);

      await launcher.launch(QuickLaunchTarget.youtube);
      await server.close(force: true);
      await launcher.close();
    });
  });
}
