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

  /// (code, guess) — guesses are from the node-red keymap; verify on-device.
  static const _presets = <(int, String)>[
    (1063, 'YouTube'),
    (1064, 'Netflix'),
    (1046, 'Portal'),
    (1056, 'HDMI / Input'),
    (1065, 'Web browser'),
  ];

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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (code, guess) in _presets)
                ActionChip(
                  avatar: const Icon(Icons.key, size: 16),
                  label: Text('$code · $guess'),
                  mouseCursor: SystemMouseCursors.click,
                  onPressed: () => _send(code),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
