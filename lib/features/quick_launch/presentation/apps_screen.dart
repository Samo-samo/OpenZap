import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/quick_launch_error.dart';
import '../domain/quick_launch_service.dart';

/// Launches apps and inputs on the selected TV through the quick-launch
/// integration.
class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  static const _apps = <(QuickLaunchTarget, IconData)>[
    (QuickLaunchTarget.youtube, Icons.play_circle_outline),
    (QuickLaunchTarget.netflix, Icons.live_tv),
    (QuickLaunchTarget.hdmi, Icons.cable),
    (QuickLaunchTarget.portal, Icons.apps),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final launcher = ref.watch(quickLaunchProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appsTitle)),
      body: launcher == null
          ? Center(child: Text(l10n.noDeviceSelected))
          : ListView(
              children: [
                for (final (target, icon) in _apps)
                  ListTile(
                    leading: Icon(icon),
                    title: Text(_label(l10n, target)),
                    trailing: const Icon(Icons.chevron_right),
                    mouseCursor: SystemMouseCursors.click,
                    onTap: () => _launch(context, ref, launcher, target),
                  ),
              ],
            ),
    );
  }

  String _label(AppLocalizations l10n, QuickLaunchTarget target) {
    return switch (target) {
      QuickLaunchTarget.youtube => l10n.appYouTube,
      QuickLaunchTarget.netflix => l10n.appNetflix,
      QuickLaunchTarget.hdmi => l10n.appHdmi,
      QuickLaunchTarget.portal => l10n.appPortal,
    };
  }

  Future<void> _launch(
    BuildContext context,
    WidgetRef ref,
    QuickLaunchService launcher,
    QuickLaunchTarget target,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final feedback =
        ref.read(settingsProvider).valueOrNull?.commandFeedback ??
        CommandFeedback.errorsOnly;
    try {
      await launcher.launch(target);
      if (feedback == CommandFeedback.all) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.appLaunched),
              backgroundColor: Colors.green.shade700,
              duration: const Duration(seconds: 1),
            ),
          );
      }
    } on QuickLaunchException catch (e) {
      if (feedback != CommandFeedback.none) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('${l10n.appLaunchFailed} ${e.message}'),
              backgroundColor: Colors.red.shade700,
            ),
          );
      }
    }
  }
}
