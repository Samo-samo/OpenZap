import 'dart:io';

/// Connects to the Vestel TV status WebSocket (port 7681) and prints every
/// incoming frame verbatim, including connection state. Press Ctrl+C to exit.
///
/// Usage: `dart run tool/watch_status.dart <tv-ip>`
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    stderr.writeln('Usage: dart run tool/watch_status.dart <tv-ip>');
    exitCode = 64;
    return;
  }

  final host = args[0];
  final uri = 'ws://$host:7681/';
  stdout.writeln('Connecting to $uri ...');
  try {
    final socket = await WebSocket.connect(uri);
    stdout.writeln('Connected. Waiting for frames... (Ctrl+C to exit)');
    socket.listen(
      (data) => stdout.writeln('FRAME: $data'),
      onError: (Object e) => stderr.writeln('Error: $e'),
      onDone: () => stderr.writeln('Connection closed by TV.'),
    );
    await Future<void>.delayed(const Duration(days: 1));
  } on WebSocketException catch (e) {
    stderr.writeln('Connection failed: $e');
    exitCode = 1;
  }
}
