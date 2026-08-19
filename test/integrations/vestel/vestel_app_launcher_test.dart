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
    test('sends the YouTube shortcut key', () async {
      final probe = _FakeProbe()..response = '';
      final launcher = VestelAppLauncher(host: '192.168.0.101', probe: probe);

      await launcher.launch(QuickLaunchTarget.youtube);

      expect(probe.lastUrl, 'http://192.168.0.101:56789/apps/SmartCenter');
      expect(probe.lastBody, contains("code='1062'"));
    });

    test('sends the Netflix shortcut key', () async {
      final probe = _FakeProbe()..response = '';
      final launcher = VestelAppLauncher(host: '192.168.0.101', probe: probe);

      await launcher.launch(QuickLaunchTarget.netflix);

      expect(probe.lastBody, contains("code='1064'"));
    });

    test('sends the portal (APP) shortcut key', () async {
      final probe = _FakeProbe()..response = '';
      final launcher = VestelAppLauncher(host: '192.168.0.101', probe: probe);

      await launcher.launch(QuickLaunchTarget.portal);

      expect(probe.lastBody, contains("code='1046'"));
    });

    test('sends the HDMI (INPUT_SOURCE) shortcut key', () async {
      final probe = _FakeProbe()..response = '';
      final launcher = VestelAppLauncher(host: '192.168.0.101', probe: probe);

      await launcher.launch(QuickLaunchTarget.hdmi);

      expect(probe.lastBody, contains("code='1056'"));
    });

    test('throws when the TV does not accept the key', () async {
      final probe = _FakeProbe()..response = null;
      final launcher = VestelAppLauncher(host: '192.168.0.101', probe: probe);

      expect(
        () => launcher.launch(QuickLaunchTarget.netflix),
        throwsA(isA<QuickLaunchException>()),
      );
    });
  });
}
