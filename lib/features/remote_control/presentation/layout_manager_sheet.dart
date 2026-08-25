import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../remote_control/domain/remote_layout.dart';
import '../../settings/presentation/settings_providers.dart';
import 'layout_editor_screen.dart';

/// Bottom sheet for managing saved custom layouts: open in the editor,
/// rename or delete each one, and create new layouts.
Future<void> showLayoutManagerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => const _LayoutManagerSheet(),
  );
}

class _LayoutManagerSheet extends ConsumerWidget {
  const _LayoutManagerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final layouts = settings?.savedLayouts ?? const [];
    final notifier = ref.read(settingsProvider.notifier);

    Future<void> openEditor(String id) async {
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LayoutEditorScreen(layoutId: id),
        ),
      );
    }

    Future<void> rename(SavedRemoteLayout layout) async {
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) => _RenameDialog(initialName: layout.name),
      );
      if (name == null || name.trim().isEmpty) {
        return;
      }
      await notifier.renameCustomLayout(layout.id, name.trim());
    }

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            l10n.manageLayouts,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (layouts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text(l10n.noSavedDevices)),
            ),
          for (final entry in layouts)
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: Text(entry.name, overflow: TextOverflow.ellipsis),
              onTap: () => openEditor(entry.id),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: l10n.editLayout,
                    onPressed: () => openEditor(entry.id),
                  ),
                  IconButton(
                    icon: const Icon(Icons.drive_file_rename_outline),
                    tooltip: l10n.renameLayoutTitle,
                    onPressed: () => rename(entry),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.removeButton,
                    onPressed: () => notifier.deleteCustomLayout(entry.id),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () async {
              final count = layouts.length;
              final id = await notifier.createCustomLayout(
                '${l10n.layoutCustom} ${count + 1}',
              );
              if (!context.mounted) {
                return;
              }
              await openEditor(id);
            },
            icon: const Icon(Icons.add),
            label: Text(l10n.newLayout),
          ),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.renameLayoutTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.nameLabel),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(materialL10n.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(materialL10n.okButtonLabel),
        ),
      ],
    );
  }
}
