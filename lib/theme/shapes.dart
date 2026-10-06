import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The brand arch: top corners are full semicircles (`W/2 W/2 r r`), bottom corners [bottomRadius].
class ArchBorder extends OutlinedBorder {
  const ArchBorder({this.bottomRadius = 18, super.side});

  final double bottomRadius;

  Path _path(Rect rect) {
    final top = math.min(rect.width / 2, rect.height);
    final bottom = math.max(0.0, math.min(bottomRadius, math.min(rect.height - top, rect.width / 2)));
    return Path()..addRRect(
      RRect.fromRectAndCorners(
        rect,
        topLeft: Radius.circular(top),
        topRight: Radius.circular(top),
        bottomLeft: Radius.circular(bottom),
        bottomRight: Radius.circular(bottom),
      ),
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.strokeInset));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    // SwiftUI `.stroke` centers the line on the edge.
    canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  ArchBorder copyWith({BorderSide? side, double? bottomRadius}) =>
      ArchBorder(side: side ?? this.side, bottomRadius: bottomRadius ?? this.bottomRadius);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  ShapeBorder scale(double t) => ArchBorder(side: side.scale(t), bottomRadius: bottomRadius * t);
}

/// Open arch outline (sides + semicircular top, no bottom), used for the expanding rings.
class ArchOutlinePainter extends CustomPainter {
  ArchOutlinePainter({required this.color, required this.lineWidth});

  final Color color;
  final double lineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final p = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, r)
      ..arcTo(Rect.fromCircle(center: Offset(r, r), radius: r), math.pi, math.pi, false)
      ..lineTo(size.width, size.height);
    canvas.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth,
    );
  }

  @override
  bool shouldRepaint(ArchOutlinePainter old) => old.color != color || old.lineWidth != lineWidth;
}

/// CSS `border-radius: tl tr br bl`.
BorderRadius cornerBox(double tl, double tr, double br, double bl) => BorderRadius.only(
  topLeft: Radius.circular(tl),
  topRight: Radius.circular(tr),
  bottomRight: Radius.circular(br),
  bottomLeft: Radius.circular(bl),
);

/// iOS `.continuous` rounded rectangle.
ShapeBorder squircle(double radius, {BorderSide side = BorderSide.none}) =>
    RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius), side: side);

/// Inside stroke, matching SwiftUI `strokeBorder`.
BorderSide hairline(Color color, [double width = 1]) =>
    BorderSide(color: color, width: width, strokeAlign: BorderSide.strokeAlignInside);
