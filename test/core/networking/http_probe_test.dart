import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:openzap/core/networking/http_probe.dart';

Future<void> _respond(HttpServer server, int statusCode, String body) async {
  final request = await server.first;
  request.response.statusCode = statusCode;
  request.response.write(body);
  await request.response.close();
}

void main() {
  group('DartHttpProbe', () {
    test('returns the response body for a 200 response', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final probe = DartHttpProbe();

      unawaited(
        _respond(server, HttpStatus.ok, '<friendlyName>TestTV</friendlyName>'),
      );

      final body = await probe.get(
        'http://127.0.0.1:${server.port}/dd.xml',
        timeout: const Duration(seconds: 2),
      );

      expect(body, contains('TestTV'));
      await server.close(force: true);
      await probe.close();
    });

    test('returns null for a non-200 response', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final probe = DartHttpProbe();

      unawaited(_respond(server, HttpStatus.notFound, ''));

      final body = await probe.get(
        'http://127.0.0.1:${server.port}/dd.xml',
        timeout: const Duration(seconds: 2),
      );

      expect(body, isNull);
      await server.close(force: true);
      await probe.close();
    });

    test('returns null when the host does not respond', () async {
      final temp = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = temp.port;
      await temp.close(force: true);

      final probe = DartHttpProbe();
      final body = await probe.get(
        'http://127.0.0.1:$port/dd.xml',
        timeout: const Duration(seconds: 1),
      );

      expect(body, isNull);
      await probe.close();
    });
  });
}