import 'dart:async';
import 'dart:convert';
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

    test('posts the body with the given headers and returns the response',
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final probe = DartHttpProbe();

      unawaited(() async {
        final request = await server.first;
        expect(request.method, 'POST');
        expect(request.uri.path, '/apps/SmartCenter');
        expect(
          request.headers.value('content-type'),
          'text/plain; charset=ISO-8859-1',
        );
        expect(await utf8.decodeStream(request), contains("code='1016'"));
        request.response.write('<ok/>');
        await request.response.close();
      }());

      final body = await probe.post(
        'http://127.0.0.1:${server.port}/apps/SmartCenter',
        body: "<?xml version='1.0' ?><remote><key code='1016'/></remote>",
        headers: const {'Content-Type': 'text/plain; charset=ISO-8859-1'},
        timeout: const Duration(seconds: 2),
      );

      expect(body, '<ok/>');
      await server.close(force: true);
      await probe.close();
    });

    test('returns null for a non-200 POST response', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final probe = DartHttpProbe();

      unawaited(_respond(server, HttpStatus.notFound, ''));

      final body = await probe.post(
        'http://127.0.0.1:${server.port}/apps/SmartCenter',
        body: 'x',
        timeout: const Duration(seconds: 2),
      );

      expect(body, isNull);
      await server.close(force: true);
      await probe.close();
    });
  });
}