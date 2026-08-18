import 'package:flutter_test/flutter_test.dart';

import 'package:openzap/core/networking/udp_broadcast_socket.dart';

void main() {
  group('DartUdpBroadcastSocket', () {
    test('opens and closes without error', () async {
      final socket = DartUdpBroadcastSocket();

      await socket.open();
      await socket.close();
    });

    test('listen completes with no datagrams when nothing is sent', () async {
      final socket = DartUdpBroadcastSocket();

      await socket.open();
      final datagrams = await socket.listen(const Duration(milliseconds: 50)).toList();
      await socket.close();

      expect(datagrams, isEmpty);
    });

    test('broadcast requires an open socket', () async {
      final socket = DartUdpBroadcastSocket();

      expect(
        () => socket.broadcast([1, 2, 3], port: 4567),
        throwsStateError,
      );
    });
  });
}