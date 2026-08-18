import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/remote_control_error.dart';
import '../domain/remote_key.dart';

class RemoteScreen extends ConsumerWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final device = ref.watch(selectedDeviceProvider);

    if (device == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.noDeviceSelected)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(device.name)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RemoteButton(
                      remoteKey: RemoteKey.power,
                      icon: Icons.power_settings_new,
                      tooltip: l10n.tooltipPower,
                    ),
                    _RemoteButton(
                      remoteKey: RemoteKey.mute,
                      icon: Icons.volume_off,
                      tooltip: l10n.tooltipMute,
                    ),
                    _RemoteButton(
                      remoteKey: RemoteKey.info,
                      icon: Icons.info_outline,
                      tooltip: l10n.tooltipInfo,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RemoteButton(
                      remoteKey: RemoteKey.volumeDown,
                      icon: Icons.volume_down,
                      tooltip: l10n.tooltipVolumeDown,
                    ),
                    _RemoteButton(
                      remoteKey: RemoteKey.volumeUp,
                      icon: Icons.volume_up,
                      tooltip: l10n.tooltipVolumeUp,
                    ),
                    _RemoteButton(
                      remoteKey: RemoteKey.channelDown,
                      icon: Icons.remove,
                      tooltip: l10n.tooltipChannelDown,
                    ),
                    _RemoteButton(
                      remoteKey: RemoteKey.channelUp,
                      icon: Icons.add,
                      tooltip: l10n.tooltipChannelUp,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDirectionalPad(l10n),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _RemoteButton(
                      remoteKey: RemoteKey.back,
                      icon: Icons.arrow_back,
                      tooltip: l10n.tooltipBack,
                    ),
                    _RemoteButton(
                      remoteKey: RemoteKey.exit,
                      icon: Icons.cancel_outlined,
                      tooltip: l10n.tooltipExit,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDigits(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionalPad(AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RemoteButton(
          remoteKey: RemoteKey.up,
          icon: Icons.keyboard_arrow_up,
          tooltip: l10n.tooltipUp,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RemoteButton(
              remoteKey: RemoteKey.left,
              icon: Icons.keyboard_arrow_left,
              tooltip: l10n.tooltipLeft,
            ),
            _RemoteButton(
              remoteKey: RemoteKey.select,
              icon: Icons.circle_outlined,
              tooltip: l10n.tooltipOk,
            ),
            _RemoteButton(
              remoteKey: RemoteKey.right,
              icon: Icons.keyboard_arrow_right,
              tooltip: l10n.tooltipRight,
            ),
          ],
        ),
        _RemoteButton(
          remoteKey: RemoteKey.down,
          icon: Icons.keyboard_arrow_down,
          tooltip: l10n.tooltipDown,
        ),
      ],
    );
  }

  Widget _buildDigits() {
    const digits = <RemoteKey>[
      RemoteKey.digit1,
      RemoteKey.digit2,
      RemoteKey.digit3,
      RemoteKey.digit4,
      RemoteKey.digit5,
      RemoteKey.digit6,
      RemoteKey.digit7,
      RemoteKey.digit8,
      RemoteKey.digit9,
      RemoteKey.digit0,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [for (final digit in digits) _DigitButton(digit)],
    );
  }
}

class _RemoteButton extends ConsumerWidget {
  const _RemoteButton({
    required this.remoteKey,
    required this.icon,
    required this.tooltip,
  });

  final RemoteKey remoteKey;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(remoteControlProvider);
    return Tooltip(
      message: tooltip,
      child: IconButton.filled(
        iconSize: 28,
        onPressed: remote == null
            ? null
            : () => _sendKey(context, ref, remoteKey),
        icon: Icon(icon),
      ),
    );
  }
}

class _DigitButton extends ConsumerWidget {
  const _DigitButton(this.remoteKey);

  final RemoteKey remoteKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remote = ref.watch(remoteControlProvider);
    return SizedBox(
      width: 64,
      child: FilledButton(
        onPressed: remote == null
            ? null
            : () => _sendKey(context, ref, remoteKey),
        child: Text(_digitLabel(remoteKey)),
      ),
    );
  }
}

/// Returns the digit for a digit key (enum order keeps digit0..digit9
/// consecutive).
String _digitLabel(RemoteKey key) =>
    '${key.index - RemoteKey.digit0.index}';

Future<void> _sendKey(
  BuildContext context,
  WidgetRef ref,
  RemoteKey key,
) async {
  final remote = ref.read(remoteControlProvider);
  if (remote == null) {
    return;
  }
  final messenger = ScaffoldMessenger.of(context);
  try {
    await remote.sendKey(key);
  } on RemoteControlException catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text(e.message)),
    );
  }
}