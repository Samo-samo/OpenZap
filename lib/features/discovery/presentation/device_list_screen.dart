import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../device_settings/presentation/saved_devices_provider.dart';
import '../../remote_control/presentation/remote_screen.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../settings/presentation/settings_screen.dart';
import '../domain/discovered_device.dart';
import 'discovery_providers.dart';

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final devices = ref.watch(deviceListProvider);
    final lastDevice = ref.watch(lastDeviceProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (ref.watch(
            settingsProvider.select(
              (s) => s.valueOrNull?.wifiWarningEnabled ?? true,
            ),
          ))
            _WifiWarningBanner(
              onDismiss: () => ref
                  .read(settingsProvider.notifier)
                  .setWifiWarningEnabled(false),
            ),
          Expanded(
            child: devices.when(
              loading: () => _ScanningProgress(),
              error: (error, _) =>
                  _CenteredText('${l10n.noDevicesFound}\n$error'),
              data: (list) {
                final saved =
                    ref.watch(savedDevicesProvider).valueOrNull ?? const [];
                final knownIps = {for (final device in list) device.ipAddress};
                final savedByIp = {
                  for (final device in saved) device.ipAddress: device,
                };
                // Saved devices keep their (possibly renamed) name and are
                // deduplicated against the scanned list by IP.
                final merged = [
                  for (final device in list)
                    savedByIp[device.ipAddress] ?? device,
                  for (final device in saved)
                    if (!knownIps.contains(device.ipAddress)) device,
                ];
                return ListView(
                  children: [
                    if (lastDevice != null) ...[
                      _RecentDeviceTile(
                        device: lastDevice,
                        isSaved: savedByIp.containsKey(lastDevice.ipAddress),
                        onTap: () => _selectDevice(context, ref, lastDevice),
                        onSecondaryTapDown: (details) => _showDeviceMenu(
                          context,
                          ref,
                          lastDevice,
                          savedByIp.containsKey(lastDevice.ipAddress),
                          details.globalPosition,
                        ),
                        onLongPressStart: (details) => _showDeviceMenu(
                          context,
                          ref,
                          lastDevice,
                          savedByIp.containsKey(lastDevice.ipAddress),
                          details.globalPosition,
                        ),
                      ),
                      const Divider(),
                    ],
                    for (final device in merged)
                      _DeviceTile(
                        device: device,
                        isSaved: savedByIp.containsKey(device.ipAddress),
                        onTap: () => _selectDevice(context, ref, device),
                        onSecondaryTapDown: (details) => _showDeviceMenu(
                          context,
                          ref,
                          device,
                          savedByIp.containsKey(device.ipAddress),
                          details.globalPosition,
                        ),
                        onLongPressStart: (details) => _showDeviceMenu(
                          context,
                          ref,
                          device,
                          savedByIp.containsKey(device.ipAddress),
                          details.globalPosition,
                        ),
                      ),
                    if (list.isEmpty && saved.isEmpty && lastDevice == null)
                      _CenteredText(l10n.noDevicesFound),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.read(deviceListProvider.notifier).refresh(),
        icon: const Icon(Icons.search),
        label: Text(l10n.findDevices),
      ),
    );
  }

  void _selectDevice(
    BuildContext context,
    WidgetRef ref,
    DiscoveredDevice device,
  ) {
    ref.read(selectedDeviceProvider.notifier).state = device;
    ref.read(deviceStoreProvider).saveLastDevice(device);
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const RemoteScreen()));
  }

  /// Shows the device context menu (right-click / long-press).
  ///
  /// Unsaved devices offer "Save device"; saved devices offer "Rename" and
  /// "Remove" instead.
  void _showDeviceMenu(
    BuildContext context,
    WidgetRef ref,
    DiscoveredDevice device,
    bool isSaved,
    Offset position,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final actions = isSaved
        ? <(String, IconData, String)>[
            (l10n.renameDevice, Icons.edit_outlined, 'rename'),
            (l10n.removeDevice, Icons.delete_outline, 'remove'),
          ]
        : <(String, IconData, String)>[
            (l10n.saveDevice, Icons.bookmark_add_outlined, 'save'),
          ];
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        for (final (label, icon, value) in actions)
          PopupMenuItem(
            value: value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 12),
                Text(label),
              ],
            ),
          ),
      ],
    ).then((value) async {
      if (value == null || !context.mounted) return;
      switch (value) {
        case 'save':
          await _saveDevice(context, ref, device);
        case 'rename':
          await _renameDevice(context, ref, device);
        case 'remove':
          await _removeDevice(context, ref, device);
      }
    });
  }

  Future<void> _saveDevice(
    BuildContext context,
    WidgetRef ref,
    DiscoveredDevice device,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(savedDevicesProvider.notifier).add(device);
    if (!context.mounted) {
      return;
    }
    _showSnack(context, l10n.deviceSaved);
  }

  Future<void> _renameDevice(
    BuildContext context,
    WidgetRef ref,
    DiscoveredDevice device,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _RenameDeviceDialog(currentName: device.name),
    );
    if (name == null || name.isEmpty || name == device.name) {
      return;
    }
    await ref
        .read(savedDevicesProvider.notifier)
        .add(device.copyWith(name: name));
    if (!context.mounted) {
      return;
    }
    _showSnack(context, l10n.deviceRenamed);
  }

  Future<void> _removeDevice(
    BuildContext context,
    WidgetRef ref,
    DiscoveredDevice device,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(savedDevicesProvider.notifier).remove(device.ipAddress);
    if (!context.mounted) {
      return;
    }
    _showSnack(context, l10n.deviceRemoved);
  }

  void _showSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({
    required this.device,
    required this.isSaved,
    required this.onTap,
    required this.onSecondaryTapDown,
    required this.onLongPressStart,
  });

  final DiscoveredDevice device;
  final bool isSaved;
  final VoidCallback onTap;
  final ValueChanged<TapDownDetails> onSecondaryTapDown;
  final ValueChanged<LongPressStartDetails> onLongPressStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTapDown: onSecondaryTapDown,
      onLongPressStart: onLongPressStart,
      child: ListTile(
        leading: isSaved ? const Icon(Icons.bookmark) : const Icon(Icons.tv),
        title: Text(device.name),
        subtitle: Text(
          device.model == null
              ? device.ipAddress
              : '${device.ipAddress} · ${device.model}',
        ),
        trailing: const Icon(Icons.chevron_right),
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
      ),
    );
  }
}

