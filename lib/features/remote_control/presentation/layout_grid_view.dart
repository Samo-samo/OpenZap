import 'package:flutter/material.dart';

import '../domain/remote_layout.dart';

/// Renders the items of a [RemoteGridLayout] as a positioned grid.
///
/// The widget is purely geometric: callers decide how each item is drawn via
/// [itemBuilder], which keeps the same grid usable for the read-only remote
/// screen and for the interactive layout editor. Items placed beyond
/// [RemoteGridLayout.columns] are skipped so narrower screens can render a
/// wider design without overflowing.
class LayoutGridView extends StatelessWidget {
  const LayoutGridView({
    super.key,
    required this.grid,
    required this.itemBuilder,
    this.gap = 8,
    this.offsetOverride,
    this.underlayBuilder,
    this.overlayBuilder,
  });

  final RemoteGridLayout grid;

  final Widget Function(BuildContext context, LayoutItem item) itemBuilder;

  /// Spacing between cells in logical pixels.
  final double gap;

  /// Lets callers move an item's rendered position (e.g. while it is being
  /// dragged). Receives the computed origin and returns the one to use.
  final Offset Function(LayoutItem item, Offset origin)? offsetOverride;

  /// Widgets rendered beneath the items (e.g. faint cell guides).
  final List<Widget> Function(BuildContext context)? underlayBuilder;

  /// Extra widgets rendered on top of the items (e.g. drop-target ghosts).
  final List<Widget> Function(BuildContext context)? overlayBuilder;

  static double cellSizeFor(
    double maxWidth,
    double gap, {
    int columns = kLayoutGridColumns,
  }) => (maxWidth - gap * (columns - 1)) / columns;

  /// Total number of rows needed to render [grid].
  static int rowCountFor(RemoteGridLayout grid) {
    var rows = 0;
    for (final item in grid.items) {
      if (item.column >= grid.columns) {
        continue;
      }
      final bottom = item.row + item.effectiveRowSpan;
      if (bottom > rows) {
        rows = bottom;
      }
    }
    return rows;
  }

  static Offset originOf(LayoutItem item, double cell, double gap) =>
      Offset(item.column * (cell + gap), item.row * (cell + gap));

  static Size sizeOf(LayoutItem item, double cell, double gap) => Size(
    item.effectiveColumnSpan * cell + (item.effectiveColumnSpan - 1) * gap,
    item.effectiveRowSpan * cell + (item.effectiveRowSpan - 1) * gap,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = cellSizeFor(
          constraints.maxWidth,
          gap,
          columns: grid.columns,
        );
        final rows = rowCountFor(grid);
        return SizedBox(
          height: rows > 0 ? rows * cell + (rows - 1) * gap : 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ...?(underlayBuilder?.call(context)),
              for (final item in grid.items)
                if (item.column < grid.columns)
                  Builder(
                    builder: (context) {
                      var origin = originOf(item, cell, gap);
                      final override = offsetOverride;
                      if (override != null) {
                        origin = override(item, origin);
                      }
                      final size = sizeOf(item, cell, gap);
                      return Positioned(
                        left: origin.dx,
                        top: origin.dy,
                        width: size.width,
                        height: size.height,
                        child: KeyedSubtree(
                          key: ObjectKey(item),
                          child: itemBuilder(context, item),
                        ),
                      );
                    },
                  ),
              ...?(overlayBuilder?.call(context)),
            ],
          ),
        );
      },
    );
  }
}
