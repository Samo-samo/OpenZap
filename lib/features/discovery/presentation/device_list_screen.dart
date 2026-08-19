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
                final extras = [
                  for (final device in saved)
                    if (!knownIps.contains(device.ipAddress)) device,
                ];
                return ListView(
                  children: [
                    if (lastDevice != null) ...[
                      _RecentDeviceTile(
                        device: lastDevice,
                        onTap: () => _selectDevice(context, ref, lastDevice),
                      ),
                      const Divider(),
                    ],
                    for (final device in [...list, ...extras])
                      _DeviceTile(
                        device: device,
                        onTap: () => _selectDevice(context, ref, device),
                      ),
                    if (list.isEmpty && extras.isEmpty && lastDevice == null)
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
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onTap});

  final DiscoveredDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.tv),
      title: Text(device.name),
      subtitle: Text(
        device.model == null
            ? device.ipAddress
            : '${device.ipAddress} · ${device.model}',
      ),
      trailing: const Icon(Icons.chevron_right),
      mouseCursor: SystemMouseCursors.click,
      onTap: onTap,
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
  const _RecentDeviceTile({required this.device, required this.onTap});

  final DiscoveredDevice device;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        leading: const Icon(Icons.connected_tv),
        title: Text(l10n.recentDevice),
        subtitle: Text('${device.name}\n${device.ipAddress}'),
        trailing: const Icon(Icons.chevron_right),
        mouseCursor: SystemMouseCursors.click,
        onTap: onTap,
      ),
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
