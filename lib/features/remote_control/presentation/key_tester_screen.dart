import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/remote_control_error.dart';

/// Raw-key tester used to discover and verify remote key codes on the device.
///
/// Sends an arbitrary numeric code through [RemoteControl.sendCode] and offers
/// the known shortcut keys as presets. Feedback is always shown so codes can
/// be probed from the TV room.
class KeyTesterScreen extends ConsumerStatefulWidget {
  const KeyTesterScreen({super.key});

  @override
  ConsumerState<KeyTesterScreen> createState() => _KeyTesterScreenState();
}

class _KeyTesterScreenState extends ConsumerState<KeyTesterScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _sendCodeFromInput() {
    final code = int.tryParse(_codeController.text.trim());
    if (code != null) {
      _send(code);
    }
  }

  Future<void> _send(int code) async {
    final remote = ref.read(remoteControlProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (remote == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.noDeviceSelected)));
      return;
    }
    try {
      await remote.sendCode(code);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.keySent(code)),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 1),
          ),
        );
    } on RemoteControlException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${l10n.commandFailed} ${e.message}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.keyTesterTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: l10n.keyCodeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendCodeFromInput(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _sendCodeFromInput,
                icon: const Icon(Icons.send),
                label: Text(l10n.sendKey),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(l10n.presetKeys, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ..._buildGroups(l10n),
        ],
      ),
    );
  }

  /// All confirmed codes as reference groups; every code is tappable to send
  /// it again (e.g. to re-verify a function).
  List<Widget> _buildGroups(AppLocalizations l10n) {
    return [
      for (final (title, entries) in _confirmedCodes(l10n)) ...[
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (code, label) in entries)
              ActionChip(
                avatar: const Icon(Icons.key, size: 16),
                label: Text('$code · $label'),
                mouseCursor: SystemMouseCursors.click,
                onPressed: () => _send(code),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

  /// (group title, (code, label)) pairs for every code confirmed on the TV.
  List<(String, List<(int, String)>)> _confirmedCodes(AppLocalizations l10n) {
    return [
      (
        l10n.keyGroupNavigation,
        [
          for (var digit = 0; digit <= 9; digit++) (1000 + digit, '$digit'),
          (1010, l10n.tooltipBack),
          (1012, l10n.tooltipPower),
          (1013, l10n.tooltipMute),
          (1016, l10n.tooltipVolumeUp),
          (1017, l10n.tooltipVolumeDown),
          (1018, l10n.tooltipInfo),
          (1019, l10n.tooltipUp),
          (1020, l10n.tooltipDown),
          (1021, l10n.tooltipLeft),
          (1022, l10n.tooltipRight),
          (1032, l10n.tooltipChannelUp),
          (1033, l10n.tooltipChannelDown),
          (1037, l10n.tooltipExit),
          (1053, l10n.tooltipOk),
          (1053, l10n.keyNameHome),
        ],
      ),
      (
        l10n.keyGroupAppsInputs,
        [
          (1046, l10n.keyNameFastAccess),
          (1056, l10n.keyNameSourceList),
          (1062, l10n.appYouTube),
          (1064, l10n.appNetflix),
          (1065, l10n.keyNameWebBrowser),
          (1063, l10n.keyNameNetworkType),
          (1055, l10n.keyNameHybrid),
        ],
      ),
      (
        l10n.keyGroupPictureAudio,
        [
          (1011, l10n.tooltipPictureFormat),
          (1014, l10n.tooltipPictureMode),
          (1015, l10n.tooltipSubtitleAudio),
          (1031, l10n.tooltipSubtitles),
          (1035, l10n.tooltipAudioTrack),
          (1040, l10n.tooltipFavorites),
          (1060, l10n.tooltipTeletext),
          (1066, l10n.tooltipSettings),
        ],
      ),
    ];
  }
}
