import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openzap/features/remote_control/domain/remote_key.dart';
import 'package:openzap/features/remote_control/domain/remote_layout.dart';

void main() {
  group('LayoutItem', () {
    test('key items report their key and spans', () {
      final item = LayoutItem.key(
        remoteKey: RemoteKey.power,
        row: 2,
        column: 3,
        rowSpan: 2,
        columnSpan: 1,
      );
      expect(item.isKey, isTrue);
      expect(item.effectiveRowSpan, 2);
      expect(item.effectiveColumnSpan, 1);
    });

    test('block items use the fixed block spans', () {
      final item = LayoutItem.block(
        block: LayoutBlock.digitsPad,
        row: 0,
        column: 0,
      );
      expect(item.isKey, isFalse);
      expect(
        item.effectiveRowSpan,
        kLayoutBlockSpans[LayoutBlock.digitsPad]!.$1,
      );
      expect(
        item.effectiveColumnSpan,
        kLayoutBlockSpans[LayoutBlock.digitsPad]!.$2,
      );
    });
  });

  group('RemoteGridLayout serialization', () {
    test('round-trips through JSON', () {
      final grid = RemoteGridLayout([
        LayoutItem.block(block: LayoutBlock.tvStatus, row: 0, column: 1),
        LayoutItem.key(remoteKey: RemoteKey.power, row: 1, column: 0),
        LayoutItem.key(
          remoteKey: RemoteKey.volumeUp,
          row: 2,
          column: 0,
          rowSpan: 2,
          columnSpan: 2,
        ),
      ]);
      final encoded = grid.toJsonString();
      final decoded = RemoteGridLayout.tryFromJsonString(encoded);
      expect(decoded, grid);
    });

    test('returns null on malformed input', () {
      expect(RemoteGridLayout.tryFromJsonString('not json'), isNull);
      expect(RemoteGridLayout.tryFromJsonString('[1,2,3]'), isNull);
    });

    test('skips unknown keys and out-of-bounds items', () {
      final grid = RemoteGridLayout.tryFromJsonString(
        '{"items":['
        '{"type":"key","key":"nonexistent","row":0,"column":0},'
        '{"type":"key","key":"power","row":0,"column":9},'
        '{"type":"block","block":"sleepTimer","row":1,"column":0}'
        ']}',
      );
      expect(grid!.items, hasLength(1));
      expect(grid.items.single.block, LayoutBlock.sleepTimer);
    });

    test('drops overlapping survivors on load', () {
      final grid = RemoteGridLayout.tryFromJsonString(
        '{"items":['
        '{"type":"key","key":"power","row":0,"column":0},'
        '{"type":"key","key":"mute","row":0,"column":0},'
        '{"type":"key","key":"info","row":0,"column":1}'
        ']}',
      );
      expect(grid!.items, hasLength(2));
      expect(
        grid.items.map((i) => i.remoteKey),
        containsAll([RemoteKey.power, RemoteKey.info]),
      );
    });
  });

  group('RemoteGridLayout placement', () {
    late RemoteGridLayout grid;

    setUp(() {
      grid = RemoteGridLayout([
        LayoutItem.key(remoteKey: RemoteKey.power, row: 0, column: 0),
      ]);
    });

    test('canPlace rejects overlaps', () {
      expect(
        grid.canPlace(row: 0, column: 0, rowSpan: 1, columnSpan: 1),
        isFalse,
      );
      expect(
        grid.canPlace(row: 0, column: 1, rowSpan: 1, columnSpan: 1),
        isTrue,
      );
    });

    test('canPlace rejects out-of-grid columns', () {
      expect(
        grid.canPlace(row: 0, column: 3, rowSpan: 1, columnSpan: 2),
        isFalse,
      );
      expect(
        grid.canPlace(row: 0, column: -1, rowSpan: 1, columnSpan: 1),
        isFalse,
      );
    });

    test('canPlace ignores the moving item itself', () {
      final item = grid.items.first;
      expect(
        grid.canPlace(
          row: item.row,
          column: item.column,
          rowSpan: 2,
          columnSpan: 2,
          ignore: item,
        ),
        isTrue,
      );
    });

    test('firstFreeSpot finds reading-order placement', () {
      final spot = grid.firstFreeSpot(1, 1);
      expect(spot, (0, 1));
    });

    test('nearestFreeSpot shifts to the closest valid cell', () {
      final spot = grid.nearestFreeSpot(
        row: 0,
        column: 0,
        rowSpan: 1,
        columnSpan: 1,
      );
      expect(spot, isNotNull);
      expect(spot, isNot((0, 0)));
    });
  });

  test('default template has no collisions and fits the grid', () {
    final grid = RemoteGridLayout.defaultTemplate();
    final occupied = <String>{};
    for (final item in grid.items) {
      expect(
        item.column + item.effectiveColumnSpan,
        lessThanOrEqualTo(kLayoutGridColumns),
        reason: '${item.remoteKey ?? item.block} overflows the grid',
      );
      final cells = RemoteGridLayout.cellsOf(item);
      expect(
        cells.any(occupied.contains),
        isFalse,
        reason: '${item.remoteKey ?? item.block} collides',
      );
      occupied.addAll(cells);
    }
  });

  test('default template round-trips', () {
    final grid = RemoteGridLayout.defaultTemplate();
    expect(RemoteGridLayout.tryFromJsonString(grid.toJsonString()), grid);
  });
}

extension on RemoteGridLayout {
  String toJsonString() => jsonEncode(toJson());
}
