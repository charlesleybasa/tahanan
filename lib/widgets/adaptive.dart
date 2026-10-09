import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// Centers [child] and caps its width (default: one content column). A no-op on phones.
class MaxWidth extends StatelessWidget {
  const MaxWidth({super.key, this.width = Layout.content, this.alignment = Alignment.topCenter, required this.child});

  final double width;
  final AlignmentGeometry alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: alignment,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: child,
    ),
  );
}

/// Two panes side by side when the window allows it, otherwise `null` so the caller lays out a single column.
///
/// On a device with a vertical hinge the split follows the hinge exactly (nothing is drawn under it); on a wide
/// window without a hinge the [start] pane takes [startFraction] of the width.
class AdaptivePanes extends StatelessWidget {
  const AdaptivePanes({super.key, required this.start, required this.end, this.startFraction = 0.46, this.gap = 0});

  final Widget start, end;
  final double startFraction, gap;

  /// Whether [AdaptivePanes] would split at this window size.
  static bool splits(BuildContext context) =>
      Layout.verticalHinge(context) != null || Layout.width(context) >= Layout.twoPane;

  @override
  Widget build(BuildContext context) {
    final hinge = Layout.verticalHinge(context);
    if (hinge != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: hinge.left, child: start),
          SizedBox(width: hinge.width),
          Expanded(child: end),
        ],
      );
    }
    final w = Layout.width(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: w * startFraction, child: start),
        SizedBox(width: gap),
        Expanded(child: end),
      ],
    );
  }
}
