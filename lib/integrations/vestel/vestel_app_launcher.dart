import '../../core/networking/http_probe.dart';
import '../../features/quick_launch/domain/quick_launch_error.dart';
import '../../features/quick_launch/domain/quick_launch_service.dart';
import '../../features/remote_control/domain/remote_control_error.dart';
import 'vestel_remote_control.dart';

const int _dialPort = 56789;
const String _dialBase = '/apps';

/// Launches apps and switches inputs on Vestel-based TVs.
///
/// Apps are started through DIAL (`POST http://<ip>:56789/apps/{AppId}` with
/// an empty body), as observed on a VESTEL 50U9510M (MB180). HDMI is switched
/// via the INPUT_SOURCE key (1056). The default port matches that device;
/// other models may use a different port (see `.ai/vestel-protocol-notes.md`).
class VestelAppLauncher implements QuickLaunchService {
  VestelAppLauncher({
    required this.host,
    this.port = _dialPort,
    HttpProbe? probe,
    this.probeTimeout = const Duration(seconds: 3),
  }) : _probe = probe ?? DartHttpProbe(),
       _remote = VestelRemoteControl(
         host: host,
         port: port,
         probe: probe,
         probeTimeout: const Duration(seconds: 3),
       );

  final String host;
  final int port;
  final Duration probeTimeout;
  final HttpProbe _probe;
  final VestelRemoteControl _remote;

  /// DIAL application IDs observed on Vestel TVs.
  static const Map<QuickLaunchTarget, String> dialAppIds = {
    QuickLaunchTarget.youtube: 'YouTube',
    QuickLaunchTarget.netflix: 'Netflix',
    QuickLaunchTarget.portal: 'SmartCenter',
  };

  /// Remote key code that cycles through input sources (see notes).
  static const int _inputSourceCode = 1056;

  @override
  Future<void> launch(QuickLaunchTarget target) async {
    final appId = dialAppIds[target];
    if (appId != null) {
      return _launchDial(appId);
    }
    if (target == QuickLaunchTarget.hdmi) {
      return _switchInput();
    }
    throw QuickLaunchException('Unsupported launch target: $target');
  }

  Future<void> _launchDial(String appId) async {
    final response = await _probe.post(
      'http://$host:$port$_dialBase/$appId',
      body: '',
      headers: const {
        'Content-Type': 'text/plain; charset=ISO-8859-1',
        'Connection': 'Keep-Alive',
      },
      timeout: probeTimeout,
    );
    if (response == null) {
      throw QuickLaunchException(
        'TV at $host:$port did not accept the app launch',
      );
    }
  }

  Future<void> _switchInput() async {
    try {
      await _remote.sendCode(_inputSourceCode);
    } on RemoteControlException catch (e) {
      throw QuickLaunchException(e.message);
    }
  }

  @override
  Future<void> close() async {
    await _probe.close();
    await _remote.close();
  }
}
