import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../remote_control/presentation/remote_screen.dart';
import '../domain/discovered_device.dart';
import 'discovery_providers.dart';

class DeviceListScreen extends ConsumerWidget {
  const DeviceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final devices = ref.watch(deviceListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: devices.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _CenteredText('${l10n.noDevicesFound}\n$error'),
        data: (list) => list.isEmpty
            ? _CenteredText(l10n.noDevicesFound)
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final device = list[index];
                  return ListTile(
                    leading: const Icon(Icons.tv),
                    title: Text(device.name),
                    subtitle: Text(
                      device.model == null
                          ? device.ipAddress
                          : '${device.ipAddress} · ${device.model}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _selectDevice(context, ref, device),
                  );
                },
              ),
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
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RemoteScreen()),
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