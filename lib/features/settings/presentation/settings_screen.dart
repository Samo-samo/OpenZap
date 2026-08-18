import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../domain/app_settings.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider);
    final commandFeedback =
        settings.valueOrNull?.commandFeedback ?? CommandFeedback.errorsOnly;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.commandFeedback, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(l10n.commandFeedbackDescription, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          RadioGroup<CommandFeedback>(
            groupValue: commandFeedback,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setCommandFeedback(value);
              }
            },
            child: Column(
              children: [
                RadioListTile<CommandFeedback>(
                  title: Text(l10n.feedbackErrorsOnly),
                  value: CommandFeedback.errorsOnly,
                ),
                RadioListTile<CommandFeedback>(
                  title: Text(l10n.feedbackAll),
                  value: CommandFeedback.all,
                ),
                RadioListTile<CommandFeedback>(
                  title: Text(l10n.feedbackNone),
                  value: CommandFeedback.none,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}