import 'dart:ui' show DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// Adaptive layout rules shared by every screen (Material 3 window-size classes).
///
/// * **Compact** (< 600 dp): phones and folded foldables — the 390 pt design, edge to edge.
/// * **Medium** (600–839 dp): unfolded Galaxy Z Fold / Pixel Fold, small tablets — content stays in a centered
///   [content]-wide column so lines and tap targets keep phone proportions.
/// * **Expanded** (≥ 840 dp): tablets — screens that have two natural halves (brand and unit pages) split into panes.
///
/// A device whose hinge physically separates the screen (Surface Duo, a half-opened book-style foldable) never gets
/// content under the hinge: single-column screens sit on one side, two-pane screens put one pane on each side.
abstract final class Layout {
  static const medium = 600.0;
  static const expanded = 840.0;

  /// Max width of a single content column.
  static const content = 600.0;

  /// Max width of bottom bars, sheets and the tab bar.
  static const bar = 560.0;

  /// Width from which the brand and unit pages show two panes.
  static const twoPane = 760.0;

  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => width(context) < medium;

  /// A vertical hinge or half-opened fold that splits the window into left and right screens, in global coordinates.
  static Rect? verticalHinge(BuildContext context) {
    final mq = MediaQuery.of(context);
    for (final f in mq.displayFeatures) {
      final separates =
          f.bounds.width > 0 || f.state == DisplayFeatureState.postureHalfOpened || f.type == DisplayFeatureType.hinge;
      final vertical = f.bounds.height >= mq.size.height * 0.9 && f.bounds.width < mq.size.width * 0.2;
      if (separates && vertical && f.type != DisplayFeatureType.cutout) return f.bounds;
    }
    return null;
  }
}
