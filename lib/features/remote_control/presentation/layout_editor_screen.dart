import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/remote_key.dart';
import '../domain/remote_layout.dart';
import 'layout_grid_view.dart';
import 'remote_key_icons.dart';

/// Full-screen editor for a saved custom remote layout.
///
/// Items can be dragged to free cells; selecting an item shows small badges
/// on its corners for cycling the size (buttons: 1x1 up to 2x2) and removing
/// it. New items come from the palette in the app bar. Saving persists the
/// arrangement.
class LayoutEditorScreen extends ConsumerStatefulWidget {
  const LayoutEditorScreen({super.key, required this.layoutId});

  final String layoutId;

  @override
  ConsumerState<LayoutEditorScreen> createState() => _LayoutEditorScreenState();
}

class _LayoutEditorScreenState extends ConsumerState<LayoutEditorScreen> {
  static const double _gap = 8;
  static const double _maxGridWidth = 960;
  static const double _cellTarget = 60;

  static const _navigationKeys = <RemoteKey>[
    RemoteKey.up,
    RemoteKey.down,
    RemoteKey.left,
    RemoteKey.right,
    RemoteKey.select,
    RemoteKey.back,
    RemoteKey.exit,
  ];

  static const _basicsKeys = <RemoteKey>[
    RemoteKey.power,
    RemoteKey.mute,
    RemoteKey.info,
    RemoteKey.volumeUp,
    RemoteKey.volumeDown,
    RemoteKey.channelUp,
    RemoteKey.channelDown,
  ];

  static const _pictureAudioKeys = <RemoteKey>[
    RemoteKey.settings,
    RemoteKey.favorites,
    RemoteKey.pictureFormat,
    RemoteKey.pictureMode,
    RemoteKey.audioTrack,
    RemoteKey.subtitleAudio,
    RemoteKey.subtitles,
    RemoteKey.teletext,
  ];

  static const _sizes = [(1, 1), (2, 1), (1, 2), (2, 2)];

  late List<LayoutItem> _items;
  String _name = '';
  int? _selectedIndex;
  int? _dragIndex;
  Offset _dragDelta = Offset.zero;
  (int, int)? _dragPreview;
  bool _showGrid = true;

  /// Rendered width and column count of the grid, captured while building.
  double _gridWidth = _maxGridWidth;
  int _columns = kLayoutGridColumns;

