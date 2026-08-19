import '../../core/networking/http_probe.dart';
import '../../features/quick_launch/domain/quick_launch_error.dart';
import '../../features/quick_launch/domain/quick_launch_service.dart';
import '../../features/remote_control/domain/remote_control_error.dart';
import 'vestel_remote_control.dart';

/// Launches apps and switches inputs on Vestel-based TVs.
///
/// Apps are started through the virtual-remote shortcut keys (observed on a
/// VESTEL 50U9510M / MB180): NETFLIX 1064, APP (portal) 1046, INPUT_SOURCE
/// 1056 and a tentative YouTube key 1063. DIAL `POST /apps/{id}` is **not**
/// available on MB180 (returns 403) and is therefore not used here.
class VestelAppLauncher implements QuickLaunchService {
  VestelAppLauncher({
    required this.host,
    this.port = _remoteControlPort,
    HttpProbe? probe,
    this.probeTimeout = const Duration(seconds: 3),
  }) : _remote = VestelRemoteControl(
         host: host,
         port: port,
         probe: probe,
         probeTimeout: probeTimeout,
       );

  static const int _remoteControlPort = 56789;

  /// Remote key codes per launch target (node-red keymap, confirmed working
  /// on MB180 as key POSTs return 200).
  static const Map<QuickLaunchTarget, int> _keyCodes = {
    QuickLaunchTarget.youtube: 1063,
    QuickLaunchTarget.netflix: 1064,
    QuickLaunchTarget.hdmi: 1056,
    QuickLaunchTarget.portal: 1046,
  };

  final String host;
  final int port;
  final Duration probeTimeout;
  final VestelRemoteControl _remote;

  @override
  Future<void> launch(QuickLaunchTarget target) async {
    final code = _keyCodes[target];
    if (code == null) {
      throw QuickLaunchException('Unsupported launch target: $target');
    }
    try {
      await _remote.sendCode(code);
    } on RemoteControlException catch (e) {
      throw QuickLaunchException(e.message);
    }
  }

  @override
  Future<void> close() => _remote.close();
}
