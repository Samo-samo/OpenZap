import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/remote_key.dart';
import '../domain/remote_layout.dart';
import 'free_layout_view.dart';
import 'remote_key_icons.dart';

/// Full-screen editor for a saved custom remote layout.
///
/// Tiles are freely arranged on a canvas: drag to move (with alignment
/// guides), resize with the corner handle (mouse and touch) or with a
/// two-finger pinch (touch), remove with the top-left badge, and add new
/// tiles from the palette in the app bar. Saving persists the arrangement.
class LayoutEditorScreen extends ConsumerStatefulWidget {
  const LayoutEditorScreen({super.key, required this.layoutId});

  final String layoutId;

  @override
  ConsumerState<LayoutEditorScreen> createState() => _LayoutEditorScreenState();
}

class _LayoutEditorScreenState extends ConsumerState<LayoutEditorScreen> {
  static const double _maxCanvasWidth = 960;

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

  List<LayoutItem> _items = [];
  String _name = '';
  int? _selectedIndex;

  /// Whether resize operations preserve the tile's aspect ratio.
  bool _lockAspect = true;

  /// Whether dragged tiles snap to alignment guides.
  bool _snapEnabled = true;

  // Move-drag state.
  int? _dragIndex;
  Offset _dragStart = Offset.zero;
  Offset _dragDelta = Offset.zero;
  AlignmentSnap _snap = AlignmentSnap.none;

  // Resize-handle state (pointer id tracked so multi-touch stays sane).
  int? _resizePointer;
  int? _resizeIndex;
  Offset _resizeStartLocal = Offset.zero;
  (double, double)? _resizeBase;

