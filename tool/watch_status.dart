import 'dart:async';
import 'dart:io';

import 'package:openzap/integrations/vestel/vestel_tv_status.dart';

/// Connects to the Vestel TV status WebSocket (port 7681) and prints the
/// status events the TV pushes. Press Ctrl+C to exit.
///
/// Usage: `dart run tool/watch_status.dart <tv-ip>`
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/watch_status.dart <tv-ip>');
    exitCode = 64;
    return;
  }

  final host = args[0];
  final service = VestelTvStatus(host: host);
  service.watch().listen(
        (status) => stdout.writeln(status),
        onError: (Object e) => stderr.writeln('Error: $e'),
      );
  stdout.writeln('Listening for status events from $host:7681 ...');
  await Completer<void>().future;
}