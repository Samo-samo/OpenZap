import '../../core/networking/http_probe.dart';
import '../../features/remote_control/domain/remote_control.dart';
import '../../features/remote_control/domain/remote_control_error.dart';
import '../../features/remote_control/domain/remote_key.dart';

const int _remoteControlPort = 56789;
const String _remoteControlPath = '/apps/SmartCenter';

/// Remote control for Vestel-based TVs.
///
/// Sends key presses through the HTTP virtual-remote API
/// (`POST /apps/SmartCenter`), as observed on a VESTEL 50U9510M (MB180).
/// The default port matches that device; other models may use a different
/// port (see `.ai/vestel-protocol-notes.md`).
class VestelRemoteControl implements RemoteControl {
  VestelRemoteControl({
    required this.host,
    this.port = _remoteControlPort,
    HttpProbe? probe,
    this.probeTimeout = const Duration(seconds: 3),
  }) : _probe = probe ?? DartHttpProbe();

  final String host;
  final int port;
  final Duration probeTimeout;
  final HttpProbe _probe;

  @override
  Future<void> sendKey(RemoteKey key) {
    final code = _keyCodes[key];
    if (code == null) {
      throw ArgumentError.value(key, 'key', 'No code mapped for key');
    }
    return sendCode(code);
  }

  @override
  Future<void> sendCode(int code) async {
    final response = await _probe.post(
      'http://$host:$port$_remoteControlPath',
      body: "<?xml version='1.0' ?><remote><key code='$code'/></remote>",
      headers: const {
        'Content-Type': 'text/plain; charset=ISO-8859-1',
        'Connection': 'Keep-Alive',
      },
      timeout: probeTimeout,
    );
    if (response == null) {
      throw RemoteControlException(
        'TV at $host:$port did not accept the command',
      );
    }
  }

  @override
  Future<void> close() => _probe.close();
}

const Map<RemoteKey, int> _keyCodes = {
  RemoteKey.power: 1012,
  RemoteKey.mute: 1013,
  RemoteKey.volumeUp: 1016,
  RemoteKey.volumeDown: 1017,
  RemoteKey.info: 1018,
  RemoteKey.down: 1019,
  RemoteKey.up: 1020,
  RemoteKey.left: 1021,
  RemoteKey.right: 1022,
  RemoteKey.channelUp: 1032,
  RemoteKey.channelDown: 1033,
  RemoteKey.exit: 1037,
  RemoteKey.back: 1010,
  RemoteKey.select: 1053,
  RemoteKey.digit0: 1000,
  RemoteKey.digit1: 1001,
  RemoteKey.digit2: 1002,
  RemoteKey.digit3: 1003,
  RemoteKey.digit4: 1004,
  RemoteKey.digit5: 1005,
  RemoteKey.digit6: 1006,
  RemoteKey.digit7: 1007,
  RemoteKey.digit8: 1008,
  RemoteKey.digit9: 1009,
};
