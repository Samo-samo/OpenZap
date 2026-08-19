import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/domain/app_settings.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../sleep_timer/presentation/sleep_timer_provider.dart';
import '../../tv_status/domain/tv_status.dart';
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
                const _TvStatusChip(),
                const SizedBox(height: 12),
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
                const SizedBox(height: 16),
                const _SleepTimerControl(),
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

class _SleepTimerControl extends ConsumerWidget {
  const _SleepTimerControl();

  static const _options = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(minutes: 45),
    Duration(minutes: 60),
    Duration(minutes: 90),
    Duration(minutes: 120),
  ];
  static const _customSentinel = Duration(days: 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final remaining = ref.watch(sleepTimerProvider);
    if (remaining != null) {
      final minutes = remaining.inMinutes;
      final seconds = remaining.inSeconds % 60;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bedtime),
          const SizedBox(width: 8),
          Text(
            '${l10n.sleepTimerRemaining} '
            '${minutes.toString().padLeft(2, '0')}:'
            '${seconds.toString().padLeft(2, '0')}',
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.cancelSleepTimer,
            onPressed: () => ref.read(sleepTimerProvider.notifier).cancel(),
          ),
        ],
      );
    }
    return PopupMenuButton<Duration>(
      tooltip: l10n.sleepTimer,
      itemBuilder: (_) => [
        for (final option in _options)
          PopupMenuItem(
            value: option,
            child: Text(l10n.sleepTimerMinutes(option.inMinutes)),
          ),
        PopupMenuItem(
          value: _customSentinel,
          child: Text(l10n.sleepTimerCustom),
        ),
      ],
      onSelected: (duration) {
        if (duration == _customSentinel) {
          _pickCustom(context, ref);
        } else {
          ref.read(sleepTimerProvider.notifier).start(duration);
        }
      },
      child: Chip(
        avatar: const Icon(Icons.bedtime),
        label: Text(l10n.sleepTimer),
        mouseCursor: SystemMouseCursors.click,
      ),
    );
  }

  Future<void> _pickCustom(BuildContext context, WidgetRef ref) async {
    final duration = await showDialog<Duration>(
      context: context,
      builder: (_) => const _CustomSleepTimerDialog(),
    );
    if (duration != null) {
      ref.read(sleepTimerProvider.notifier).start(duration);
    }
  }
}

class _CustomSleepTimerDialog extends StatefulWidget {
  const _CustomSleepTimerDialog();

  @override
  State<_CustomSleepTimerDialog> createState() =>
      _CustomSleepTimerDialogState();
}

class _CustomSleepTimerDialogState extends State<_CustomSleepTimerDialog> {
  static const double _minMinutes = 5;
  static const double _maxMinutes = 360;

  double _minutes = 30;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.customSleepTimerTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.sleepTimerMinutes(_minutes.round())),
          Slider(
            value: _minutes,
            min: _minMinutes,
            max: _maxMinutes,
            divisions: (_maxMinutes - _minMinutes) ~/ 5,
            label: l10n.sleepTimerMinutes(_minutes.round()),
            onChanged: (value) => setState(() => _minutes = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(materialL10n.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(Duration(minutes: _minutes.round())),
          child: Text(materialL10n.okButtonLabel),
        ),
      ],
    );
  }
}

class _TvStatusChip extends ConsumerWidget {
  const _TvStatusChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final status = ref.watch(tvStatusProvider).valueOrNull;
    final state = status?.powerState ?? TvPowerState.unknown;
    final (label, color) = switch (state) {
      TvPowerState.on => (l10n.tvStatusOn, Colors.green),
      TvPowerState.off => (l10n.tvStatusOff, Colors.red),
      TvPowerState.unknown => (l10n.tvStatusUnknown, Colors.grey),
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.circle, size: 12, color: color),
        const SizedBox(width: 8),
        Text(label),
      ],
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
  final l10n = AppLocalizations.of(context)!;
  final feedback =
      ref.read(settingsProvider).valueOrNull?.commandFeedback ??
          CommandFeedback.errorsOnly;
  try {
    await remote.sendKey(key);
    if (feedback == CommandFeedback.all) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.commandSent),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 1),
          ),
        );
    }
  } on RemoteControlException catch (e) {
    if (feedback != CommandFeedback.none) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${l10n.commandFailed}: ${e.message}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
    }
  }
}