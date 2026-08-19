import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:openzap/core/networking/http_probe.dart';
import 'package:openzap/features/remote_control/domain/remote_control_error.dart';
import 'package:openzap/features/remote_control/domain/remote_key.dart';
import 'package:openzap/integrations/vestel/vestel_remote_control.dart';

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
  group('VestelRemoteControl', () {
    test('posts the volume-up key code to the SmartCenter endpoint', () async {
      final probe = _FakeProbe()..response = '';
      final remote = VestelRemoteControl(host: '192.168.0.101', probe: probe);

      await remote.sendKey(RemoteKey.volumeUp);

      expect(probe.lastUrl, 'http://192.168.0.101:56789/apps/SmartCenter');
      expect(
        probe.lastBody,
        "<?xml version='1.0' ?><remote><key code='1016'/></remote>",
      );
      expect(
        probe.lastHeaders?['Content-Type'],
        'text/plain; charset=ISO-8859-1',
      );
      expect(probe.lastHeaders?['Connection'], 'Keep-Alive');
    });

    test('maps every RemoteKey to a numeric code', () async {
      final probe = _FakeProbe()..response = '';
      final remote = VestelRemoteControl(host: '192.168.0.101', probe: probe);

      for (final key in RemoteKey.values) {
        await remote.sendKey(key);
        expect(probe.lastBody, contains("key code='"));
        expect(probe.lastBody, isNot(contains("key code='null'")));
      }
    });

    test('sends a raw code unchanged', () async {
      final probe = _FakeProbe()..response = '';
      final remote = VestelRemoteControl(host: '192.168.0.101', probe: probe);

      await remote.sendCode(1037);

      expect(probe.lastBody, contains("code='1037'"));
    });

    test('throws when the TV does not accept the command', () async {
      final probe = _FakeProbe()..response = null;
      final remote = VestelRemoteControl(host: '192.168.0.101', probe: probe);

      expect(
        () => remote.sendKey(RemoteKey.mute),
        throwsA(isA<RemoteControlException>()),
      );
    });

    test('sends a key to a real TV endpoint end-to-end', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      unawaited(() async {
        final request = await server.first;
        expect(request.method, 'POST');
        expect(request.uri.path, '/apps/SmartCenter');
        expect(await utf8.decodeStream(request), contains("code='1016'"));
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
      }());

      final remote = VestelRemoteControl(host: '127.0.0.1', port: server.port);

      await remote.sendKey(RemoteKey.volumeUp);
      await server.close(force: true);
      await remote.close();
    });
  });
}
