import 'dart:convert';

import 'remote_key.dart';

/// Minimum/maximum tile dimensions in logical pixels.
const double kMinTileExtent = 40;
const double kMaxTileExtent = 400;

/// Maximum accepted canvas coordinate; items beyond this are clamped or
/// dropped on load so hostile payloads cannot freeze the UI.
const double kMaxCanvasExtent = 4000;

/// Maximum number of tiles accepted per layout (bounds widget creation and
/// per-frame scans against hostile payloads).
const int kMaxLayoutItems = 500;

/// Default size of a key button tile.
const double kDefaultButtonSize = 64;

/// Snap distance for alignment guides in logical pixels.
const double kSnapThreshold = 6;

/// Special (non-key) building blocks that can be placed on the canvas.
enum LayoutBlock { tvStatus, digitsPad, sleepTimer }

/// Default tile size of each special block.
const Map<LayoutBlock, (double, double)> kLayoutBlockSizes = {
  LayoutBlock.tvStatus: (170, 52),
  LayoutBlock.digitsPad: (320, 176),
  LayoutBlock.sleepTimer: (170, 52),
};

/// Cell size used when migrating version-1 grid layouts to the free canvas.
const double _legacyCellSize = 72;
const double _legacyGap = 8;

/// A single item placed on the free-form layout canvas: either a
/// [RemoteKey] button or a special [LayoutBlock].
///
/// Positions and sizes are absolute logical pixels relative to the canvas
/// origin (top-left). There is no grid; items can be freely arranged.
class LayoutItem {
  const LayoutItem.key({
    required this.remoteKey,
    required this.x,
    required this.y,
    this.width = kDefaultButtonSize,
    this.height = kDefaultButtonSize,
  }) : block = null;

  const LayoutItem.block({
    required this.block,
    required this.x,
    required this.y,
    double? width,
    double? height,
  }) : remoteKey = null,
       width = width ?? kDefaultButtonSize,
       height = height ?? kDefaultButtonSize;

  final RemoteKey? remoteKey;

  final LayoutBlock? block;

  /// Left edge in logical pixels.
  final double x;

  /// Top edge in logical pixels.
  final double y;

  /// Tile width in logical pixels.
  final double width;

  /// Tile height in logical pixels.
  final double height;

  bool get isKey => remoteKey != null;

  LayoutItem moveTo(double x, double y) => isKey
      ? LayoutItem.key(
          remoteKey: remoteKey!,
          x: x,
          y: y,
          width: width,
          height: height,
        )
      : LayoutItem.block(
          block: block!,
          x: x,
          y: y,
          width: width,
          height: height,
        );

  LayoutItem resizeTo(double width, double height) => isKey
      ? LayoutItem.key(
          remoteKey: remoteKey!,
          x: x,
          y: y,
          width: width,
          height: height,
        )
      : LayoutItem.block(
          block: block!,
          x: x,
          y: y,
          width: width,
          height: height,
        );

  double get left => x;
  double get top => y;
  double get right => x + width;
  double get bottom => y + height;
  double get centerX => x + width / 2;
  double get centerY => y + height / 2;

  Map<String, Object?> toJson() => {
    'type': isKey ? 'key' : 'block',
    if (isKey) 'key': remoteKey!.name,
    if (!isKey) 'block': block!.name,
    'x': x,
    'y': y,
    'w': width,
    'h': height,
  };

  /// Parses a single item; returns `null` when [json] is not a valid item.
  ///
  /// Coordinates are clamped to the canvas bounds and sizes to the tile
  /// limits; items that would render nothing (zero-area after clamping) are
  /// dropped.
  static LayoutItem? tryFromJson(Object? json) {
    if (json is! Map<Object?, Object?>) {
      return null;
    }
    final x = _finiteDouble(json['x']);
    final y = _finiteDouble(json['y']);
    if (x == null || y == null) {
      return null;
    }
    final width = (_finiteDouble(json['w']) ?? kDefaultButtonSize).clamp(
      kMinTileExtent,
      kMaxTileExtent,
    );
    final height = (_finiteDouble(json['h']) ?? kDefaultButtonSize).clamp(
      kMinTileExtent,
      kMaxTileExtent,
    );
    switch (json['type']) {
      case 'key':
        final key = _tryParseKey(json['key']);
        if (key == null) {
          return null;
        }
        return LayoutItem.key(
          remoteKey: key,
          x: x.clamp(0, kMaxCanvasExtent),
          y: y.clamp(0, kMaxCanvasExtent),
          width: width,
          height: height,
        );
      case 'block':
        final block = _tryParseBlock(json['block']);
        if (block == null) {
          return null;
        }
        final (defaultW, defaultH) = kLayoutBlockSizes[block]!;
        return LayoutItem.block(
          block: block,
          x: x.clamp(0, kMaxCanvasExtent),
          y: y.clamp(0, kMaxCanvasExtent),
          width: (_finiteDouble(json['w']) ?? defaultW).clamp(
            kMinTileExtent,
            kMaxTileExtent,
          ),
          height: (_finiteDouble(json['h']) ?? defaultH).clamp(
            kMinTileExtent,
            kMaxTileExtent,
          ),
        );
      default:
        return null;
    }
  }