  SavedRemoteLayout? _savedLayout;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull;
    _savedLayout = settings?.savedLayouts
        .where((layout) => layout.id == widget.layoutId)
        .firstOrNull;
    if (_savedLayout != null) {
      _name = _savedLayout!.name;
      _items =
          RemoteGridLayout.tryFromJsonString(
            _savedLayout!.gridJson,
          )?.items.toList() ??
          RemoteGridLayout.defaultTemplate().items.toList();
    } else {
      // The layout was deleted before the screen opened; nothing to edit.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _select(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }

  void _startDrag(int index) {
    final item = _items[index];
    setState(() {
      _dragIndex = index;
      _dragDelta = Offset.zero;
      _dragPreview = (item.row, item.column);
      _selectedIndex = null;
    });
  }

  void _updateDrag(DragUpdateDetails details) {
    final index = _dragIndex;
    if (index == null) {
      return;
    }
    final step =
        LayoutGridView.cellSizeFor(_gridWidth, _gap, columns: _columns) + _gap;
    final item = _items[index];
    setState(() {
      _dragDelta += details.delta;
      var targetRow = (item.row + _dragDelta.dy / step).round();
      var targetColumn = (item.column + _dragDelta.dx / step).round();
      if (targetRow < 0) {
        targetRow = 0;
      }
      if (targetColumn < 0) {
        targetColumn = 0;
      }
      if (targetColumn + item.effectiveColumnSpan > _columns) {
        targetColumn = _columns - item.effectiveColumnSpan;
      }
      _dragPreview = _currentGrid.nearestFreeSpot(
        row: targetRow,
        column: targetColumn,
        rowSpan: item.effectiveRowSpan,
        columnSpan: item.effectiveColumnSpan,
        ignore: item,
      );
    });
  }

  void _endDrag() {
    final index = _dragIndex;
    final preview = _dragPreview;
    if (index == null) {
      return;
    }
    setState(() {
      if (preview != null && index < _items.length) {
        _items[index] = _items[index].moveTo(preview.$1, preview.$2);
      }
      _dragIndex = null;
      _dragDelta = Offset.zero;
      _dragPreview = null;
    });
  }

  RemoteGridLayout get _currentGrid =>
      RemoteGridLayout(_items, columns: _columns);

  void _cycleSize(int index) {
    final item = _items[index];
    if (!item.isKey) {
      return;
    }
    final currentIndex = _sizes.indexWhere(
      (s) => s.$1 == item.effectiveRowSpan && s.$2 == item.effectiveColumnSpan,
    );
    final next = _sizes[(currentIndex + 1) % _sizes.length];
    final movedTo = _currentGrid.nearestFreeSpot(
      row: item.row,
      column: item.column,
      rowSpan: next.$1,
      columnSpan: next.$2,
      ignore: item,
    );
    if (movedTo == null) {
      return;
    }
    setState(() {
      _items[index] = _items[index]
          .moveTo(movedTo.$1, movedTo.$2)
          .resizeTo(next.$1, next.$2);
    });
  }

  void _remove(int index) {
    setState(() {
      _items.removeAt(index);
      _selectedIndex = null;
    });
  }

  void _addItem(LayoutItem candidate) {
    final spot = _currentGrid.firstFreeSpot(
      candidate.effectiveRowSpan,
      candidate.effectiveColumnSpan,
    );
    if (spot == null) {
      return;
    }
    setState(() {
      _items.add(candidate.moveTo(spot.$1, spot.$2));
    });
  }

  void _resetLayout() {
    setState(() {
      _items = RemoteGridLayout.defaultTemplate().items.toList();
      _selectedIndex = null;
    });
  }

  Future<void> _save() async {
    final json = jsonEncode(_currentGrid.toJson());
    await ref
        .read(settingsProvider.notifier)
        .saveCustomLayout(widget.layoutId, json);
    if (!mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.layoutSaved),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_name.isEmpty ? l10n.editLayout : _name),
        actions: [
          IconButton(
            icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: _showGrid ? l10n.hideGrid : l10n.showGrid,
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addToLayout,
            onPressed: () => _openPalette(context, l10n),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: l10n.resetLayout,
            onPressed: _resetLayout,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: MaterialLocalizations.of(context).saveButtonLabel,
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxGridWidth),
            child: LayoutBuilder(
              builder: (context, constraints) {
                _gridWidth = constraints.maxWidth;
                _columns = RemoteGridLayout.suggestedColumnCount(
                  _gridWidth,
                  _gap,
                  cellTarget: _cellTarget,
                );
                final grid = _currentGrid;
                final cell = LayoutGridView.cellSizeFor(
                  _gridWidth,
                  _gap,
                  columns: _columns,
                );
                return LayoutGridView(
                  gap: _gap,
                  grid: grid,
                  itemBuilder: (context, item) =>
                      _buildEditableItem(context, item),
                  offsetOverride: (item, origin) =>
                      _items.indexOf(item) == _dragIndex
                      ? origin + _dragDelta
                      : origin,
                  underlayBuilder: (context) =>
                      _showGrid ? _buildGuides(grid, cell) : const [],
                  overlayBuilder: (context) => [
                    if (_dragPreview case (final row, final column)?
                        when _dragIndex != null)
                      Positioned(
                        left: column * (cell + _gap),
                        top: row * (cell + _gap),
                        width: LayoutGridView.sizeOf(
                          _items[_dragIndex!],
                          cell,
                          _gap,
                        ).width,
                        height: LayoutGridView.sizeOf(
                          _items[_dragIndex!],
                          cell,
                          _gap,
                        ).height,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Faint per-cell guides rendered under the items.
  List<Widget> _buildGuides(RemoteGridLayout grid, double cell) {
    final rows = LayoutGridView.rowCountFor(grid);
    final lineColor = Theme.of(context).dividerColor.withValues(alpha: 0.4);
    return [
      for (var row = 0; row < rows; row++)
        for (var column = 0; column < grid.columns; column++)
          Positioned(
            left: column * (cell + _gap),
            top: row * (cell + _gap),
            width: cell,
            height: cell,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: lineColor),
              ),
            ),
          ),
    ];
  }

  Widget _buildEditableItem(BuildContext context, LayoutItem item) {
    final index = _items.indexOf(item);
    if (index < 0) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedIndex == index;
    final dragging = _dragIndex == index;

    Widget content;
    if (item.isKey) {
      final longestSpan = item.effectiveRowSpan > item.effectiveColumnSpan
          ? item.effectiveRowSpan
          : item.effectiveColumnSpan;
      content = Tooltip(
        message: remoteKeyLabel(item.remoteKey!, l10n),
        child: SizedBox.expand(
          child: IconButton.filled(
            iconSize: 20.0 + 4.0 * (longestSpan - 1),
            onPressed: () => _select(index),
            icon: Icon(remoteKeyIcon(item.remoteKey!)),
          ),
        ),
      );
    } else {
      final theme = Theme.of(context);
      content = Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_blockIcon(item.block!), size: 16),
              const SizedBox(width: 6),
              Flexible(child: Text(_blockLabel(item.block!, l10n))),
            ],
          ),
        ),
      );
    }
    if (selected || dragging) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
        child: content,
      );
    }
    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _select(index),
            onPanStart: (_) => _startDrag(index),
            onPanUpdate: _updateDrag,
            onPanEnd: (_) => _endDrag(),
            child: content,
          ),
          if (selected && !dragging) ...[
            Positioned(top: -9, left: -9, child: _removeBadge(l10n)),
            if (item.isKey)
              Positioned(top: -9, right: -9, child: _sizeBadge(l10n)),
          ],
        ],
      ),
    );
  }

  Widget _removeBadge(AppLocalizations l10n) => _cornerBadge(
    icon: Icons.close,
    tooltip: l10n.removeButton,
    onTap: () => _remove(_selectedIndex!),
  );

  Widget _sizeBadge(AppLocalizations l10n) => _cornerBadge(
    icon: Icons.zoom_out_map,
    tooltip: l10n.buttonSize,
    onTap: () => _cycleSize(_selectedIndex!),
  );

  Widget _cornerBadge({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        elevation: 2,
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 15),
          ),
        ),
      ),
    );
  }

  IconData _blockIcon(LayoutBlock block) => switch (block) {
    LayoutBlock.tvStatus => Icons.tv,
    LayoutBlock.digitsPad => Icons.dialpad,
    LayoutBlock.sleepTimer => Icons.bedtime,
  };

  String _blockLabel(LayoutBlock block, AppLocalizations l10n) =>
      switch (block) {
        LayoutBlock.tvStatus => l10n.blockTvStatus,
        LayoutBlock.digitsPad => l10n.blockDigitsPad,
        LayoutBlock.sleepTimer => l10n.sleepTimer,
      };

  Future<void> _openPalette(BuildContext context, AppLocalizations l10n) {
    void addAndClose(LayoutItem candidate) {
      Navigator.of(context).pop();
      _addItem(candidate);
    }

    Widget section(String title, List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );

    Widget keyChip(RemoteKey key) => ActionChip(
      avatar: Icon(remoteKeyIcon(key), size: 18),
      label: Text(remoteKeyLabel(key, l10n)),
      tooltip: remoteKeyLabel(key, l10n),
      onPressed: () =>
          addAndClose(LayoutItem.key(remoteKey: key, row: 0, column: 0)),
    );

    Widget blockChip(String label, IconData icon, LayoutBlock block) {
      return ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        tooltip: label,
        onPressed: () =>
            addAndClose(LayoutItem.block(block: block, row: 0, column: 0)),
      );
    }

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              l10n.addToLayout,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            section(l10n.keyGroupBasics, [
              for (final key in _basicsKeys) keyChip(key),
            ]),
            section(l10n.keyGroupNavigation, [
              for (final key in _navigationKeys) keyChip(key),
            ]),
            section(l10n.keyGroupPictureAudio, [
              for (final key in _pictureAudioKeys) keyChip(key),
            ]),
            section(l10n.layoutBlocks, [
              blockChip(l10n.blockTvStatus, Icons.tv, LayoutBlock.tvStatus),
              blockChip(
                l10n.blockDigitsPad,
                Icons.dialpad,
                LayoutBlock.digitsPad,
              ),
              blockChip(l10n.sleepTimer, Icons.bedtime, LayoutBlock.sleepTimer),
            ]),
          ],
        ),
      ),
    );
  }
}
