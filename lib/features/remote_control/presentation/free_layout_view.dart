import 'package:flutter/material.dart';

import '../domain/remote_layout.dart';

/// Renders the items of a [FreeRemoteLayout] as absolutely-positioned tiles.
///
/// The widget is purely geometric: callers decide how each tile is drawn via
/// [itemBuilder], which keeps the same canvas usable for the read-only remote
/// screen and for the interactive layout editor. Content wider than the
/// available width scrolls horizontally so nothing designed on a wide screen
/// becomes unreachable on a narrow one.
///
/// Tiles are identified by their list [index]: duplicate tiles with identical
/// geometry are allowed, so callers must not rely on value equality.
class FreeLayoutView extends StatelessWidget {
  const FreeLayoutView({
    super.key,
    required this.layout,
    required this.itemBuilder,
    this.underlayBuilder,
    this.overlayBuilder,
    this.minHeight = 200,
  });

  final FreeRemoteLayout layout;

  final Widget Function(BuildContext context, int index, LayoutItem item)
  itemBuilder;

  /// Widgets rendered beneath the tiles (e.g. alignment guide lines).
  final List<Widget> Function(BuildContext context)? underlayBuilder;

  /// Extra widgets rendered on top of the tiles.
  final List<Widget> Function(BuildContext context)? overlayBuilder;

  final double minHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 0.0;
        var contentRight = 0.0;
        var contentBottom = 0.0;
        for (final item in layout.items) {
          if (item.right > contentRight) {
            contentRight = item.right;
          }
          if (item.bottom > contentBottom) {
            contentBottom = item.bottom;
          }
        }
        final width = availableWidth > contentRight + 16
            ? availableWidth
            : contentRight + 16;
        final height = contentBottom + 24 < minHeight
            ? minHeight
            : contentBottom + 24;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ...?(underlayBuilder?.call(context)),
                for (var index = 0; index < layout.items.length; index++)
                  Positioned(
                    left: layout.items[index].x,
                    top: layout.items[index].y,
                    width: layout.items[index].width,
                    height: layout.items[index].height,
                    child: itemBuilder(context, index, layout.items[index]),
                  ),
                ...?(overlayBuilder?.call(context)),
              ],
            ),
          ),
        );
      },
    );
  }
}