  static RemoteKey? _tryParseKey(Object? value) {
    if (value is! String) {
      return null;
    }
    for (final key in RemoteKey.values) {
      if (key.name == value) {
        return key;
      }
    }
    return null;
  }

  static LayoutBlock? _tryParseBlock(Object? value) {
    if (value is! String) {
      return null;
    }
    for (final block in LayoutBlock.values) {
      if (block.name == value) {
        return block;
      }
    }
    return null;
  }

  static double? _finiteDouble(Object? value) =>
      value is num && value.isFinite ? value.toDouble() : null;

  @override
  bool operator ==(Object other) =>
      other is LayoutItem &&
      other.remoteKey == remoteKey &&
      other.block == block &&
      other.x == x &&
      other.y == y &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(remoteKey, block, x, y, width, height);
}

/// An arrangement of [LayoutItem]s on the free-form canvas.
class FreeRemoteLayout {
  FreeRemoteLayout(Iterable<LayoutItem> items)
    : items = List.unmodifiable(items);

  final List<LayoutItem> items;

  /// Lowest content edge, used to size the canvas and to append new items.
  double get contentBottom {
    var bottom = 0.0;
    for (final item in items) {
      if (item.bottom > bottom) {
        bottom = item.bottom;
      }
    }
    return bottom;
  }

  /// First free anchor below the existing content for a tile of [size];
  /// free-form canvases always have room, so this never returns null.
  (double, double) appendSpot() => (8, contentBottom + 16);

  /// A sensible starting point mirroring the classic preset.
  static FreeRemoteLayout defaultTemplate() {
    const step = _legacyCellSize + _legacyGap;
    double col(int c) => 8 + c * step;
    double row(int r) => 8 + r * step;
    const button = 64.0;
    return FreeRemoteLayout([
      LayoutItem.block(
        block: LayoutBlock.tvStatus,
        x: col(1),
        y: row(0),
        width: 200,
        height: 48,
      ),
      for (final (key, r, c) in [
        (RemoteKey.power, 1, 0),
        (RemoteKey.mute, 1, 1),
        (RemoteKey.info, 1, 2),
        (RemoteKey.volumeDown, 2, 0),
        (RemoteKey.volumeUp, 2, 1),
        (RemoteKey.channelDown, 2, 2),
        (RemoteKey.channelUp, 2, 3),
        (RemoteKey.up, 3, 1),
        (RemoteKey.left, 4, 0),
        (RemoteKey.select, 4, 1),
        (RemoteKey.right, 4, 2),
        (RemoteKey.down, 5, 1),
        (RemoteKey.back, 6, 0),
        (RemoteKey.exit, 6, 1),
        (RemoteKey.settings, 7, 0),
        (RemoteKey.favorites, 7, 1),
        (RemoteKey.pictureFormat, 7, 2),
        (RemoteKey.pictureMode, 7, 3),
        (RemoteKey.audioTrack, 8, 0),
        (RemoteKey.subtitleAudio, 8, 1),
        (RemoteKey.subtitles, 8, 2),
        (RemoteKey.teletext, 8, 3),
      ])
        LayoutItem.key(
          remoteKey: key,
          x: col(c),
          y: row(r),
          width: button,
          height: button,
        ),
      LayoutItem.block(
        block: LayoutBlock.digitsPad,
        x: col(0),
        y: row(9),
        width: 4 * _legacyCellSize + 3 * _legacyGap,
        height: 176,
      ),
      LayoutItem.block(
        block: LayoutBlock.sleepTimer,
        x: col(1),
        y: row(11) + 8,
        width: 200,
        height: 48,
      ),
    ]);
  }

  Map<String, Object?> toJson() => {
    'version': 2,
    'items': [for (final item in items) item.toJson()],
  };

