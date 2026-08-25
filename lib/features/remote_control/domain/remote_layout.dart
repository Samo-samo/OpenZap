import 'dart:convert';

import 'remote_key.dart';

/// Default number of columns in the custom remote layout grid.
const int kLayoutGridColumns = 4;

/// Minimum/maximum supported column counts.
const int kLayoutGridMinColumns = 2;
const int kLayoutGridMaxColumns = 12;

/// Special (non-key) building blocks that can be placed on the grid.
enum LayoutBlock { tvStatus, digitsPad, sleepTimer }

/// Default column/row span of each special block.
const Map<LayoutBlock, (int, int)> kLayoutBlockSpans = {
  LayoutBlock.tvStatus: (1, 2),
  LayoutBlock.digitsPad: (2, 4),
  LayoutBlock.sleepTimer: (1, 2),
};

/// A single item placed on the custom remote layout grid: either a
/// [RemoteKey] button or a special [LayoutBlock].
///
/// Buttons may span 1x1 up to 2x2 cells; special blocks have a fixed span
/// ([kLayoutBlockSpans]).
class LayoutItem {
  const LayoutItem.key({
    required this.remoteKey,
    required this.row,
    required this.column,
    this.rowSpan = 1,
    this.columnSpan = 1,
  }) : block = null;

  const LayoutItem.block({
    required this.block,
    required this.row,
    required this.column,
  }) : remoteKey = null,
       rowSpan = 1,
       columnSpan = 1;

  final RemoteKey? remoteKey;

  final LayoutBlock? block;

  /// Zero-based top row of the item on the grid.
  final int row;

  /// Zero-based leftmost column of the item on the grid.
  final int column;

  /// Height of the item in grid rows (buttons only).
  final int rowSpan;

  /// Width of the item in grid columns (buttons only).
  final int columnSpan;

  bool get isKey => remoteKey != null;

  /// Effective vertical span, taking the fixed block sizes into account.
  int get effectiveRowSpan => isKey ? rowSpan : kLayoutBlockSpans[block!]!.$1;

  /// Effective horizontal span, taking the fixed block sizes into account.
  int get effectiveColumnSpan =>
      isKey ? columnSpan : kLayoutBlockSpans[block!]!.$2;

  LayoutItem moveTo(int row, int column) => isKey
      ? LayoutItem.key(
          remoteKey: remoteKey!,
          row: row,
          column: column,
          rowSpan: rowSpan,
          columnSpan: columnSpan,
        )
      : LayoutItem.block(block: block!, row: row, column: column);

  LayoutItem resizeTo(int rowSpan, int columnSpan) => isKey
      ? LayoutItem.key(
          remoteKey: remoteKey!,
          row: row,
          column: column,
          rowSpan: rowSpan,
          columnSpan: columnSpan,
        )
      : this;

  Map<String, Object?> toJson() => {
    'type': isKey ? 'key' : 'block',
    if (isKey) 'key': remoteKey!.name,
    if (!isKey) 'block': block!.name,
    'row': row,
    'column': column,
    if (isKey) 'rowSpan': rowSpan,
    if (isKey) 'columnSpan': columnSpan,
  };

