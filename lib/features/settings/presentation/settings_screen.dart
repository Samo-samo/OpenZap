import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../device_settings/presentation/saved_devices_provider.dart';
import '../../discovery/domain/discovered_device.dart';
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
    final themeMode = settings?.themeMode ?? AppThemeMode.system;
    // No explicit "System" option: the current system locale is detected and
    // preselected, and any pick stores a concrete language.
    final systemLanguageCode =
        Localizations.localeOf(context).languageCode == 'tr' ? 'tr' : 'en';
    final languageCode = settings?.languageCode ?? systemLanguageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          _SectionHeader(l10n.appearance),
          RadioGroup<AppThemeMode>(
            groupValue: themeMode,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setThemeMode(value);
              }
            },
            child: Column(
              children: [
                RadioListTile<AppThemeMode>(
                  title: Text(l10n.themeSystem),
                  mouseCursor: SystemMouseCursors.click,
                  value: AppThemeMode.system,
                ),
                RadioListTile<AppThemeMode>(
                  title: Text(l10n.themeLight),
                  mouseCursor: SystemMouseCursors.click,
                  value: AppThemeMode.light,
                ),
                RadioListTile<AppThemeMode>(
                  title: Text(l10n.themeDark),
                  mouseCursor: SystemMouseCursors.click,
                  value: AppThemeMode.dark,
                ),
              ],
            ),
          ),
          RadioGroup<String>(
            groupValue: languageCode,
            onChanged: (value) {
              if (value != null) {
                ref.read(settingsProvider.notifier).setLanguageCode(value);
              }
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(l10n.languageTurkish),
                  mouseCursor: SystemMouseCursors.click,
                  value: 'tr',
                ),
                RadioListTile<String>(
                  title: Text(l10n.languageEnglish),
                  mouseCursor: SystemMouseCursors.click,
                  value: 'en',
                ),
              ],
            ),
          ),
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
          _SectionHeader(l10n.tvStatusTracking),
          SwitchListTile(
            title: Text(l10n.tvStatusTracking),
            subtitle: Text(l10n.tvStatusTrackingDescription),
            mouseCursor: SystemMouseCursors.click,
            value: settings?.tvStatusTracking ?? false,
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).setTvStatusTracking(value),
          ),
          _SectionHeader(l10n.devices),
          ref.watch(savedDevicesProvider).when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => ListTile(title: Text('$error')),
                data: (devices) => Column(
                  children: [
                    if (devices.isEmpty)
                      ListTile(title: Text(l10n.noSavedDevices)),
                    for (final device in devices)
                      ListTile(
                        leading: const Icon(Icons.tv),
                        title: Text(device.name),
                        subtitle: Text(device.ipAddress),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.removeDevice,
                          onPressed: () => ref
                              .read(savedDevicesProvider.notifier)
                              .remove(device.ipAddress),
                        ),
                      ),
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: Text(l10n.addDevice),
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () => _addDevice(context, ref),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _addDevice(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final added = await showDialog<DiscoveredDevice>(
      context: context,
      builder: (_) => const _AddDeviceDialog(),
    );
    if (added == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    final devices = ref.read(savedDevicesProvider).valueOrNull ?? const [];
    if (devices.any((device) => device.ipAddress == added.ipAddress)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.deviceAlreadyAdded)));
      return;
    }
    await ref.read(savedDevicesProvider.notifier).add(added);
  }
}

class _AddDeviceDialog extends StatefulWidget {
  const _AddDeviceDialog();

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final ip = _ipController.text.trim();
    final name = _nameController.text.trim();
    Navigator.of(context).pop(
      DiscoveredDevice(
        name: name.isEmpty ? ip : name,
        ipAddress: ip,
        port: 56789,
        manufacturer: 'Vestel',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addDevice),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(labelText: l10n.deviceNameLabel),
            ),
            TextFormField(
              controller: _ipController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.deviceIpLabel),
              validator: (value) {
                final ip = value?.trim() ?? '';
                if (InternetAddress.tryParse(ip) == null) {
                  return l10n.deviceIpInvalid;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(materialL10n.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(materialL10n.saveButtonLabel),
        ),
      ],
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