  /// Parses a free-form layout. Version-1 grid payloads are migrated to
  /// canvas coordinates on the fly. Returns `null` when [json] is not a
  /// valid layout payload. At most [kMaxLayoutItems] tiles are kept.
  static FreeRemoteLayout? tryFromJson(Object? json) {
    if (json is! Map<Object?, Object?>) {
      return null;
    }
    final rawItems = json['items'];
    if (rawItems is! List<Object?>) {
      return null;
    }
    final version = _safeInt(json['version']) ?? 1;
    final parsed = <LayoutItem>[];
    for (final raw in rawItems) {
      if (parsed.length >= kMaxLayoutItems) {
        break;
      }
      final item = version >= 2
          ? LayoutItem.tryFromJson(raw)
          : _migrateGridItem(raw);
      if (item != null) {
        // Defensive cap: ignore items placed absurdly far away.
        if (item.x > kMaxCanvasExtent || item.y > kMaxCanvasExtent) {
          continue;
        }
        parsed.add(item);
      }
    }
    return FreeRemoteLayout(parsed);
  }

  /// Converts a version-1 grid item (`row`/`column`/`rowSpan`/`columnSpan`)
  /// into canvas coordinates.
  static LayoutItem? _migrateGridItem(Object? json) {
    if (json is! Map<Object?, Object?>) {
      return null;
    }
    final row = _nonNegativeInt(json['row']);
    final column = _nonNegativeInt(json['column']);
    if (row == null || column == null || column > 11) {
      return null;
    }
    // Matches defaultTemplate()'s 8px canvas margin.
    final x = 8 + column * (_legacyCellSize + _legacyGap);
    final y = 8 + row * (_legacyCellSize + _legacyGap);
    switch (json['type']) {
      case 'key':
        final key = LayoutItem._tryParseKey(json['key']);
        if (key == null) {
          return null;
        }
        final rowSpan = _safeInt(json['rowSpan'], min: 1, max: 2) ?? 1;
        final columnSpan = _safeInt(json['columnSpan'], min: 1, max: 2) ?? 1;
        return LayoutItem.key(
          remoteKey: key,
          x: x,
          y: y,
          width: (columnSpan * _legacyCellSize + (columnSpan - 1) * _legacyGap)
              .clamp(kMinTileExtent, kMaxTileExtent),
          height: (rowSpan * _legacyCellSize + (rowSpan - 1) * _legacyGap)
              .clamp(kMinTileExtent, kMaxTileExtent),
        );
      case 'block':
        final block = LayoutItem._tryParseBlock(json['block']);
        if (block == null) {
          return null;
        }
        final (defaultW, defaultH) = kLayoutBlockSizes[block]!;
        return LayoutItem.block(
          block: block,
          x: x,
          y: y,
          width: defaultW,
          height: defaultH,
        );
      default:
        return null;
    }
  }

  static int? _nonNegativeInt(Object? value) =>
      value is num && value.isFinite && value >= 0 && value == value.round()
      ? value.round()
      : null;

  /// Reads an integer with optional bounds; returns null for anything else
  /// (including numeric strings), never throwing.
  static int? _safeInt(Object? value, {int? min, int? max}) {
    if (value is! num || !value.isFinite) {
      return null;
    }
    var result = value.round();
    if (min != null && result < min) {
      result = min;
    }
    if (max != null && result > max) {
      result = max;
    }
    return result;
  }

