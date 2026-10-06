import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/theme.dart';
import 'brand.dart';
import 'buttons.dart';
import 'itext.dart';

/// `radial-gradient(closest-side, color, transparent)` filling its box.
class ClosestSideGlow extends StatelessWidget {
  const ClosestSideGlow(this.color, this.alpha, {super.key});

  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) =>
      CssRadialGradient(rx: 0.5, ry: 0.5, cx: 0.5, cy: 0.5, colors: [color.o(alpha), color.o(0)], stops: const [0, 1]);
}

/// Small colored legend swatch + label.
class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label, this.size = 8, this.radius, this.style});

  final Color color;
  final String label;
  final double size;
  final double? radius;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius ?? size / 2)),
      ),
      const SizedBox(width: 6),
      Flexible(child: Text(label, style: style)),
    ],
  );
}

/// The 25 × 25 QR pattern from the design (decorative; real codes come from the camera).
class DecorativeQR extends StatelessWidget {
  const DecorativeQR({super.key});

  static const rows = [
    '#######.##.#.##.#.#######',
    '#.....#.####.##...#.....#',
    '#.###.#..#.#.####.#.###.#',
    '#.###.#..#..#.###.#.###.#',
    '#.###.#..##.##..#.#.###.#',
    '#.....#.....#.##..#.....#',
    '#######.#.#.#.#.#.#######',
    '........#.#....#.........',
    '..#..##.#....##.#####.###',
    '.##.....###..####..####..',
    '....#.#...###.###########',
    '..####.#..#.####.##..#.#.',
    '...####...##......#.#####',
    '..#....#####...#..#....##',
    '.#..###..###..#...#.##...',
    '.#..##.##.###.##..#....##',
    '##.##.#.#...#.########...',
    '.........#.#....#...#####',
    '#######.#...#..##.#.#...#',
    '#.....#.#.###.#.#...##...',
    '#.###.#.###.###.#####.##.',
    '#.###.#.##...#.#.##..##.#',
    '#.###.#.######.#.#####..#',
    '#.....#.#.#.#..#...#...##',
    '#######.###.###...#######',
  ];

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'QR code',
    child: const AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _QRPainter())),
  );
}

class _QRPainter extends CustomPainter {
  const _QRPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / 25;
    final paint = Paint()..color = Palette.ink;
    for (var r = 0; r < 25; r++) {
      final row = DecorativeQR.rows[r];
      for (var c = 0; c < 25; c++) {
        if (row[c] != '#') continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(c * cell, r * cell, cell, cell), const Radius.circular(1)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QRPainter old) => false;
}

/// Four L-shaped corner brackets.
class ScanCorners extends StatelessWidget {
  const ScanCorners({
    super.key,
    required this.length,
    required this.lineWidth,
    required this.radius,
    required this.color,
  });

  final double length, lineWidth, radius;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _CornersPainter(length, lineWidth, radius, color), size: Size.infinite),
  );
}

class _CornersPainter extends CustomPainter {
  _CornersPainter(this.length, this.w, this.radius, this.color);

  final double length, w, radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.butt;
    // One bracket in a length × length box inset by half the stroke, then rotated into each corner.
    final l = length - w;
    final r = math.min(radius, l);
    final bracket = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(l, 0);
    void at(double dx, double dy, double angle) {
      canvas
        ..save()
        ..translate(dx, dy)
        ..rotate(angle)
        ..translate(w / 2, w / 2)
        ..drawPath(bracket, paint)
        ..restore();
    }

    at(0, 0, 0);
    at(size.width, 0, math.pi / 2);
    at(size.width, size.height, math.pi);
    at(0, size.height, -math.pi / 2);
  }

  @override
  bool shouldRepaint(_CornersPainter old) => old.color != color;
}

/// Full-screen dim with a rounded hole (box-shadow: 0 0 0 999px rgba(2,6,14,a)).
class DimmedSurround extends StatelessWidget {
  const DimmedSurround({super.key, required this.hole, required this.radius, required this.color});

  final Rect hole;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _HolePainter(hole, radius, color), size: Size.infinite),
  );
}

class _HolePainter extends CustomPainter {
  _HolePainter(this.hole, this.radius, this.color);

  final Rect hole;
  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect((Offset.zero & size).inflate(500))
      ..addPath(RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius)).getOuterPath(hole), Offset.zero);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.hole != hole || old.color != color;
}

/// A fixed 390 × 844 design canvas scaled uniformly to the screen, for absolutely positioned art.
class DesignCanvas extends StatelessWidget {
  const DesignCanvas({super.key, required this.children, this.background});

