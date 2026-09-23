import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  static const _appsInputsKeys = <RemoteKey>[
    RemoteKey.youTube,
    RemoteKey.netflix,
    RemoteKey.fastAccess,
    RemoteKey.sourceList,
    RemoteKey.webBrowser,
    RemoteKey.networkType,
    RemoteKey.hybridBroadcast,
    RemoteKey.showCurrent,
  ];

  List<LayoutItem> _items = [];
  String _name = '';
  int? _selectedIndex;

  /// Whether resize operations preserve the tile's aspect ratio.
  bool _lockAspect = true;

  /// Whether dragged tiles snap to alignment guides.
  bool _snapEnabled = true;

  /// Undo/redo history of tile arrangements (bounded).
  static const int _historyLimit = 30;
  final List<List<LayoutItem>> _undoStack = [];
  final List<List<LayoutItem>> _redoStack = [];

  // Move-drag state.
  //
  // Pointer down is tracked with a raw Listener (so the page scroll locks
  // before the scrollable can claim the gesture), while moves go through
  // the tile's pan recognizer: once it wins the arena it keeps receiving
  // every move even when the tile jumps away from under the finger
  // (pointer capture), which a raw Listener cannot do.
  int? _dragIndex;
  int? _dragPointer;
  Offset _dragStart = Offset.zero;
  Offset _dragDelta = Offset.zero;
  AlignmentSnap _snap = AlignmentSnap.none;

  /// While true, page scrolling is locked (a tile gesture is in progress).
  bool _scrollLock = false;

  // Resize-handle state (pointer id tracked so multi-touch stays sane).
  int? _resizePointer;
  int? _resizeIndex;
  Offset _resizeStartLocal = Offset.zero;
  (double, double)? _resizeBase;

  // Latest resize snap, used to draw guide lines while resizing.
  SizeSnap? _sizeSnap;

  // Pinch state: exactly two pointers scale the target tile.
  final Map<int, Offset> _pinchPointers = {};
  int? _pinchIndex;
  double _pinchStartDist = 0;
  (double, double)? _pinchBase;

  /// True while a two-finger gesture zooms the canvas instead of a tile.
  bool _pinchCanvas = false;
  double _zoomStart = 1;

  /// Canvas zoom level (desktop: Ctrl+wheel, touch: pinch on empty area).
  double _zoom = 1;

  /// Scroll controllers so zooming can keep the view centered on content.
  final ScrollController _vScroll = ScrollController();
  final ScrollController _hScroll = ScrollController();

  /// Whether Ctrl is currently held (disables page scroll for zooming).
  bool _ctrlHeld = false;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKey);
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

  bool _handleKey(KeyEvent event) {
    if (!mounted) {
      return false;
    }
    final held = HardwareKeyboard.instance.isControlPressed;
    if (held != _ctrlHeld) {
      setState(() => _ctrlHeld = held);
    }
    return false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _vScroll.dispose();
    _hScroll.dispose();
    super.dispose();
  }

  RenderBox? get _canvasBox =>
      _canvasKey.currentContext?.findRenderObject() as RenderBox?;

  /// Changes the zoom level, rescaling scroll offsets so the view stays on
  /// the content instead of stranding the viewport on empty space.
  ///
  /// No-op while [AppSettings.editorZoomEnabled] is off; a zoomed canvas
  /// snaps back to 1x in that case.
  void _applyZoom(double zoom) {
    final zoomAllowed =
        ref.read(settingsProvider).valueOrNull?.editorZoomEnabled ?? true;
    if (!zoomAllowed) {
      if (_zoom != 1 && mounted) {
        setState(() => _zoom = 1);
      }
      return;
    }
    final next = zoom.clamp(0.5, 2.5).toDouble();
    if (next == _zoom) {
      return;
    }
    final factor = next / _zoom;
    setState(() => _zoom = next);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      for (final controller in [_vScroll, _hScroll]) {
        if (!controller.hasClients) {
          continue;
        }
        final position = controller.position;
        if (position.maxScrollExtent <= 0) {
          controller.jumpTo(0);
        } else {
          controller.jumpTo(
            (position.pixels * factor).clamp(0.0, position.maxScrollExtent),
          );
        }
      }
    });
  }

  /// Records the current arrangement for undo; clears the redo stack.
  void _pushHistory() {
    _undoStack.add(List.of(_items));
    if (_undoStack.length > _historyLimit) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  /// Drops the last pushed snapshot when a gesture ended without changes.
  void _dropUnchangedHistory() {
    if (_undoStack.isNotEmpty && _listsEqual(_undoStack.last, _items)) {
      _undoStack.removeLast();
    }
  }

  static bool _listsEqual(List<LayoutItem> a, List<LayoutItem> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  void _undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    setState(() {
      _redoStack.add(List.of(_items));
      _items = _undoStack.removeLast();
      _clearGestureState();
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    setState(() {
      _undoStack.add(List.of(_items));
      _items = _redoStack.removeLast();
      _clearGestureState();
    });
  }

  /// Drops any in-flight drag/resize/pinch state (e.g. after undo mid-gesture
  /// so stale indices cannot apply to the restored arrangement).
  void _clearGestureState() {
    _selectedIndex = null;
    _dragIndex = null;
    _dragDelta = Offset.zero;
    _snap = AlignmentSnap.none;
    _resizePointer = null;
    _resizeIndex = null;
    _resizeBase = null;
    _pinchPointers.clear();
    _pinchIndex = null;
    _pinchBase = null;
    _pinchCanvas = false;
    _sizeSnap = null;
  }

  // ----- selection -----

  void _select(int index) {
    setState(() {
      _selectedIndex = _selectedIndex == index ? null : index;
    });
  }

  // ----- move -----

  void _startDrag(int index, Offset globalPosition, int pointer) {
    if (_dragPointer != null || index >= _items.length) {
      return;
    } // A drag starting on the resize handle belongs to the handle. The badge
    // is a ~25px circle overflowing the tile's bottom-right corner, so the
    // skip zone covers that corner.
    final box = _canvasBox;
    if (box == null) {
      return;
    }
    if (_selectedIndex == index && _showResizeHandle(context)) {
      final local = box.globalToLocal(globalPosition);
      final item = _items[index];
      // Constant on-screen size regardless of zoom.
      final corner = 26 / _zoom;
      if (local.dx >= item.right - corner && local.dy >= item.bottom - corner) {
        return;
      }
    }
    final item = _items[index];
    _pushHistory();
    setState(() {
      _dragPointer = pointer;
      _dragIndex = index;
      _dragStart = Offset(item.x, item.y);
      _dragDelta = Offset.zero;
      _snap = AlignmentSnap.none;
      _selectedIndex = null;
      _scrollLock = true;
    });
  }

  void _updateDragBy(Offset delta) {
    final index = _dragIndex;
    if (index == null || index >= _items.length) {
      return;
    }
    // A simultaneous pinch (tile or canvas) owns the gesture.
    if (_pinchIndex != null || _pinchCanvas) {
      return;
    }
    final item = _items[index];
    setState(() {
      _dragDelta += delta;
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
              includeOrigin: true,
            )
          : AlignmentSnap.none;
      x = (x + _snap.dx).clamp(0, kMaxCanvasExtent).toDouble();
      y = (y + _snap.dy).clamp(0, kMaxCanvasExtent).toDouble();
      // Snap back to the drag start position ("remember previous spot").
      final vLines = [..._snap.verticalLines];
      final hLines = [..._snap.horizontalLines];
      if (_snapEnabled) {
        if ((x - _dragStart.dx).abs() <= kSnapThreshold) {
          x = _dragStart.dx;
          vLines.add(_dragStart.dx);
        }
        if ((y - _dragStart.dy).abs() <= kSnapThreshold) {
          y = _dragStart.dy;
          hLines.add(_dragStart.dy);
        }
      }
      _snap = AlignmentSnap(
        dx: _snap.dx,
        dy: _snap.dy,
        verticalLines: vLines,
        horizontalLines: hLines,
      );
      _items[index] = item.moveTo(x, y);
    });
  }

  void _dragPointerDown(int index, PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons != kPrimaryButton) {
      return;
    }
    _startDrag(index, event.position, event.pointer);
  }

  void _dragPointerUp(int pointer) {
    if (_dragPointer == pointer) {
      _endDrag();
    }
  }

  void _endDrag() {
    if (_dragIndex == null && _dragPointer == null) {
      return;
    }
    _dropUnchangedHistory();
    setState(() {
      _dragIndex = null;
      _dragPointer = null;
      _dragDelta = Offset.zero;
      _snap = AlignmentSnap.none;
      if (_pinchPointers.length < 2 && _resizePointer == null) {
        _scrollLock = false;
      }
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
    _pushHistory();
    setState(() {
      _resizePointer = pointer;
      _resizeIndex = index;
      _resizeStartLocal = box.globalToLocal(globalPosition);
      _resizeBase = (item.width, item.height);
      _scrollLock = true;
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
      width = base.$1 * scale;
      height = base.$2 * scale;
    } else {
      width = base.$1 + dw;
      height = base.$2 + dh;
    }
    _applyResize(index, width, height);
  }

  /// Applies a resize with optional snap-to-neighbours and clamping.
  ///
  /// With the aspect lock on, a snapped axis rescales the other one to keep
  /// the ratio; otherwise both axes snap independently.
  void _applyResize(int index, double width, double height) {
    if (index >= _items.length) {
      return;
    }
    var w = width;
    var h = height;
    SizeSnap? sizeSnap;
    if (_snapEnabled) {
      final item = _items[index];
      final snapped = SizeSnap.compute(
        item: item,
        width: w,
        height: h,
        others: _items,
        ignore: item,
      );
      if (_lockAspect) {
        if (snapped.width != w && w > 0) {
          final scale = snapped.width / w;
          w = snapped.width;
          h = h * scale;
          sizeSnap = snapped;
        } else if (snapped.height != h && h > 0) {
          final scale = snapped.height / h;
          h = snapped.height;
          w = w * scale;
          sizeSnap = snapped;
        }
      } else if (snapped.width != width || snapped.height != height) {
        w = snapped.width;
        h = snapped.height;
        sizeSnap = snapped;
      }
    }
    setState(() {
      _items[index] = _items[index].resizeTo(
        w.clamp(kMinTileExtent, kMaxTileExtent).toDouble(),
        h.clamp(kMinTileExtent, kMaxTileExtent).toDouble(),
      );
      _sizeSnap = sizeSnap;
    });
  }

  void _endResize(int pointer) {
    if (_resizePointer == pointer) {
      _dropUnchangedHistory();
      setState(() {
        _resizePointer = null;
        _resizeIndex = null;
        _resizeBase = null;
        _sizeSnap = null;
        if (_pinchPointers.length < 2 && _dragPointer == null) {
          _scrollLock = false;
        }
      });
    }
  }

  // ----- pinch resize (touch): two pointers scale the selected tile -----

  void _pinchDown(int pointer, Offset globalPosition) {
    _pinchPointers[pointer] = globalPosition;
    if (_pinchPointers.length != 2 || _pinchIndex != null || _pinchCanvas) {
      return;
    }
    // A pinch over a tile resizes that tile; a pinch over empty canvas
    // zooms the canvas instead.
    final positions = _pinchPointers.values.toList();
    var target = _topmostTileAt(positions[0]);
    target ??= _topmostTileAt(positions[1]);
    final startDist = (positions[0] - positions[1]).distance;
    if (target == null) {
      setState(() {
        _pinchCanvas = true;
        _pinchStartDist = startDist;
        _zoomStart = _zoom;
        _scrollLock = true;
      });
      return;
    }
    if (target >= _items.length) {
      _pinchPointers.clear();
      return;
    }
    final item = _items[target];
    _pushHistory();
    setState(() {
      _pinchIndex = target;
      _selectedIndex = target;
      _pinchStartDist = startDist;
      _pinchBase = (item.width, item.height);
      _scrollLock = true;
    });
  }

  void _pinchMove(int pointer, Offset globalPosition) {
    if (!_pinchPointers.containsKey(pointer)) {
      return;
    }
    _pinchPointers[pointer] = globalPosition;
    if (_pinchPointers.length != 2) {
      return;
    }
    final positions = _pinchPointers.values.toList();
    final dist = (positions[0] - positions[1]).distance;
    if (_pinchStartDist <= 0 || dist <= 0) {
      return;
    }
    if (_pinchCanvas) {
      _applyZoom(_zoomStart * dist / _pinchStartDist);
      return;
    }
    final index = _pinchIndex;
    final base = _pinchBase;
    if (index == null || base == null) {
      return;
    }
    if (index >= _items.length) {
      return;
    }
    final factor = dist / _pinchStartDist;
    // Pinch is inherently uniform; snap still applies when enabled.
    _applyResize(index, base.$1 * factor, base.$2 * factor);
  }

  void _pinchUp(int pointer) {
    _pinchPointers.remove(pointer);
    if (_pinchPointers.length < 2) {
      if (_pinchCanvas) {
        setState(() {
          _pinchCanvas = false;
          if (_dragPointer == null && _resizePointer == null) {
            _scrollLock = false;
          }
        });
      } else if (_pinchIndex != null) {
        _dropUnchangedHistory();
        setState(() {
          _pinchIndex = null;
          _pinchBase = null;
          _sizeSnap = null;
          if (_dragPointer == null && _resizePointer == null) {
            _scrollLock = false;
          }
        });
      }
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
    _pushHistory();
    setState(() {
      _items.add(factory(x, y));
    });
  }

  void _remove(int index) {
    _pushHistory();
    setState(() {
      _items.removeAt(index);
      _selectedIndex = null;
    });
  }

  void _resetLayout() {
    _pushHistory();
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
    final zoomEnabled = ref.watch(
      settingsProvider.select((s) => s.valueOrNull?.editorZoomEnabled ?? true),
    );
    if (!zoomEnabled && _zoom != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _zoom = 1);
        }
      });
    }
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                var contentRight = 0.0;
                var contentBottom = 0.0;
                for (final item in _items) {
                  if (item.right > contentRight) {
                    contentRight = item.right;
                  }
                  if (item.bottom > contentBottom) {
                    contentBottom = item.bottom;
                  }
                }
                final viewportWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : 960.0;
                final baseWidth =
                    (viewportWidth - 32 > contentRight + 16
                            ? viewportWidth - 32
                            : contentRight + 16)
                        .toDouble();
                final baseHeight =
                    (contentBottom + 24 < 200 ? 200 : contentBottom + 24)
                        .toDouble();
                return SingleChildScrollView(
                  controller: _vScroll,
                  physics: _ctrlHeld || _scrollLock
                      ? const NeverScrollableScrollPhysics()
                      : const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    controller: _hScroll,
                    physics: _scrollLock
                        ? const NeverScrollableScrollPhysics()
                        : const AlwaysScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: baseWidth * _zoom,
                      height: baseHeight * _zoom,
                      child: Transform.scale(
                        scale: _zoom,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: baseWidth,
                          height: baseHeight,
                          child: Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerDown: (event) =>
                                _pinchDown(event.pointer, event.position),
                            onPointerMove: (event) =>
                                _pinchMove(event.pointer, event.position),
                            onPointerUp: (event) => _pinchUp(event.pointer),
                            onPointerCancel: (event) => _pinchUp(event.pointer),
                            onPointerSignal: (event) {
                              if (event is PointerScrollEvent &&
                                  HardwareKeyboard.instance.isControlPressed) {
                                _applyZoom(
                                  _zoom * math.exp(-event.scrollDelta.dy / 500),
                                );
                              }
                            },
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
                );
              },
            ),
          ),
          _buildToolbar(l10n, zoomEnabled),
        ],
      ),
    );
  }

  /// Bottom toolbar with the editor-wide toggles and the selected tile name.
  /// Identical on touch and desktop.
  Widget _buildToolbar(AppLocalizations l10n, bool zoomEnabled) {
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
          // Horizontally scrollable so narrow screens never overflow.
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: l10n.undoAction,
                  onPressed: _undoStack.isEmpty ? null : _undo,
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  tooltip: l10n.redoAction,
                  onPressed: _redoStack.isEmpty ? null : _redo,
                ),
                if (zoomEnabled && (_zoom - 1).abs() > 0.001)
                  IconButton(
                    icon: const Icon(Icons.zoom_out_map),
                    tooltip: l10n.resetZoom,
                    onPressed: () => _applyZoom(1),
                  ),
                if (label != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                FilterChip(
                  avatar: const Icon(Icons.aspect_ratio, size: 18),
                  label: Text(l10n.aspectLock),
                  tooltip: l10n.aspectLock,
                  selected: _lockAspect,
                  showCheckmark: false,
                  onSelected: (value) => setState(() => _lockAspect = value),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  avatar: const Icon(Icons.align_horizontal_center, size: 18),
                  label: Text(l10n.snapGuides),
                  tooltip: l10n.snapGuides,
                  selected: _snapEnabled,
                  showCheckmark: false,
                  onSelected: (value) => setState(() => _snapEnabled = value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Alignment guide lines for the in-progress drag or resize, plus a
  /// ghost of the drag start position.
  List<Widget> _buildGuides() {
    final sizeSnap = _sizeSnap;
    final resizing =
        (_resizePointer != null || _pinchIndex != null) && sizeSnap != null;
    if (_dragIndex == null && !resizing) {
      return const [];
    }
    final color = Theme.of(context).colorScheme.primary;
    final verticalLines = [
      ..._snap.verticalLines,
      if (resizing) ...sizeSnap.verticalLines,
    ];
    final horizontalLines = [
      ..._snap.horizontalLines,
      if (resizing) ...sizeSnap.horizontalLines,
    ];
    final dragIndex = _dragIndex;
    final ghost = dragIndex != null && dragIndex < _items.length
        ? [
            Positioned(
              left: _dragStart.dx,
              top: _dragStart.dy,
              width: _items[dragIndex].width,
              height: _items[dragIndex].height,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
              ),
            ),
          ]
        : const <Widget>[];
    return [
      ...ghost,
      for (final x in verticalLines)
        Positioned(
          left: x,
          top: 0,
          bottom: 0,
          width: 1,
          child: ColoredBox(color: color),
        ),
      for (final y in horizontalLines)
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
            onPanUpdate: (details) => _updateDragBy(details.delta / _zoom),
            onPanEnd: (_) => _endDrag(),
            onPanCancel: _endDrag,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) => _dragPointerDown(index, event),
              onPointerUp: (event) => _dragPointerUp(event.pointer),
              onPointerCancel: (event) => _dragPointerUp(event.pointer),
              child: content,
            ),
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
          if (selected && !dragging && _showResizeHandle(context))
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

  /// The resize handle badge is desktop-only: on touch devices pinch covers
  /// resizing and the badge would only get in the way of taps.
  bool _showResizeHandle(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform != TargetPlatform.android && platform != TargetPlatform.iOS;
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
            section(l10n.keyGroupAppsInputs, [
              for (final key in _appsInputsKeys) keyChip(key),
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
