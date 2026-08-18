import 'dart:io';

import 'package:openzap/features/remote_control/domain/remote_key.dart';
import 'package:openzap/integrations/vestel/vestel_remote_control.dart';

/// Sends a remote-control key to a Vestel TV from the command line.
///
/// Usage:
///   `dart run tool/send_key.dart <ip> <key|code>`
///
/// Examples:
///   `dart run tool/send_key.dart 192.168.0.101 volumeUp`
///   `dart run tool/send_key.dart 192.168.0.101 1016`
Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    _print('Usage: dart run tool/send_key.dart <ip> <key|code>');
    exitCode = 64;
    return;
  }

  final host = arguments[0];
  final raw = arguments[1];
  final remote = VestelRemoteControl(host: host);

  try {
    final code = int.tryParse(raw);
    if (code != null) {
      await remote.sendCode(code);
    } else {
      RemoteKey? key;
      for (final candidate in RemoteKey.values) {
        if (candidate.name.toLowerCase() == raw.toLowerCase()) {
          key = candidate;
          break;
        }
      }
      if (key == null) {
        _print('Unknown key "$raw". Available: '
            '${RemoteKey.values.map((k) => k.name).join(', ')}');
        exitCode = 64;
        return;
      }
      await remote.sendKey(key);
    }
    _print('Sent "$raw" to $host.');
  } on Exception catch (e) {
    _print('Failed: $e');
    exitCode = 1;
  } finally {
    await remote.close();
  }
}

void _print(String message) {
  stdout.writeln(message);
  stdout.flush();
}