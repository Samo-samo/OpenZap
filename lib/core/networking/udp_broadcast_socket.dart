import 'dart:async';
import 'dart:io';

/// A UDP socket that can broadcast a payload and collect replies.
///
/// The transport is brand-agnostic: the broadcast payload, target port, and
/// reply parsing are protocol-specific and live in integrations.
abstract class UdpBroadcastSocket {
  /// Binds the socket so it can both send and receive.
  ///
  /// [localPort] defaults to an ephemeral port.
  Future<void> open({int localPort = 0});

  /// Sends [payload] to the limited broadcast address on [port].
  Future<void> broadcast(List<int> payload, {required int port});

  /// Streams received datagrams until [duration] elapses.
  Stream<Datagram> listen(Duration duration);

  /// Closes the socket and releases the bound port.
  Future<void> close();
}

/// [UdpBroadcastSocket] implementation backed by [RawDatagramSocket].
class DartUdpBroadcastSocket implements UdpBroadcastSocket {
  RawDatagramSocket? _socket;

  @override
  Future<void> open({int localPort = 0}) async {
    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      localPort,
      reuseAddress: true,
    );
    socket.broadcastEnabled = true;
    _socket = socket;
  }

  @override
  Future<void> broadcast(List<int> payload, {required int port}) async {
    final socket = _requireSocket();
    socket.send(payload, InternetAddress('255.255.255.255'), port);
  }

  @override
  Stream<Datagram> listen(Duration duration) {
    final socket = _requireSocket();
    return socket
        .timeout(duration, onTimeout: (EventSink<RawSocketEvent> sink) {
          sink.close();
        })
        .map((_) => socket.receive())
        .where((datagram) => datagram != null)
        .cast<Datagram>();
  }

  @override
  Future<void> close() async {
    _socket?.close();
    _socket = null;
  }

  RawDatagramSocket _requireSocket() {
    final socket = _socket;
    if (socket == null) {
      throw StateError('UdpBroadcastSocket is not open.');
    }
    return socket;
  }
}