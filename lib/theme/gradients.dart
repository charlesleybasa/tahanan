import 'package:flutter/widgets.dart';

import 'colors.dart';

/// CSS `radial-gradient(RX RY at CX CY, stops…)`: radii and center are fractions of the box.
class CssRadialGradient extends StatelessWidget {
  const CssRadialGradient({
    super.key,
    required this.rx,
    required this.ry,
    required this.cx,
    required this.cy,
    required this.colors,
    required this.stops,
  });

  final double rx, ry, cx, cy;
  final List<Color> colors;
  final List<double> stops;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _RadialPainter(this), size: Size.infinite),
  );
}

class _RadialPainter extends CustomPainter {
  _RadialPainter(this.g);

  final CssRadialGradient g;

  @override
  void paint(Canvas canvas, Size size) {
    final radiusX = (g.rx * size.width).clamp(0.001, double.infinity);
    final radiusY = (g.ry * size.height).clamp(0.001, double.infinity);
    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(g.cx * size.width, g.cy * size.height)
      ..scale(1, radiusY / radiusX);
    final reach = size.longestSide * 4;
    final rect = Rect.fromCircle(center: Offset.zero, radius: radiusX);
    canvas
      ..drawRect(
        Rect.fromLTRB(-reach, -reach, reach, reach),
        Paint()..shader = RadialGradient(colors: g.colors, stops: g.stops).createShader(rect),
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_RadialPainter old) => false;
}

/// The ground behind every screen (spec §1.7).
class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: Palette.night),
          CssRadialGradient(
            rx: 0.7,
            ry: 0.4,
            cx: -0.1,
            cy: 1.05,
            colors: [Color(0x17FFC42E), Color(0x00FFC42E)],
            stops: [0, 0.6],
          ),
          CssRadialGradient(
            rx: 1.1,
            ry: 0.55,
            cx: 0.85,
            cy: -0.08,
            colors: [Color(0x572E6BE6), Color(0x002E6BE6)],
            stops: [0, 0.62],
          ),
        ],
      ),
    );
  }
}

/// Diagonal navy stripes: repeating-linear-gradient(-45deg, ink@.95 0 6px, ink@.72 6px 12px).
class StripesPainter extends CustomPainter {
  const StripesPainter({this.dark = 0.95, this.light = 0.72});

  final double dark, light;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Palette.ink.o(light));
    const period = 12 * 1.4142135623730951;
    final paint = Paint()..color = Palette.ink.o(dark);
    for (var x = -size.height; x < size.width + size.height; x += period) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + size.height, 0)
          ..lineTo(x + size.height + period / 2, 0)
          ..lineTo(x + period / 2, size.height)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StripesPainter old) => old.dark != dark || old.light != light;
}