class _WifiWarningBanner extends StatelessWidget {
  const _WifiWarningBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Colors.amber.shade100,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.amber.shade900),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.wifiWarningText,
                style: TextStyle(color: Colors.amber.shade900),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.wifiWarningDismiss,
              color: Colors.amber.shade900,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentDeviceTile extends StatelessWidget {
  const _RecentDeviceTile({
    required this.device,
    required this.isSaved,
    required this.onTap,
    required this.onSecondaryTapDown,
    required this.onLongPressStart,
  });

  final DiscoveredDevice device;
  final bool isSaved;
  final VoidCallback onTap;
  final ValueChanged<TapDownDetails> onSecondaryTapDown;
  final ValueChanged<LongPressStartDetails> onLongPressStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onSecondaryTapDown: onSecondaryTapDown,
      onLongPressStart: onLongPressStart,
      child: Card(
        margin: const EdgeInsets.all(12),
        child: ListTile(
          leading: isSaved
              ? const Icon(Icons.bookmark)
              : const Icon(Icons.connected_tv),
          title: Text(l10n.recentDevice),
          subtitle: Text('${device.name}\n${device.ipAddress}'),
          trailing: const Icon(Icons.chevron_right),
          mouseCursor: SystemMouseCursors.click,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _RenameDeviceDialog extends StatefulWidget {
  const _RenameDeviceDialog({required this.currentName});

  final String currentName;

  @override
  State<_RenameDeviceDialog> createState() => _RenameDeviceDialogState();
}

class _RenameDeviceDialogState extends State<_RenameDeviceDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentName,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.renameDeviceDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.deviceNameLabel),
        onSubmitted: (_) => _submit(),
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

class _ScanningProgress extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ref.watch(scanProgressProvider);
    if (progress == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.scanningProgress(progress.scanned, progress.total),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.total == 0
                  ? null
                  : progress.scanned / progress.total,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.close),
              label: Text(l10n.cancelScan),
              onPressed: () =>
                  ref.read(deviceListProvider.notifier).cancelScan(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredText extends StatelessWidget {
  const _CenteredText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}
