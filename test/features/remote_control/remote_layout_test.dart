import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openzap/features/remote_control/domain/remote_key.dart';
import 'package:openzap/features/remote_control/domain/remote_layout.dart';

void main() {
  group('LayoutItem', () {
    test('key items report their geometry', () {
      const item = LayoutItem.key(
        remoteKey: RemoteKey.power,
        x: 10,
        y: 20,
        width: 64,
        height: 48,
      );
      expect(item.isKey, isTrue);
      expect(item.left, 10);
      expect(item.right, 74);
      expect(item.centerX, 42);
      expect(item.bottom, 68);
    });

    test('block items default to the button size unless given one', () {
      const item = LayoutItem.block(block: LayoutBlock.tvStatus, x: 0, y: 0);
      expect(item.isKey, isFalse);
      expect(item.width, kDefaultButtonSize);
    });
  });

  group('FreeRemoteLayout serialization', () {
    test('round-trips through JSON', () {
      final layout = FreeRemoteLayout([
        const LayoutItem.block(block: LayoutBlock.tvStatus, x: 8, y: 8),
        const LayoutItem.key(remoteKey: RemoteKey.power, x: 8, y: 88),
        const LayoutItem.key(
          remoteKey: RemoteKey.volumeUp,
          x: 80,
          y: 88,
          width: 120,
          height: 64,
        ),
      ]);
      final decoded = FreeRemoteLayout.tryFromJsonString(
        jsonEncode(layout.toJson()),
      );
      expect(decoded, layout);
    });

    test('returns null on malformed input', () {
      expect(FreeRemoteLayout.tryFromJsonString('not json'), isNull);
      expect(FreeRemoteLayout.tryFromJsonString('[1,2,3]'), isNull);
      expect(FreeRemoteLayout.tryFromJsonString(null), isNull);
    });

    test('drops unknown keys and blocks', () {
      final layout = FreeRemoteLayout.tryFromJsonString(
        '{"version":2,"items":['
        '{"type":"key","key":"nonexistent","x":0,"y":0},'
        '{"type":"block","block":"sleepTimer","x":0,"y":48}'
        ']}',
      );
      expect(layout!.items, hasLength(1));
      expect(layout.items.single.block, LayoutBlock.sleepTimer);
    });

    test('clamps hostile coordinates and sizes', () {
      final layout = FreeRemoteLayout.tryFromJsonString(
        '{"version":2,"items":['
        '{"type":"key","key":"power","x":1000000000,"y":-5,'
        '"w":100000,"h":0}]}',
      );
      expect(layout!.items, hasLength(1));
      final item = layout.items.single;
      expect(item.x, kMaxCanvasExtent);
      expect(item.y, 0);
      expect(item.width, kMaxTileExtent);
      expect(item.height, kMinTileExtent);
    });

    test('rejects NaN and infinite coordinates', () {
      // jsonEncode cannot produce NaN/Infinity; feed the map directly.
      final layout = FreeRemoteLayout.tryFromJson({
        'version': 2,
        'items': [
          {'type': 'key', 'key': 'power', 'x': double.nan, 'y': 0},
          {'type': 'key', 'key': 'mute', 'x': 0, 'y': double.infinity},
          {'type': 'key', 'key': 'info', 'x': 0, 'y': 0},
        ],
      });
      expect(layout!.items, hasLength(1));
      expect(layout.items.single.remoteKey, RemoteKey.info);
    });

    test('migrates version-1 grid payloads to canvas coordinates', () {
      final layout = FreeRemoteLayout.tryFromJsonString(
        '{"version":1,"columns":4,"items":['
        '{"type":"key","key":"power","row":1,"column":2},'
        '{"type":"key","key":"volumeUp","row":2,"column":0,'
        '"rowSpan":2,"columnSpan":2},'
        '{"type":"block","block":"sleepTimer","row":3,"column":0},'
        '{"type":"key","key":"nonexistent","row":0,"column":0}'
        ']}',
      );
      expect(layout!.items, hasLength(3));
      final power = layout.items[0];
      expect(power.x, 8 + 2 * 80);
      expect(power.y, 8 + 1 * 80);
      expect(power.width, 72);
      expect(power.height, 72);
      final volume = layout.items[1];
      expect(volume.width, 2 * 72 + 8);
      expect(volume.height, 2 * 72 + 8);
      final timer = layout.items[2];
      expect(timer.width, kLayoutBlockSizes[LayoutBlock.sleepTimer]!.$1);
    });

    test('treats payloads without a version as grids', () {
      final layout = FreeRemoteLayout.tryFromJsonString(
        '{"items":[{"type":"key","key":"power","row":0,"column":0}]}',
      );
      expect(layout!.items, hasLength(1));
      expect(layout.items.single.x, 8);
    });
  });

  group('AlignmentSnap', () {
    test('snaps left edges within the threshold', () {
      const moving = LayoutItem.key(remoteKey: RemoteKey.power, x: 100, y: 0);
      const other = LayoutItem.key(remoteKey: RemoteKey.mute, x: 103, y: 200);
      final snap = AlignmentSnap.compute(moving: moving, others: [other]);
      expect(snap.dx, 3);
      expect(snap.verticalLines, [103]);
      expect(snap.dy, 0);
      expect(snap.horizontalLines, isEmpty);
    });

    test('ignores candidates beyond the threshold', () {
      const moving = LayoutItem.key(remoteKey: RemoteKey.power, x: 100, y: 0);
      const other = LayoutItem.key(remoteKey: RemoteKey.mute, x: 110, y: 200);
      final snap = AlignmentSnap.compute(moving: moving, others: [other]);
      expect(snap, AlignmentSnap.none);
      expect(snap.dx, 0);
    });

    test('snaps edges and reports exact alignment', () {
      const moving = LayoutItem.key(
        remoteKey: RemoteKey.power,
        x: 99,
        y: 100,
        width: 64,
        height: 64,
      );
      const near = LayoutItem.key(
        remoteKey: RemoteKey.mute,
        x: 164,
        y: 100,
        width: 64,
        height: 64,
      );
      const far = LayoutItem.key(
        remoteKey: RemoteKey.info,
        x: 300,
        y: 300,
        width: 64,
        height: 64,
      );
      final snap = AlignmentSnap.compute(moving: moving, others: [near, far]);
      // Right edge (163) meets near's left edge (164).
      expect(snap.dx, 1);
      expect(snap.verticalLines, [164]);
      // Tops already aligned.
      expect(snap.dy, 0);
      expect(snap.horizontalLines, [100]);
    });

    test('respects the ignore parameter', () {
      const moving = LayoutItem.key(remoteKey: RemoteKey.power, x: 100, y: 0);
      const other = LayoutItem.key(remoteKey: RemoteKey.mute, x: 103, y: 0);
      final snap = AlignmentSnap.compute(
        moving: moving,
        others: [other],
        ignore: other,
      );
      expect(snap.dx, 0);
    });
  });

  test('snaps to the canvas origin when enabled', () {
    const moving = LayoutItem.key(remoteKey: RemoteKey.power, x: 4, y: 200);
    final snap = AlignmentSnap.compute(
      moving: moving,
      others: const [],
      includeOrigin: true,
    );
    expect(snap.dx, -4);
    expect(snap.verticalLines, [0]);
    expect(snap.dy, 0);
    expect(snap.horizontalLines, isEmpty);
  });

  test('ignores the canvas origin by default', () {
    const moving = LayoutItem.key(remoteKey: RemoteKey.power, x: 4, y: 3);
    final snap = AlignmentSnap.compute(moving: moving, others: const []);
    expect(snap.dx, 0);
    expect(snap.dy, 0);
  });

  group('SizeSnap', () {
    test('snaps width to a neighbour width', () {
      const item = LayoutItem.key(
        remoteKey: RemoteKey.power,
        x: 8,
        y: 8,
        width: 60,
        height: 64,
      );
      const other = LayoutItem.key(
        remoteKey: RemoteKey.mute,
        x: 200,
        y: 8,
        width: 64,
        height: 64,
      );
      final snap = SizeSnap.compute(
        item: item,
        width: 60,
        height: 64,
        others: [other],
        ignore: item,
      );
      expect(snap.width, 64);
      expect(snap.verticalLines, [8 + 64]);
    });

    test('snaps the right edge to a neighbour edge', () {
      const item = LayoutItem.key(
        remoteKey: RemoteKey.power,
        x: 8,
        y: 8,
        width: 60,
        height: 64,
      );
      // Other tile spans x=200..264; growing item to width 192 would put its
      // right edge at 200 (other's left edge) — 4px short of 196? No:
      // width 190 -> right edge 198, 2px from 200 -> snaps to 192.
      const other = LayoutItem.key(
        remoteKey: RemoteKey.mute,
        x: 200,
        y: 8,
        width: 64,
        height: 64,
      );
      final snap = SizeSnap.compute(
        item: item,
        width: 190,
        height: 64,
        others: [other],
        ignore: item,
      );
      expect(snap.width, 192);
      expect(snap.verticalLines, [200]);
    });

    test('ignores negative and tiny candidates', () {
      const item = LayoutItem.key(
        remoteKey: RemoteKey.power,
        x: 200,
        y: 8,
        width: 60,
        height: 64,
      );
      // Other sits left of the item with a far-off width: edge candidates
      // would be negative and must not snap the width.
      const other = LayoutItem.key(
        remoteKey: RemoteKey.mute,
        x: 8,
        y: 8,
        width: 100,
        height: 64,
      );
      final snap = SizeSnap.compute(
        item: item,
        width: 60,
        height: 64,
        others: [other],
        ignore: item,
      );
      expect(snap.width, 60);
      expect(snap.verticalLines, isEmpty);
    });

    test('leaves far sizes alone', () {
      const item = LayoutItem.key(
        remoteKey: RemoteKey.power,
        x: 8,
        y: 8,
        width: 60,
        height: 64,
      );
      const other = LayoutItem.key(
        remoteKey: RemoteKey.mute,
        x: 300,
        y: 300,
        width: 100,
        height: 100,
      );
      final snap = SizeSnap.compute(
        item: item,
        width: 60,
        height: 64,
        others: [other],
        ignore: item,
      );
      expect(snap.width, 60);
      expect(snap.height, 64);
      expect(snap.verticalLines, isEmpty);
      expect(snap.horizontalLines, isEmpty);
    });
  });

  test('default template stays within canvas bounds', () {
    final layout = FreeRemoteLayout.defaultTemplate();
    expect(layout.items, isNotEmpty);
    for (final item in layout.items) {
      expect(item.x, inInclusiveRange(0, kMaxCanvasExtent));
      expect(item.y, inInclusiveRange(0, kMaxCanvasExtent));
      expect(item.width, inInclusiveRange(kMinTileExtent, kMaxTileExtent));
      expect(item.height, inInclusiveRange(kMinTileExtent, kMaxTileExtent));
    }
    expect(
      FreeRemoteLayout.tryFromJsonString(jsonEncode(layout.toJson())),
      layout,
    );
  });

  group('SavedRemoteLayout', () {
    test('round-trips through the store helpers', () {
      const entry = SavedRemoteLayout(
        id: 'a',
        name: 'Salon',
        gridJson: '{"version":2,"items":[]}',
      );
      final encoded = serializeSavedLayouts([entry]);
      final decoded = parseSavedLayouts(encoded);
      expect(decoded, [entry]);
    });

    test('drops duplicates and invalid entries', () {
      final decoded = parseSavedLayouts(
        '[{"id":"a","name":"A","grid":"g"},{"id":"a","name":"B","grid":"g"},'
        '{"id":"","name":"C","grid":"g"},{"nope":1}]',
      );
      expect(decoded, hasLength(1));
      expect(decoded.single.name, 'A');
    });

    test('returns empty on malformed input', () {
      expect(parseSavedLayouts('nope'), isEmpty);
      expect(parseSavedLayouts('{"a":1}'), isEmpty);
    });
  });
}