  // Pinch state: exactly two pointers scale the target tile.
  final Map<int, Offset> _pinchPointers = {};
  int? _pinchIndex;
  double _pinchStartDist = 0;
  (double, double)? _pinchBase;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull;
    final saved = settings?.savedLayouts
        .where((layout) => layout.id == widget.layoutId)
        .firstOrNull;
    if (saved != null) {
      _name = saved.name;
      _items =
          FreeRemoteLayout.tryFromJsonString(saved.gridJson)?.items.toList() ??
          FreeRemoteLayout.defaultTemplate().items.toList();
    } else {
      // The layout was deleted before the screen opened; nothing to edit.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  RenderBox? get _canvasBox =>
      _canvasKey.currentContext?.findRenderObject() as RenderBox?;

  // ----- selection -----

  void _select(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }

  // ----- move -----

  void _startDrag(int index, DragStartDetails details) {
    // A drag starting on the resize handle belongs to the handle. The badge
    // is a ~25px circle overflowing the tile's bottom-right corner, so the
    // skip zone covers that corner.
    final box = _canvasBox;
    if (box == null) {
      return;
    }
    if (_selectedIndex == index && index < _items.length) {
      final local = box.globalToLocal(details.globalPosition);
      final item = _items[index];
      if (local.dx >= item.right - 26 && local.dy >= item.bottom - 26) {
        return;
      }
    }
    final item = _items[index];
    setState(() {
      _dragIndex = index;
      _dragStart = Offset(item.x, item.y);
      _dragDelta = Offset.zero;
      _snap = AlignmentSnap.none;
      _selectedIndex = null;
    });
  }

  void _updateDrag(DragUpdateDetails details) {
    final index = _dragIndex;
    if (index == null || index >= _items.length) {
      return;
    }
    // A simultaneous pinch owns the gesture.
    if (_pinchIndex != null) {
      return;
    }
    final item = _items[index];
    setState(() {
      _dragDelta += details.delta;
      var x = (_dragStart.dx + _dragDelta.dx)
          .clamp(0, kMaxCanvasExtent)
          .toDouble();
      var y = (_dragStart.dy + _dragDelta.dy)
          .clamp(0, kMaxCanvasExtent)
          .toDouble();
      final candidate = item.moveTo(x, y);
      _snap = _snapEnabled
          ? AlignmentSnap.compute(
              moving: candidate,
              others: _items,
              ignore: item,
            )
          : AlignmentSnap.none;
      x = (x + _snap.dx).clamp(0, kMaxCanvasExtent).toDouble();
      y = (y + _snap.dy).clamp(0, kMaxCanvasExtent).toDouble();
      _items[index] = item.moveTo(x, y);
    });
  }

  void _endDrag() {
    if (_dragIndex == null) {
      return;
    }
    setState(() {
      _dragIndex = null;
      _dragDelta = Offset.zero;
      _snap = AlignmentSnap.none;
    });
  }

  // ----- resize handle (mouse + touch) -----

  void _beginResize(int index, int pointer, Offset globalPosition) {
    if (_resizePointer != null || index >= _items.length) {
      return;
    }
    final box = _canvasBox;
    if (box == null) {
      return;
    }
    final item = _items[index];
    setState(() {
      _resizePointer = pointer;
      _resizeIndex = index;
      _resizeStartLocal = box.globalToLocal(globalPosition);
      _resizeBase = (item.width, item.height);
    });
  }

  void _updateResize(int pointer, Offset globalPosition) {
    final index = _resizeIndex;
    if (_resizePointer != pointer || index == null) {
      return;
    }
    final box = _canvasBox;
    final base = _resizeBase;
    if (box == null || base == null) {
      return;
    }
    if (index >= _items.length) {
      return;
    }
    final local = box.globalToLocal(globalPosition);
    final dw = local.dx - _resizeStartLocal.dx;
    final dh = local.dy - _resizeStartLocal.dy;
    double width;
    double height;
    if (_lockAspect) {
      // Uniform scale from the dominant axis, preserving the ratio.
      final scaleW = (base.$1 + dw) / base.$1;
      final scaleH = (base.$2 + dh) / base.$2;
      final scale = scaleW > scaleH ? scaleW : scaleH;
      width = (base.$1 * scale)
          .clamp(kMinTileExtent, kMaxTileExtent)
          .toDouble();
      height = (base.$2 * scale)
          .clamp(kMinTileExtent, kMaxTileExtent)
          .toDouble();
    } else {
      width = (base.$1 + dw).clamp(kMinTileExtent, kMaxTileExtent).toDouble();
      height = (base.$2 + dh).clamp(kMinTileExtent, kMaxTileExtent).toDouble();
    }
    setState(() {
      _items[index] = _items[index].resizeTo(width, height);
    });
  }

  void _endResize(int pointer) {
    if (_resizePointer == pointer) {
      setState(() {
        _resizePointer = null;
        _resizeIndex = null;
        _resizeBase = null;
      });
    }
  }

  // ----- pinch resize (touch): two pointers scale the selected tile -----

  void _pinchDown(int pointer, Offset globalPosition) {
    _pinchPointers[pointer] = globalPosition;
    if (_pinchPointers.length != 2 || _pinchIndex != null) {
      return;
    }
    var target = _selectedIndex;
    target ??= _topmostTileAt(globalPosition);
    if (target == null) {
      _pinchPointers.clear();
      return;
    }
    final positions = _pinchPointers.values.toList();
    final item = _items[target];
    setState(() {
      _pinchIndex = target;
      _selectedIndex = target;
      _pinchStartDist = (positions[0] - positions[1]).distance;
      _pinchBase = (item.width, item.height);
    });
  }

  void _pinchMove(int pointer, Offset globalPosition) {
    if (!_pinchPointers.containsKey(pointer)) {
      return;
    }
    _pinchPointers[pointer] = globalPosition;
    final index = _pinchIndex;
    final base = _pinchBase;
    if (index == null || base == null || _pinchPointers.length != 2) {
      return;
    }
    if (index >= _items.length) {
      return;
    }
    final positions = _pinchPointers.values.toList();
    final dist = (positions[0] - positions[1]).distance;
    if (_pinchStartDist <= 0 || dist <= 0) {
      return;
    }
    final factor = dist / _pinchStartDist;
    setState(() {
      _items[index] = _items[index].resizeTo(
        (base.$1 * factor).clamp(kMinTileExtent, kMaxTileExtent).toDouble(),
        (base.$2 * factor).clamp(kMinTileExtent, kMaxTileExtent).toDouble(),
      );
    });
  }

  void _pinchUp(int pointer) {
    _pinchPointers.remove(pointer);
    if (_pinchPointers.length < 2 && _pinchIndex != null) {
      setState(() {
        _pinchIndex = null;
        _pinchBase = null;
      });
    }
  }

  /// Topmost item containing [globalPosition], or null.
  int? _topmostTileAt(Offset globalPosition) {
    final box = _canvasBox;
    if (box == null) {
      return null;
    }
    final local = box.globalToLocal(globalPosition);
    for (var i = _items.length - 1; i >= 0; i--) {
      final item = _items[i];
      if (local.dx >= item.left &&
          local.dx <= item.right &&
          local.dy >= item.top &&
          local.dy <= item.bottom) {
        return i;
      }
    }
    return null;
  }

  // ----- palette / reset / save -----

  void _addItem(LayoutItem Function(double x, double y) factory) {
    final (x, y) = FreeRemoteLayout(_items).appendSpot();
    setState(() {
      _items.add(factory(x, y));
    });
  }

  void _remove(int index) {
    setState(() {
      _items.removeAt(index);
      _selectedIndex = null;
    });
  }

  void _resetLayout() {
    setState(() {
      _items = FreeRemoteLayout.defaultTemplate().items.toList();
      _selectedIndex = null;
    });
  }

  Future<void> _save() async {
    final json = jsonEncode(FreeRemoteLayout(_items).toJson());
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxCanvasWidth),
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (event) =>
                        _pinchDown(event.pointer, event.position),
                    onPointerMove: (event) =>
                        _pinchMove(event.pointer, event.position),
                    onPointerUp: (event) => _pinchUp(event.pointer),
                    onPointerCancel: (event) => _pinchUp(event.pointer),
                    child: Container(
                      key: _canvasKey,
                      child: FreeLayoutView(
                        layout: FreeRemoteLayout(_items),
                        itemBuilder: (context, index, item) =>
                            _buildEditableItem(context, index, item),
                        underlayBuilder: (context) => _buildGuides(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _buildToolbar(l10n),
        ],
      ),
    );
  }