  /// Parses a single item; returns `null` when [json] is not a valid item.
  static LayoutItem? tryFromJson(Object? json) {
    if (json is! Map<Object?, Object?>) {
      return null;
    }
    final row = _nonNegativeInt(json['row']);
    final column = _nonNegativeInt(json['column']);
    if (row == null || column == null) {
      return null;
    }
    switch (json['type']) {
      case 'key':
        final key = _tryParseKey(json['key']);
        if (key == null) {
          return null;
        }
        return LayoutItem.key(
          remoteKey: key,
          row: row,
          column: column,
          rowSpan: (json['rowSpan'] as num?)?.clamp(1, 2).toInt() ?? 1,
          columnSpan: (json['columnSpan'] as num?)?.clamp(1, 2).toInt() ?? 1,
        );
      case 'block':
        final block = _tryParseBlock(json['block']);
        if (block == null) {
          return null;
        }
        return LayoutItem.block(block: block, row: row, column: column);
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

  static int? _nonNegativeInt(Object? value) =>
      value is num && value >= 0 && value == value.round()
      ? value.round()
      : null;

  @override
  bool operator ==(Object other) =>
      other is LayoutItem &&
      other.remoteKey == remoteKey &&
      other.block == block &&
      other.row == row &&
      other.column == column &&
      other.rowSpan == rowSpan &&
      other.columnSpan == columnSpan;

  @override
  int get hashCode =>
      Object.hash(remoteKey, block, row, column, rowSpan, columnSpan);
}

/// An arrangement of [LayoutItem]s on a custom remote layout grid.
class RemoteGridLayout {
  RemoteGridLayout(
    Iterable<LayoutItem> items, {
    this.columns = kLayoutGridColumns,
  }) : assert(
         columns >= kLayoutGridMinColumns && columns <= kLayoutGridMaxColumns,
       ),
       items = List.unmodifiable(items);

  final List<LayoutItem> items;

  /// Number of columns this arrangement was designed for. Renderers may use
  /// fewer/more columns per screen width; items beyond the visible columns
  /// are simply not shown there.
  final int columns;

  /// Suggested column count for [maxWidth], aiming at roughly 60 px cells.
  static int suggestedColumnCount(
    double maxWidth,
    double gap, {
    double cellTarget = 60,
  }) {
    final count = ((maxWidth + gap) / (cellTarget + gap)).floor();
    return count.clamp(kLayoutGridMinColumns, kLayoutGridMaxColumns).toInt();
  }

  /// The cells (as `row:column` strings) occupied by [item].
  static Set<String> cellsOf(LayoutItem item) => {
    for (var r = item.row; r < item.row + item.effectiveRowSpan; r++)
      for (var c = item.column; c < item.column + item.effectiveColumnSpan; c++)
        '$r:$c',
  };

  /// Whether an item with the given geometry would stay inside the grid and
  /// not overlap any other item (excluding [ignore]).
  bool canPlace({
    required int row,
    required int column,
    required int rowSpan,
    required int columnSpan,
    Object? ignore,
  }) {
    if (column < 0 || column + columnSpan > columns || row < 0) {
      return false;
    }
    final candidate = <String>{
      for (var r = row; r < row + rowSpan; r++)
        for (var c = column; c < column + columnSpan; c++) '$r:$c',
    };
    for (final item in items) {
      if (identical(item, ignore)) {
        continue;
      }
      if (cellsOf(item).any(candidate.contains)) {
        return false;
      }
    }
    return true;
  }

  /// First position (reading order) where an item with the given spans fits,
  /// or `null` when the grid has no room left for it.
  (int, int)? firstFreeSpot(int rowSpan, int columnSpan) {
    var maxRow = 0;
    for (final item in items) {
      maxRow = maxRow > item.row ? maxRow : item.row;
    }
    for (var row = 0; row <= maxRow + 8; row++) {
      for (var column = 0; column < columns; column++) {
        if (canPlace(
          row: row,
          column: column,
          rowSpan: rowSpan,
          columnSpan: columnSpan,
        )) {
          return (row, column);
        }
      }
    }
    return null;
  }

  /// Nearest valid position for the given geometry, scanning outwards from
  /// the requested spot; returns `null` when nothing fits anywhere nearby.
  (int, int)? nearestFreeSpot({
    required int row,
    required int column,
    required int rowSpan,
    required int columnSpan,
    Object? ignore,
  }) {
    if (canPlace(
      row: row,
      column: column,
      rowSpan: rowSpan,
      columnSpan: columnSpan,
      ignore: ignore,
    )) {
      return (row, column);
    }
    for (var radius = 1; radius <= 24; radius++) {
      for (var dr = -radius; dr <= radius; dr++) {
        for (final dc in [-radius, radius]) {
          final candidate = _validSpot(
            row: row + dr,
            column: column + dc,
            rowSpan: rowSpan,
            columnSpan: columnSpan,
            ignore: ignore,
          );
          if (candidate != null) {
            return candidate;
          }
        }
      }
      for (var dc = -radius + 1; dc <= radius - 1; dc++) {
        for (final dr in [-radius, radius]) {
          final candidate = _validSpot(
            row: row + dr,
            column: column + dc,
            rowSpan: rowSpan,
            columnSpan: columnSpan,
            ignore: ignore,
          );
          if (candidate != null) {
            return candidate;
          }
        }
      }
    }
    return null;
  }

  (int, int)? _validSpot({
    required int row,
    required int column,
    required int rowSpan,
    required int columnSpan,
    Object? ignore,
  }) {
    if (row < 0 ||
        column < 0 ||
        column + columnSpan > columns ||
        !canPlace(
          row: row,
          column: column,
          rowSpan: rowSpan,
          columnSpan: columnSpan,
          ignore: ignore,
        )) {
      return null;
    }
    return (row, column);
  }

  /// A sensible starting point mirroring the classic preset.
  static RemoteGridLayout defaultTemplate() => RemoteGridLayout([
    LayoutItem.block(block: LayoutBlock.tvStatus, row: 0, column: 1),
    LayoutItem.key(remoteKey: RemoteKey.power, row: 1, column: 0),
    LayoutItem.key(remoteKey: RemoteKey.mute, row: 1, column: 1),
    LayoutItem.key(remoteKey: RemoteKey.info, row: 1, column: 2),
    LayoutItem.key(remoteKey: RemoteKey.volumeDown, row: 2, column: 0),
    LayoutItem.key(remoteKey: RemoteKey.volumeUp, row: 2, column: 1),
    LayoutItem.key(remoteKey: RemoteKey.channelDown, row: 2, column: 2),
    LayoutItem.key(remoteKey: RemoteKey.channelUp, row: 2, column: 3),
    LayoutItem.key(remoteKey: RemoteKey.up, row: 3, column: 1),
    LayoutItem.key(remoteKey: RemoteKey.left, row: 4, column: 0),
    LayoutItem.key(remoteKey: RemoteKey.select, row: 4, column: 1),
    LayoutItem.key(remoteKey: RemoteKey.right, row: 4, column: 2),
    LayoutItem.key(remoteKey: RemoteKey.down, row: 5, column: 1),
    LayoutItem.key(remoteKey: RemoteKey.back, row: 6, column: 0),
    LayoutItem.key(remoteKey: RemoteKey.exit, row: 6, column: 1),
    LayoutItem.key(remoteKey: RemoteKey.settings, row: 7, column: 0),
    LayoutItem.key(remoteKey: RemoteKey.favorites, row: 7, column: 1),
    LayoutItem.key(remoteKey: RemoteKey.pictureFormat, row: 7, column: 2),
    LayoutItem.key(remoteKey: RemoteKey.pictureMode, row: 7, column: 3),
    LayoutItem.key(remoteKey: RemoteKey.audioTrack, row: 8, column: 0),
    LayoutItem.key(remoteKey: RemoteKey.subtitleAudio, row: 8, column: 1),
    LayoutItem.key(remoteKey: RemoteKey.subtitles, row: 8, column: 2),
    LayoutItem.key(remoteKey: RemoteKey.teletext, row: 8, column: 3),
    LayoutItem.block(block: LayoutBlock.digitsPad, row: 9, column: 0),
    LayoutItem.block(block: LayoutBlock.sleepTimer, row: 11, column: 1),
  ]);

  Map<String, Object?> toJson() => {
    'version': 1,
    'columns': columns,
    'items': [for (final item in items) item.toJson()],
  };

  /// Parses a grid; invalid items are skipped. Returns `null` when [json] is
  /// not a valid grid payload.
  static RemoteGridLayout? tryFromJson(Object? json) {
    if (json is! Map<Object?, Object?>) {
      return null;
    }
    final rawItems = json['items'];
    if (rawItems is! List<Object?>) {
      return null;
    }
    final columns = (json['columns'] as num?)?.round() ?? kLayoutGridColumns;
    final parsed = <LayoutItem>[];
    for (final raw in rawItems) {
      final item = LayoutItem.tryFromJson(raw);
      if (item != null) {
        parsed.add(item);
      }
    }
    // Drop items that overlap survivors so the result stays renderable.
    final kept = <LayoutItem>[];
    final occupiedCells = <String>{};
    for (final item in parsed) {
      final cells = cellsOf(item);
      if (item.column + item.effectiveColumnSpan > columns ||
          cells.any(occupiedCells.contains)) {
        continue;
      }
      occupiedCells.addAll(cells);
      kept.add(item);
    }
    return RemoteGridLayout(
      kept,
      columns: columns
          .clamp(kLayoutGridMinColumns, kLayoutGridMaxColumns)
          .toInt(),
    );
  }

  static RemoteGridLayout? tryFromJsonString(String? source) {
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
    if (other is! RemoteGridLayout ||
        other.items.length != items.length ||
        other.columns != columns) {
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
  int get hashCode => Object.hash(columns, Object.hashAll(items));
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

  /// Serialized [RemoteGridLayout] JSON.
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
