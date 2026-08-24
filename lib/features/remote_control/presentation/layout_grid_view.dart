import 'package:flutter/material.dart';

import '../domain/remote_layout.dart';

/// Renders the items of a [RemoteGridLayout] as a positioned grid.
///
/// The widget is purely geometric: callers decide how each item is drawn via
/// [itemBuilder], which keeps the same grid usable for the read-only remote
/// screen and for the interactive layout editor.
class LayoutGridView extends StatelessWidget {
  const LayoutGridView({
    super.key,
    required this.grid,
    required this.itemBuilder,
    this.gap = 8,
    this.offsetOverride,
    this.overlayBuilder,
  });

  final RemoteGridLayout grid;

  final Widget Function(BuildContext context, LayoutItem item) itemBuilder;

  /// Spacing between cells in logical pixels.
  final double gap;

  /// Lets callers move an item's rendered position (e.g. while it is being
  /// dragged). Receives the computed origin and returns the one to use.
  final Offset Function(LayoutItem item, Offset origin)? offsetOverride;

  /// Extra widgets rendered on top of the grid (e.g. a drop-target ghost).
  final List<Widget> Function(BuildContext context)? overlayBuilder;

  static double cellSizeFor(double maxWidth, double gap) =>
      (maxWidth - gap * (kLayoutGridColumns - 1)) / kLayoutGridColumns;

  /// Total number of rows needed to render [grid].
  static int rowCountFor(RemoteGridLayout grid) {
    var rows = 0;
    for (final item in grid.items) {
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
        final cell = cellSizeFor(constraints.maxWidth, gap);
        final rows = rowCountFor(grid);
        return SizedBox(
          height: rows > 0 ? rows * cell + (rows - 1) * gap : 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final item in grid.items)
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