  static FreeRemoteLayout? tryFromJsonString(String? source) {
    if (source == null) {
      return null;
    }
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return null;
    }
    return tryFromJson(decoded);
  }

  @override
  bool operator ==(Object other) {
    if (other is! FreeRemoteLayout || other.items.length != items.length) {
      return false;
    }
    for (var i = 0; i < items.length; i++) {
      if (other.items[i] != items[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(items);
}

/// Result of snapping a dragged tile against its neighbours.
class AlignmentSnap {
  const AlignmentSnap({
    required this.dx,
    required this.dy,
    required this.verticalLines,
    required this.horizontalLines,
  });

  /// Horizontal correction to apply.
  final double dx;

  /// Vertical correction to apply.
  final double dy;

  /// X positions of the vertical guide lines to draw.
  final List<double> verticalLines;

  /// Y positions of the horizontal guide lines to draw.
  final List<double> horizontalLines;

  static const AlignmentSnap none = AlignmentSnap(
    dx: 0,
    dy: 0,
    verticalLines: [],
    horizontalLines: [],
  );

  @override
  bool operator ==(Object other) =>
      other is AlignmentSnap &&
      other.dx == dx &&
      other.dy == dy &&
      _doublesEqual(other.verticalLines, verticalLines) &&
      _doublesEqual(other.horizontalLines, horizontalLines);

  @override
  int get hashCode => Object.hash(
    dx,
    dy,
    Object.hashAll(verticalLines),
    Object.hashAll(horizontalLines),
  );

  static bool _doublesEqual(List<double> a, List<double> b) {
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

  /// Snaps [moving]'s edges/center against [others] within [threshold].
  ///
  /// Each axis snaps independently to the nearest candidate (left, center,
  /// right / top, center, bottom). With [includeOrigin], the moving tile's
  /// left/top edges also snap to the canvas origin (0, 0). When no edge
  /// snaps on an axis, gaps are equalized instead: a tile dragged between
  /// two neighbours snaps so both gaps match.
  static AlignmentSnap compute({
    required LayoutItem moving,
    required Iterable<LayoutItem> others,
    double threshold = kSnapThreshold,
    LayoutItem? ignore,
    bool includeOrigin = false,
  }) {
    double? bestDx;
    var bestDxDist = threshold + 1;
    final vLines = <double>[];
    double? bestDy;
    var bestDyDist = threshold + 1;
    final hLines = <double>[];
    void considerX(double from, double to) {
      final distance = (to - from).abs();
      if (distance <= threshold && distance < bestDxDist) {
        bestDxDist = distance;
        bestDx = to - from;
        vLines
          ..clear()
          ..add(to);
      }
    }

    void considerY(double from, double to) {
      final distance = (to - from).abs();
      if (distance <= threshold && distance < bestDyDist) {
        bestDyDist = distance;
        bestDy = to - from;
        hLines
          ..clear()
          ..add(to);
      }
    }

    if (includeOrigin) {
      considerX(moving.left, 0);
      considerY(moving.top, 0);
    }
    final rest = others.where((other) => !identical(other, ignore)).toList();
    for (final other in rest) {
      for (final from in [moving.left, moving.centerX, moving.right]) {
        for (final to in [other.left, other.centerX, other.right]) {
          considerX(from, to);
        }
      }
      for (final from in [moving.top, moving.centerY, moving.bottom]) {
        for (final to in [other.top, other.centerY, other.bottom]) {
          considerY(from, to);
        }
      }
    }
    if (bestDx == null) {
      final gap = _equalizeGap(
        movingLeft: moving.left,
        movingSize: moving.width,
        neighbours: [
          for (final other in rest)
            if (_overlaps(
              moving.top,
              moving.bottom,
              other.top,
              other.bottom,
            ))
              (other.left, other.right),
        ],
        threshold: threshold,
      );
      if (gap != null) {
        bestDx = gap.$1;
        vLines
          ..clear()
          ..addAll(gap.$2);
      }
    }
    if (bestDy == null) {
      final gap = _equalizeGap(
        movingLeft: moving.top,
        movingSize: moving.height,
        neighbours: [
          for (final other in rest)
            if (_overlaps(
              moving.left,
              moving.right,
              other.left,
              other.right,
            ))
              (other.top, other.bottom),
        ],
        threshold: threshold,
      );
      if (gap != null) {
        bestDy = gap.$1;
        hLines
          ..clear()
          ..addAll(gap.$2);
      }
    }
    return AlignmentSnap(
      dx: bestDx ?? 0,
      dy: bestDy ?? 0,
      verticalLines: vLines,
      horizontalLines: hLines,
    );
  }

  static bool _overlaps(double a1, double a2, double b1, double b2) =>
      a1 < b2 && a2 > b1;

  /// Equalizes the gaps around a tile dragged between two neighbours.
  ///
  /// Returns the shift plus the gap-boundary lines, or null when no
  /// bracketing pair has near-equal gaps.
  static (double, List<double>)? _equalizeGap({
    required double movingLeft,
    required double movingSize,
    required List<(double, double)> neighbours,
    required double threshold,
  }) {
    double? bestShift;
    var bestDiff = threshold + 1;
    List<double> bestLines = const [];
    for (final (_, a2) in neighbours) {
      for (final (b1, _) in neighbours) {
        if (a2 > movingLeft || b1 < movingLeft + movingSize) {
          continue;
        }
        final gapL = movingLeft - a2;
        final gapR = b1 - (movingLeft + movingSize);
        if (gapL < 0 || gapR < 0) {
          continue;
        }
        final diff = (gapL - gapR).abs();
        if (diff <= threshold && diff < bestDiff) {
          bestDiff = diff;
          bestShift = (gapR - gapL) / 2;
          bestLines = [a2, b1];
        }
      }
    }
    return bestShift == null ? null : (bestShift, bestLines);
  }
}

/// Result of snapping a resized tile's dimensions against its neighbours.
///
/// Width snaps to nearby tile widths and to values aligning the right edge
/// with neighbours' edges/centers; height behaves symmetrically.
class SizeSnap {
  const SizeSnap({
    required this.width,
    required this.height,
    this.verticalLines = const [],
    this.horizontalLines = const [],
  });

  final double width;
  final double height;

  /// X positions of the vertical guide lines to draw.
  final List<double> verticalLines;

  /// Y positions of the horizontal guide lines to draw.
  final List<double> horizontalLines;

  static SizeSnap compute({
    required LayoutItem item,
    required double width,
    required double height,
    required Iterable<LayoutItem> others,
    double threshold = kSnapThreshold,
    LayoutItem? ignore,
  }) {
    double snappedW = width;
    var bestWDist = threshold + 1;
    double? snapX;
    for (final candidate in _widthCandidates(item, others, ignore)) {
      if (candidate < kMinTileExtent) {
        continue;
      }
      final distance = (candidate - width).abs();
      if (distance <= threshold && distance < bestWDist) {
        bestWDist = distance;
        snappedW = candidate;
        snapX = item.x + candidate;
      }
    }
    double snappedH = height;
    var bestHDist = threshold + 1;
    double? snapY;
    for (final candidate in _heightCandidates(item, others, ignore)) {
      if (candidate < kMinTileExtent) {
        continue;
      }
      final distance = (candidate - height).abs();
      if (distance <= threshold && distance < bestHDist) {
        bestHDist = distance;
        snappedH = candidate;
        snapY = item.y + candidate;
      }
    }
    return SizeSnap(
      width: snappedW,
      height: snappedH,
      verticalLines: snapX == null ? const [] : [snapX],
      horizontalLines: snapY == null ? const [] : [snapY],
    );
  }

  static Iterable<double> _widthCandidates(
    LayoutItem item,
    Iterable<LayoutItem> others,
    LayoutItem? ignore,
  ) sync* {
    for (final other in others) {
      if (identical(other, ignore)) {
        continue;
      }
      yield other.width;
      yield other.right - item.x;
      yield other.left - item.x;
      yield other.centerX - item.x;
    }
  }

  static Iterable<double> _heightCandidates(
    LayoutItem item,
    Iterable<LayoutItem> others,
    LayoutItem? ignore,
  ) sync* {
    for (final other in others) {
      if (identical(other, ignore)) {
        continue;
      }
      yield other.height;
      yield other.bottom - item.y;
      yield other.top - item.y;
      yield other.centerY - item.y;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SizeSnap &&
      other.width == width &&
      other.height == height &&
      AlignmentSnap._doublesEqual(other.verticalLines, verticalLines) &&
      AlignmentSnap._doublesEqual(other.horizontalLines, horizontalLines);

  @override
  int get hashCode => Object.hash(
    width,
    height,
    Object.hashAll(verticalLines),
    Object.hashAll(horizontalLines),
  );
}

/// A named, persisted custom layout.
class SavedRemoteLayout {
  const SavedRemoteLayout({
    required this.id,
    required this.name,
    required this.gridJson,
  });

  /// Stable identifier (also used as the active-layout reference).
  final String id;

  /// User-visible name.
  final String name;

  /// Serialized [FreeRemoteLayout] JSON.
  final String gridJson;

  SavedRemoteLayout copyWith({String? name, String? gridJson}) =>
      SavedRemoteLayout(
        id: id,
        name: name ?? this.name,
        gridJson: gridJson ?? this.gridJson,
      );

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'grid': gridJson};

  static SavedRemoteLayout? tryFromJson(Object? json) {
    if (json is! Map<Object?, Object?>) {
      return null;
    }
    final id = json['id'];
    final grid = json['grid'];
    if (id is! String || id.isEmpty || grid is! String || grid.isEmpty) {
      return null;
    }
    final rawName = json['name'];
    return SavedRemoteLayout(
      id: id,
      name: rawName is String && rawName.isNotEmpty ? rawName : id,
      gridJson: grid,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SavedRemoteLayout &&
      other.id == id &&
      other.name == name &&
      other.gridJson == gridJson;

  @override
  int get hashCode => Object.hash(id, name, gridJson);
}

/// Serializes/deserializes the saved-layout list for the settings store.
List<SavedRemoteLayout> parseSavedLayouts(String source) {
  Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    return const [];
  }
  if (decoded is! List<Object?>) {
    return const [];
  }
  final parsed = <SavedRemoteLayout>[];
  final seenIds = <String>{};
  for (final entry in decoded) {
    final layout = SavedRemoteLayout.tryFromJson(entry);
    if (layout != null && seenIds.add(layout.id)) {
      parsed.add(layout);
    }
  }
  return parsed;
}

String serializeSavedLayouts(List<SavedRemoteLayout> layouts) =>
    jsonEncode([for (final layout in layouts) layout.toJson()]);
