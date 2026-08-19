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
    final settings = ref.watch(settingsProvider).valueOrNull;
    final commandFeedback =
        settings?.commandFeedback ?? CommandFeedback.errorsOnly;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          _SectionHeader(
            l10n.commandFeedback,
            description: l10n.commandFeedbackDescription,
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
                  mouseCursor: SystemMouseCursors.click,
                  value: CommandFeedback.errorsOnly,
                ),
                RadioListTile<CommandFeedback>(
                  title: Text(l10n.feedbackAll),
                  mouseCursor: SystemMouseCursors.click,
                  value: CommandFeedback.all,
                ),
                RadioListTile<CommandFeedback>(
                  title: Text(l10n.feedbackNone),
                  mouseCursor: SystemMouseCursors.click,
                  value: CommandFeedback.none,
                ),
              ],
            ),
          ),
          _SectionHeader(l10n.sleepTimer),
          SwitchListTile(
            title: Text(l10n.sleepTimerSwitchHumanReadable),
            mouseCursor: SystemMouseCursors.click,
            value: settings?.sleepTimerHumanReadable ?? true,
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).setSleepTimerHumanReadable(value),
          ),
          SwitchListTile(
            title: Text(l10n.sleepTimerSwitchMinutesInParens),
            mouseCursor: SystemMouseCursors.click,
            value: settings?.sleepTimerShowMinutesInParens ?? true,
            onChanged: (value) => ref
                .read(settingsProvider.notifier)
                .setSleepTimerShowMinutesInParens(value),
          ),
          SwitchListTile(
            title: Text(l10n.sleepTimerSwitchManualInput),
            mouseCursor: SystemMouseCursors.click,
            value: settings?.sleepTimerManualInput ?? false,
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).setSleepTimerManualInput(value),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text, {this.description});

  final String text;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: theme.textTheme.titleMedium),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(description!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}