  /// Bottom toolbar with the editor-wide toggles and the selected tile name.
  /// Identical on touch and desktop.
  Widget _buildToolbar(AppLocalizations l10n) {
    final index = _selectedIndex;
    final String? label = index != null && index >= 0 && index < _items.length
        ? (_items[index].isKey
              ? remoteKeyLabel(_items[index].remoteKey!, l10n)
              : _blockLabel(_items[index].block!, l10n))
        : null;
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              if (label != null)
                Expanded(child: Text(label, overflow: TextOverflow.ellipsis))
              else
                const Spacer(),
              FilterChip(
                avatar: const Icon(Icons.aspect_ratio, size: 18),
                label: Text(l10n.aspectLock),
                tooltip: l10n.aspectLock,
                selected: _lockAspect,
                onSelected: (value) => setState(() => _lockAspect = value),
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: const Icon(Icons.align_horizontal_center, size: 18),
                label: Text(l10n.snapGuides),
                tooltip: l10n.snapGuides,
                selected: _snapEnabled,
                onSelected: (value) => setState(() => _snapEnabled = value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Alignment guide lines for the in-progress drag.
  List<Widget> _buildGuides() {
    if (_dragIndex == null) {
      return const [];
    }
    final color = Theme.of(context).colorScheme.primary;
    return [
      for (final x in _snap.verticalLines)
        Positioned(
          left: x,
          top: 0,
          bottom: 0,
          width: 1,
          child: ColoredBox(color: color),
        ),
      for (final y in _snap.horizontalLines)
        Positioned(
          top: y,
          left: 0,
          right: 0,
          height: 1,
          child: ColoredBox(color: color),
        ),
    ];
  }

  Widget _buildEditableItem(BuildContext context, int index, LayoutItem item) {
    if (index < 0 || index >= _items.length) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final selected = _selectedIndex == index;
    final dragging = _dragIndex == index;

    Widget content;
    if (item.isKey) {
      final iconSize =
          (item.width < item.height ? item.width : item.height) * 0.42;
      content = Tooltip(
        message: remoteKeyLabel(item.remoteKey!, l10n),
        child: SizedBox.expand(
          child: IconButton.filled(
            iconSize: iconSize.clamp(18, 40),
            onPressed: () => _select(index),
            icon: Icon(remoteKeyIcon(item.remoteKey!)),
          ),
        ),
      );
    } else {
      final theme = Theme.of(context);
      content = ClipRect(
        child: Container(
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
            onPanStart: (details) => _startDrag(index, details),
            onPanUpdate: _updateDrag,
            onPanEnd: (_) => _endDrag(),
            onPanCancel: _endDrag,
            child: content,
          ),
          if (selected && !dragging)
            Positioned(
              top: -11,
              left: -11,
              child: _cornerBadge(
                icon: Icons.close,
                tooltip: l10n.removeButton,
                onTap: () => _remove(index),
              ),
            ),
          if (selected && !dragging)
            Positioned(
              bottom: -11,
              right: -11,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) =>
                    _beginResize(index, event.pointer, event.position),
                onPointerMove: (event) =>
                    _updateResize(event.pointer, event.position),
                onPointerUp: (event) => _endResize(event.pointer),
                onPointerCancel: (event) => _endResize(event.pointer),
                child: _cornerBadge(
                  icon: Icons.open_in_full,
                  tooltip: l10n.resizeButton,
                  onTap: () {},
                ),
              ),
            ),
        ],
      ),
    );
  }

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
    void addAndClose(LayoutItem Function(double x, double y) factory) {
      Navigator.of(context).pop();
      _addItem(factory);
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
          addAndClose((x, y) => LayoutItem.key(remoteKey: key, x: x, y: y)),
    );

    Widget blockChip(String label, IconData icon, LayoutBlock block) {
      final (defaultW, defaultH) = kLayoutBlockSizes[block]!;
      return ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        tooltip: label,
        onPressed: () => addAndClose(
          (x, y) => LayoutItem.block(
            block: block,
            x: x,
            y: y,
            width: defaultW,
            height: defaultH,
          ),
        ),
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
