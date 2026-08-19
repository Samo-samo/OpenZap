import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../remote_control/domain/remote_control_error.dart';
import '../../remote_control/domain/remote_key.dart';

/// Countdown for the sleep timer (remaining time), or `null` when idle.
///
/// When the countdown reaches zero the selected TV is powered off through
/// the remote control.
class SleepTimerNotifier extends Notifier<Duration?> {
  Timer? _timer;
  DateTime? _endsAt;

  @override
  Duration? build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(selectedDeviceProvider, (previous, next) {
      if (previous != null && previous.ipAddress != next?.ipAddress) {
        cancel();
      }
    });
    return null;
  }

  void start(Duration duration) {
    _timer?.cancel();
    _endsAt = DateTime.now().add(duration);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    state = duration;
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
    _endsAt = null;
    state = null;
  }

  void _tick() {
    final remaining = _endsAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      cancel();
      _powerOff();
      return;
    }
    state = remaining;
  }

  Future<void> _powerOff() async {
    try {
      await ref.read(remoteControlProvider)?.sendKey(RemoteKey.power);
    } on RemoteControlException {
      // Best-effort: a failed power-off is surfaced through command feedback.
    }
  }
}

final sleepTimerProvider = NotifierProvider<SleepTimerNotifier, Duration?>(
  SleepTimerNotifier.new,
);
