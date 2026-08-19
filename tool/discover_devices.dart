import 'dart:io';

import 'package:openzap/integrations/vestel/vestel_device_discovery.dart';

/// Runs Vestel device discovery from the command line.
///
/// Usage:
///   dart run tool/discover_devices.dart
///   dart run tool/discover_devices.dart 192.168.0 192.168.1
///
/// With no arguments, candidate hosts are derived from the local interfaces
/// (virtual adapters are skipped). Pass subnet prefixes to scan specific
/// subnets instead.
Future<void> main(List<String> arguments) async {
  final discovery = VestelDeviceDiscovery(
    subnets: arguments.isEmpty ? null : arguments,
  );

  _print('Scanning for Vestel TVs...');
  final devices = await discovery.discover().toList();

  if (devices.isEmpty) {
    _print(
      'No devices found. Make sure the TV is turned on and its virtual '
      'remote / DIAL feature is enabled in the TV settings.',
    );
  } else {
    for (final device in devices) {
      final model = device.model == null ? '' : ' (model: ${device.model})';
      _print(
        'Found: ${device.name} at ${device.ipAddress}:${device.port}$model',
      );
    }
  }

  await discovery.close();
}

void _print(String message) {
  stdout.writeln(message);
  stdout.flush();
}
