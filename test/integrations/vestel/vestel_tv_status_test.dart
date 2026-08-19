import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:openzap/features/tv_status/domain/tv_status.dart';
import 'package:openzap/integrations/vestel/vestel_tv_status.dart';

Future<HttpServer> _serve(List<Object> frames) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final socket = await WebSocketTransformer.upgrade(request);
    for (final frame in frames) {
      socket.add(frame);
    }
    await socket.close();
  });
  return server;
}

void main() {
  group('VestelTvStatus', () {
    test('parses tv_state events as on with state name', () async {
      final server = await _serve([
        "<event><tv_state value='PLAYER_PORTAL'/></event>",
      ]);
      final service = VestelTvStatus(host: 'localhost', port: server.port);

      final status = await service.watch().first;

      expect(status.powerState, TvPowerState.on);
      expect(status.stateName, 'PLAYER_PORTAL');
      await service.close();
      await server.close(force: true);
    });

    test('parses bare tv_state and tv_status frames', () async {
      final server = await _serve([
        "<tv_state value='NOSIGNAL'>",
        'tv_status:1',
      ]);
      final service = VestelTvStatus(host: 'localhost', port: server.port);

      final statuses = await service.watch().take(2).toList();

      expect(statuses[0].powerState, TvPowerState.on);
      expect(statuses[0].stateName, 'NOSIGNAL');
      expect(statuses[1].powerState, TvPowerState.on);
      expect(statuses[1].stateName, isNull);
      await service.close();
      await server.close(force: true);
    });

    test('parses empty tv_state as off', () async {
      final server = await _serve(["<tv_state value=''/>"]);
      final service = VestelTvStatus(host: 'localhost', port: server.port);

      final status = await service.watch().first;

      expect(status.powerState, TvPowerState.off);
      expect(status.stateName, isNull);
      await service.close();
      await server.close(force: true);
    });
  });
}