  final List<Widget> children;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final s = math.min(box.maxWidth / 390, box.maxHeight / 844);
        return ColoredBox(
          color: background ?? const Color(0x00000000),
          child: MediaQuery.withNoTextScaling(
            child: Center(
              child: OverflowBox(
                maxWidth: 390,
                maxHeight: 844,
                child: Transform.scale(
                  scale: s,
                  child: SizedBox(
                    width: 390,
                    height: 844,
                    child: Stack(clipBehavior: Clip.none, children: children),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Absolute placement in a canvas (CSS left/top/width/height).
Widget place(double x, double y, double w, double h, Widget child) =>
    Positioned(left: x, top: y, width: math.max(w, 0.01), height: math.max(h, 0.01), child: child);

/// An open arch outline.
class ArchOutline extends StatelessWidget {
  const ArchOutline({super.key, required this.color, this.lineWidth = 1.5});

  final Color color;
  final double lineWidth;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: ArchOutlinePainter(color: color, lineWidth: lineWidth),
    size: Size.infinite,
  );
}

/// `.sp-ring` looping every [duration] s: an arch outline scaling .15 → 1 while fading 0 → .7 → 0.
class LoopingArchRing extends StatelessWidget {
  const LoopingArchRing({
    super.key,
    required this.t,
    required this.width,
    required this.height,
    required this.color,
    required this.delay,
    this.duration = 3,
  });

  final double t, width, height, delay, duration;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final local = t - delay;
    final raw = local < 0 ? 0.0 : (local % duration) / duration;
    const c = Motion.standard;
    final opacity = local < 0
        ? 0.0
        : (raw < 0.25 ? mix(0, 0.7, c.transform(raw / 0.25)) : mix(0.7, 0, c.transform((raw - 0.25) / 0.75)));
    return SizedBox(
      width: width,
      height: height,
      child: Opacity(
        opacity: opacity.clamp(0, 1),
        child: Transform.scale(
          scale: mix(0.15, 1, c.transform(raw)),
          child: ArchOutline(color: color),
        ),
      ),
    );
  }
}

/// The logo assembling itself: roof grows from the bottom, the sun rises and glows, door grows, bush pops.
class MarkIntro extends StatelessWidget {
  const MarkIntro({super.key, required this.width, required this.t});

  final double width;

  /// Seconds since the animation started.
  final double t;

  static double triangle(double x) {
    final f = x - x.floorToDouble();
    return f < 0.5 ? f * 2 : (1 - f) * 2;
  }

  @override
  Widget build(BuildContext context) {
    final k = width / 104;
    final roof = keyframe(t, delay: 0.35, duration: 1.05, curve: const Cubic(0.2, 0.9, 0.2, 1));
    final sun = keyframe(t, delay: 0.85, duration: 1.3);
    final door = keyframe(t, delay: 1.25, duration: 0.75, curve: const Cubic(0.2, 0.9, 0.2, 1));
    final bushRaw = ((t - 1.55) / 0.65).clamp(0.0, 1.0);
    final bush = const Cubic(0.2, 0.9, 0.3, 1.5).transform(bushRaw);
    // sunGlow: 3.2 s ease-in-out infinite from 2.2 s, 36/4 .45 <-> 70/14 .65 (at 150 px; scales with the mark)
    final g = t < 2.2 ? 0.0 : Motion.easeInOut.transform(triangle((t - 2.2) / 3.2));
    final f = width / 150;
    final glowBlur = mix(36, 70, g) * f, glowSpread = mix(4, 14, g) * f, glowAlpha = mix(0.45, 0.65, g);
    final sunD = 54 * k;

    Widget grow(double p, Widget child) => Transform(
      alignment: Alignment.bottomCenter,
      transform: Matrix4.diagonal3Values(1, math.max(p, 0.0001), 1),
      child: child,
    );

    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: 100 * k,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 50 * k,
              top: sunD * 0.7 * (1 - sun),
              width: sunD,
              height: sunD,
              child: Opacity(
                opacity: sun.clamp(0, 1),
                child: Transform.scale(
                  scale: mix(0.55, 1, sun),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      OverflowBox(
                        maxWidth: sunD + glowSpread * 2,
                        maxHeight: sunD + glowSpread * 2,
                        child: blurred(
                          glowBlur / 2,
                          Container(
                            width: sunD + glowSpread * 2,
                            height: sunD + glowSpread * 2,
                            decoration: BoxDecoration(color: Palette.yellow.o(glowAlpha), shape: BoxShape.circle),
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(color: Palette.yellow, shape: BoxShape.circle),
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 18 * k,
              width: 70 * k,
              height: 82 * k,
              child: grow(
                roof,
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: Palette.roofGradient,
                    borderRadius: cornerBox(35 * k, 35 * k, 5 * k, 5 * k),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 22 * k,
              top: 62 * k,
              width: 26 * k,
              height: 38 * k,
              child: grow(
                door,
                DecoratedBox(
                  decoration: BoxDecoration(color: Palette.orange, borderRadius: cornerBox(13 * k, 13 * k, 0, 0)),
                ),
              ),
            ),
            Positioned(
              left: 81 * k,
              top: 77 * k,
              width: 19 * k,
              height: 23 * k,
              child: Opacity(
                opacity: bush.clamp(0, 1),
                child: Transform.scale(
                  scale: math.max(bush, 0.0001),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Palette.green,
                      borderRadius: cornerBox(9.5 * k, 9.5 * k, 3 * k, 3 * k),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom CTA bar: padding 16 / 20 / 8 over linear-gradient(transparent, #08142A 35%), extending under the home indicator.
class BottomCTABar extends StatelessWidget {
  const BottomCTABar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.night.o(0), Palette.night],
          stops: const [0, 0.35],
        ),
      ),
      child: Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 8 + bottom), child: child),
    );
  }
}

/// Shared sheet success state: 84 pt popping check, title, message, Done.
class SheetSuccess extends StatelessWidget {
  const SheetSuccess({
    super.key,
    required this.title,
    this.message,
    this.color = Palette.green,
    this.verticalPadding = 8,
    required this.onDone,
  });

  final String title;
  final String? message;
  final Color color;
  final double verticalPadding;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            CheckDisc(size: 84, iconSize: 40, color: color).pop(),
            const SizedBox(height: 18),
            IText(title, textAlign: TextAlign.center, style: Typo.h1(26)),
            if (message != null) ...[
              const SizedBox(height: 8),
              IText(message!, textAlign: TextAlign.center, style: Typo.mutedBody(14)),
            ],
            const SizedBox(height: 20),
            PrimaryButton('Done', icon: null, onTap: onDone),
          ],
        ),
      ),
    );
  }
}

/// Filled circle with a white check (or other icon).
class CheckDisc extends StatelessWidget {
  const CheckDisc({
    super.key,
    required this.size,
    required this.iconSize,
    required this.color,
    this.icon = TIcon.check,
    this.halos = const [],
  });

  final double size, iconSize;
  final Color color;
  final TIcon icon;

  /// (inset, color) rings drawn behind the disc, like `.background(Circle().padding(-inset))`.
  final List<(double, Color)> halos;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          for (final (inset, c) in halos.reversed)
            Positioned(
              left: -inset,
              top: -inset,
              right: -inset,
              bottom: -inset,
              child: DecoratedBox(
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
            ),
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: TIconView(icon, size: iconSize, color: const Color(0xFFFFFFFF)),
          ),
        ],
      ),
    );
  }
}

