import 'dart:async';
import 'dart:io';

import '../../features/tv_status/domain/tv_status.dart';
import '../../features/tv_status/domain/tv_status_service.dart';

const _statusWebSocketPort = 7681;

/// Observes live TV status over the Vestel status WebSocket (port 7681).
///
/// The TV pushes text frames immediately on connect; no handshake is needed.
/// Frames come in two documented shapes, both handled here:
///   * `<tv_state value='PLAYER_PORTAL'/>` (optionally wrapped in
///     `<event>...</event>`), where an empty value means the TV is off.
///   * `tv_status:1` (optionally wrapped in `<event>...</event>`), where `1`
///     means the TV is on.
class VestelTvStatus implements TvStatusService {
  VestelTvStatus({required this.host, this.port = _statusWebSocketPort});

  final String host;
  final int port;

  StreamController<TvStatus>? _controller;
  WebSocket? _socket;
  bool _closed = false;

  @override
  Stream<TvStatus> watch() {
    _controller ??= StreamController<TvStatus>.broadcast(
      onListen: _connect,
      onCancel: _disconnect,
    );
    return _controller!.stream;
  }

  Future<void> _connect() async {
    try {
      _socket = await WebSocket.connect('ws://$host:$port/');
    } catch (_) {
      _emitUnknown();
      return;
    }
    _socket!.listen(
      (data) {
        final status = _parse(data);
        if (status != null) {
          _controller?.add(status);
        }
      },
      onError: (_) => _emitUnknown(),
      onDone: () {
        if (!_closed) {
          _emitUnknown();
        }
      },
    );
  }

  Future<void> _disconnect() async {
    await _socket?.close();
    _socket = null;
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _disconnect();
    await _controller?.close();
    _controller = null;
  }

  void _emitUnknown() {
    if (_closed) {
      return;
    }
    _controller?.add(const TvStatus.unknown());
  }

  static TvStatus? _parse(Object data) {
    final message = data is String ? data : null;
    if (message == null) {
      return null;
    }
    final state = RegExp(r"<tv_state\s+value='([^']*)'").firstMatch(message);
    if (state != null) {
      final value = state.group(1)!;
      return TvStatus(
        powerState: value.isEmpty ? TvPowerState.off : TvPowerState.on,
        stateName: value.isEmpty ? null : value,
      );
    }
    final status = RegExp(r'tv_status:(\d+)').firstMatch(message);
    if (status != null) {
      return TvStatus(
        powerState: status.group(1) == '1'
            ? TvPowerState.on
            : TvPowerState.off,
      );
    }
    return null;
  }
}