import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'buttons.dart';

/// Vertical scroller with the prototype's screen padding (2 below the safe area, 20 gutters).
class ScreenScroll extends StatelessWidget {
  const ScreenScroll({
    super.key,
    this.horizontal = Spacing.gutter,
    this.top = Spacing.belowStatusBar,
    this.bottom = 40,
    required this.children,
  });

  final double horizontal, top, bottom;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(horizontal, insets.top + top, horizontal, insets.bottom + bottom),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

/// Back button + Outfit 20 / 600 title.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle, this.titleSize = 20, required this.onBack});

  final String title;
  final String? subtitle;
  final double titleSize;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BackCircleButton(onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Typo.outfit(titleSize, Typo.semibold, Palette.text)),
              if (subtitle != null) Text(subtitle!, style: Typo.manrope(12, Typo.bold, Palette.subtle)),
            ],
          ),
        ),
      ],
    );
  }
}

/// iOS scroll feel on every platform: bounce, no glow, no scrollbars (native uses `showsIndicators: false`).
class TahananScrollBehavior extends ScrollBehavior {
  const TahananScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) => child;
}

/// SwiftUI `.scrollTargetBehavior(.viewAligned)`: settles with an item's leading edge on the content margin.
class SnapPhysics extends ScrollPhysics {
  const SnapPhysics(this.extent, {super.parent});

  final double extent;

  @override
  SnapPhysics applyTo(ScrollPhysics? ancestor) => SnapPhysics(extent, parent: buildParent(ancestor));

  @override
  ScrollPhysics? buildParent(ScrollPhysics? ancestor) =>
      super.buildParent(ancestor) ?? const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    final tol = toleranceFor(position);
    final projected = position.pixels + velocity * 0.35;
    final page = (velocity.abs() < tol.velocity ? position.pixels : projected) / extent;
    final target = (page.round() * extent).clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < tol.distance) return null;
    return ScrollSpringSimulation(spring, position.pixels, target, velocity, tolerance: tol);
  }

  @override
  bool get allowImplicitScrolling => false;
}