/// Rounded rectangle with a dashed border.
class DashedBorder extends StatelessWidget {
  const DashedBorder({
    super.key,
    required this.radius,
    required this.color,
    this.width = 1,
    this.dash = 4,
    this.gap = 3,
    this.fill,
    required this.child,
  });

  final double radius, width, dash, gap;
  final Color color;
  final Color? fill;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DashPainter(radius, color, width, dash, gap, fill, null), child: child);
}

/// An arch with a dashed outline.
class DashedArch extends StatelessWidget {
  const DashedArch({super.key, required this.color, this.width = 1.5, this.dash = 5, this.gap = 4});

  final Color color;
  final double width, dash, gap;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _DashPainter(0, color, width, dash, gap, null, const ArchBorder()), size: Size.infinite);
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.radius, this.color, this.width, this.dash, this.gap, this.fill, this.shape);

  final double radius, width, dash, gap;
  final Color color;
  final Color? fill;
  final ShapeBorder? shape;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final outline =
        shape?.getOuterPath(rect) ?? (Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius))));
    if (fill != null) canvas.drawPath(outline, Paint()..color = fill!);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final metric in outline.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, math.min(d + dash, metric.length)), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color || old.fill != fill;
}

/// The support agent avatar: a 30 pt yellow circle with a 16 pt mark.
class AgentAvatar extends StatelessWidget {
  const AgentAvatar({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: Palette.yellow, shape: BoxShape.circle),
    child: const TahananMark(width: 16),
  );
}

/// Diagonal stripes: repeating-linear-gradient(135deg, rgba(255,255,255,.03) 0 10px, transparent 10px 20px).
class DiagonalStripes extends StatelessWidget {
  const DiagonalStripes({super.key});

  @override
  Widget build(BuildContext context) => const CustomPaint(painter: _DiagonalPainter(), size: Size.infinite);
}

class _DiagonalPainter extends CustomPainter {
  const _DiagonalPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const period = 20 * 1.4142135623730951;
    final paint = Paint()..color = Palette.white(0.03);
    for (var x = -size.height; x < size.width + size.height; x += period) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + period / 2, 0)
          ..lineTo(x + period / 2 + size.height, size.height)
          ..lineTo(x + size.height, size.height)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalPainter old) => false;
}

/// Headline-style horizontal scroller that bleeds to the screen edges with 20 pt content margins.
class EdgeScroller extends StatelessWidget {
  const EdgeScroller({super.key, required this.height, required this.children, this.spacing = 8});

  final double height, spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (context, box) => OverflowBox(
        minWidth: box.maxWidth + Spacing.gutter * 2,
        maxWidth: box.maxWidth + Spacing.gutter * 2,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
          itemCount: children.length,
          separatorBuilder: (_, _) => SizedBox(width: spacing),
          itemBuilder: (_, i) => Center(child: children[i]),
        ),
      ),
    ),
  );
}
