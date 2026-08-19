// Launches an app/input on a Vestel TV through the remote shortcut keys.
//
// Usage:
//   dart run tool/launch_app.dart <tv-ip> <youtube|netflix|hdmi|portal>
//
// Keys are sent via the virtual-remote endpoint; DIAL is unavailable on MB180.
// Confirmed codes: YouTube 1062, Netflix 1064, portal 1046, source 1056.
import 'dart:io';

import 'package:openzap/features/quick_launch/domain/quick_launch_error.dart';
import 'package:openzap/features/quick_launch/domain/quick_launch_service.dart';
import 'package:openzap/integrations/vestel/vestel_app_launcher.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/launch_app.dart <tv-ip> <youtube|netflix|hdmi|portal>',
    );
    exit(2);
  }
  final host = args[0];
  final target = switch (args[1].toLowerCase()) {
    'youtube' => QuickLaunchTarget.youtube,
    'netflix' => QuickLaunchTarget.netflix,
    'hdmi' => QuickLaunchTarget.hdmi,
    'portal' => QuickLaunchTarget.portal,
    _ => null,
  };
  if (target == null) {
    stderr.writeln('Unknown app: ${args[1]} (use youtube|netflix|hdmi|portal)');
    exit(2);
  }
  final launcher = VestelAppLauncher(host: host);
  try {
    await launcher.launch(target);
    stdout.writeln('Launched ${args[1].toLowerCase()} on $host');
  } on QuickLaunchException catch (e) {
    stderr.writeln('Failed: ${e.message}');
    exit(1);
  } finally {
    await launcher.close();
  }
}
