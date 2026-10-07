import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';

/// Vector placeholders for gallery categories that have no media yet. Each one is drawn in the app's palette
/// and labelled as a sample wherever it appears.
enum ArtKind { siteMap, floorPlan, nearby, amenities }

/// Room layout for the sample floor plan.
enum PlanKind { loftGround, loftUpper, studio, oneBedroom, twoBedroom, house }

class MediaArt extends StatelessWidget {
  const MediaArt({super.key, required this.kind, this.plan = PlanKind.house});

  final ArtKind kind;
  final PlanKind plan;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: switch (kind) {
        ArtKind.siteMap => const _SiteMapPainter(),
        ArtKind.floorPlan => _FloorPlanPainter(plan),
        ArtKind.nearby => const _NearbyPainter(),
        ArtKind.amenities => const _AmenitiesPainter(),
      },
      child: const SizedBox.expand(),
    );
  }
}

// MARK: Shared drawing helpers

const _ground = Color(0xFF0B1B36);

void _label(
  Canvas canvas,
  String text,
  Offset center, {
  double size = 10,
  Color color = Palette.muted,
  FontWeight weight = FontWeight.w800,
  double spacing = 0.6,
  Color? pill,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(fontFamily: 'Manrope', fontSize: size, fontWeight: weight, color: color, letterSpacing: spacing),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final o = center - Offset(tp.width / 2, tp.height / 2);
  if (pill != null) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(o.dx - 7, o.dy - 3.5, tp.width + 14, tp.height + 7),
      Radius.circular((tp.height + 7) / 2),
    );
    canvas.drawRRect(r, Paint()..color = pill);
  }
  tp.paint(canvas, o);
}

void _grid(Canvas canvas, Size size, double step, Color color) {
  final p = Paint()
    ..color = color
    ..strokeWidth = 1;
  for (var x = step; x < size.width; x += step) {
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
  }
  for (var y = step; y < size.height; y += step) {
    canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
  }
}

void _tree(Canvas canvas, Offset c, double r) {
  canvas.drawCircle(c + Offset(r * 0.25, r * 0.3), r, Paint()..color = const Color(0x55000000));
  canvas.drawCircle(c, r, Paint()..color = const Color(0xFF2FA96B));
  canvas.drawCircle(c - Offset(r * 0.3, r * 0.3), r * 0.45, Paint()..color = const Color(0xFF62D69C).o(0.55));
}

/// Fits a [w] × [h] design into [size], centred, and returns the scale.
double _fit(Canvas canvas, Size size, double w, double h, {double pad = 0}) {
  final k = math.min((size.width - pad * 2) / w, (size.height - pad * 2) / h);
  canvas.translate((size.width - w * k) / 2, (size.height - h * k) / 2);
  canvas.scale(k);
  return k;
}

// MARK: Site development plan

/// Lot blocks around a loop road, a central park, the main gate, and a highlighted open lot.
class _SiteMapPainter extends CustomPainter {
  const _SiteMapPainter();

  // Y = open, B = reserved, S = sold
  static const _rows = ['SYSBSSYYSB', 'YSSSBYSSYS', 'SBYSSSYBSS', 'SSYBYSSSYB'];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _ground);
    _grid(canvas, size, 18, Palette.white(0.025));
    canvas.save();
    _fit(canvas, size, 360, 240, pad: 6);

    final road = Paint()
      ..color = Palette.white(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    // Loop road and the entry spur.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(26, 22, 308, 176), const Radius.circular(36)), road);
    canvas.drawLine(const Offset(180, 198), const Offset(180, 236), road);
    final dash = Paint()
      ..color = Palette.yellow.o(0.35)
      ..strokeWidth = 1.2;
    for (var x = 60.0; x < 300; x += 14) {
      canvas.drawLine(Offset(x, 22), Offset(x + 6, 22), dash);
      canvas.drawLine(Offset(x, 198), Offset(x + 6, 198), dash);
    }

    // Park in the middle.
    final park = RRect.fromRectAndRadius(const Rect.fromLTWH(138, 84, 84, 52), const Radius.circular(16));
    canvas.drawRRect(park, Paint()..color = const Color(0xFF2FA96B).o(0.22));
    canvas.drawRRect(
      park,
      Paint()
        ..color = const Color(0xFF62D69C).o(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (final t in const [Offset(152, 98), Offset(206, 96), Offset(158, 124), Offset(200, 122), Offset(180, 110)]) {
      _tree(canvas, t, 5.5);
    }

    // Lot blocks: two above the park, two below.
    const lotW = 12.0, lotH = 18.0, gap = 2.5;
    void block(String lots, double x, double y) {
      for (var i = 0; i < lots.length; i++) {
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(x + i * (lotW + gap), y, lotW, lotH),
          const Radius.circular(2.5),
        );
        final color = switch (lots[i]) {
          'Y' => Palette.yellow.o(0.88),
          'B' => Palette.blue,
          _ => Palette.white(0.16),
        };
        canvas.drawRRect(r, Paint()..color = color);
      }
    }

    block(_rows[0], 44, 40);
    block(_rows[1], 44, 60);
    block(_rows[2], 196, 40);
    block(_rows[3], 196, 60);
    block(_rows[1].split('').reversed.join(), 44, 142);
    block(_rows[0].split('').reversed.join(), 44, 162);
    block(_rows[3].split('').reversed.join(), 196, 142);
    block(_rows[2].split('').reversed.join(), 196, 162);

    // Highlighted lot with a glow ring.
    const hl = Rect.fromLTWH(196 + 2 * (lotW + gap), 162, lotW, lotH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hl.inflate(5), const Radius.circular(6)),
      Paint()
        ..color = Palette.yellow.o(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(hl, const Radius.circular(2.5)), Paint()..color = Palette.yellow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(hl.inflate(2), const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    _label(canvas, 'PARK', const Offset(180, 140), size: 7, color: const Color(0xFF62D69C), spacing: 1.2);
    _label(
      canvas,
      'MAIN GATE',
      const Offset(180, 228),
      size: 7.5,
      color: Palette.ink,
      spacing: 1,
      pill: Palette.yellow,
    );

    // North arrow.
    final n = Path()
      ..moveTo(336, 6)
      ..lineTo(341, 18)
      ..lineTo(336, 15)
      ..lineTo(331, 18)
      ..close();
    canvas.drawPath(n, Paint()..color = Palette.soft);
    _label(canvas, 'N', const Offset(336, 26), size: 7, color: Palette.soft);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SiteMapPainter old) => false;
}

// MARK: Floor plan

/// A blueprint-style plan: walls, door swings, stairs and room labels. Not to scale.
class _FloorPlanPainter extends CustomPainter {
  const _FloorPlanPainter(this.plan);

  final PlanKind plan;

  /// Rooms as (label, rect) in a 300 × 200 design.
  List<(String, Rect)> get _rooms => switch (plan) {
    PlanKind.loftGround => const [
      ('LIVING', Rect.fromLTWH(0, 0, 170, 120)),
      ('DINING', Rect.fromLTWH(170, 0, 130, 120)),
      ('KITCHEN', Rect.fromLTWH(110, 120, 190, 80)),
      ('T&B', Rect.fromLTWH(0, 120, 60, 80)),
    ],
    PlanKind.loftUpper => const [
      ('LOFT BEDROOM', Rect.fromLTWH(0, 0, 190, 200)),
      ('OPEN TO BELOW', Rect.fromLTWH(190, 0, 110, 120)),
      ('CLOSET', Rect.fromLTWH(190, 120, 110, 80)),
    ],
    PlanKind.studio => const [
      ('LIVING · SLEEPING', Rect.fromLTWH(0, 0, 200, 200)),
      ('KITCHEN', Rect.fromLTWH(200, 0, 100, 110)),
      ('T&B', Rect.fromLTWH(200, 110, 100, 90)),
    ],
    PlanKind.oneBedroom => const [
      ('LIVING · DINING', Rect.fromLTWH(0, 0, 170, 125)),
      ('BEDROOM', Rect.fromLTWH(170, 0, 130, 125)),
      ('KITCHEN', Rect.fromLTWH(0, 125, 170, 75)),
      ('T&B', Rect.fromLTWH(170, 125, 130, 75)),
    ],
    PlanKind.twoBedroom => const [
      ('LIVING · DINING', Rect.fromLTWH(0, 0, 160, 125)),
      ('BEDROOM 1', Rect.fromLTWH(160, 0, 140, 100)),
      ('BEDROOM 2', Rect.fromLTWH(160, 100, 140, 100)),
      ('KITCHEN', Rect.fromLTWH(0, 125, 95, 75)),
      ('T&B', Rect.fromLTWH(95, 125, 65, 75)),
    ],
    PlanKind.house => const [
      ('LIVING', Rect.fromLTWH(0, 0, 170, 120)),
      ('DINING', Rect.fromLTWH(170, 0, 130, 120)),
      ('KITCHEN', Rect.fromLTWH(110, 120, 190, 80)),
      ('T&B', Rect.fromLTWH(0, 120, 60, 80)),
    ],
  };

  bool get _stairs => plan == PlanKind.loftGround || plan == PlanKind.loftUpper || plan == PlanKind.house;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0C2246));
    _grid(canvas, size, 12, Palette.white(0.035));
    _grid(canvas, size, 60, Palette.white(0.05));
    canvas.save();
    final k = _fit(canvas, size, 340, 250, pad: 10);
    canvas.translate(20, 26);

    final wall = Paint()
      ..color = const Color(0xFFE9EEF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 / math.max(k, 0.8)
      ..strokeJoin = StrokeJoin.miter;
    final inner = Paint()
      ..color = const Color(0xFFE9EEF8).o(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 / math.max(k, 0.8);
    final thin = Paint()
      ..color = Palette.soft.o(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Room fills.
    for (final (i, (_, r)) in _rooms.indexed) {
      canvas.drawRect(r, Paint()..color = (i.isEven ? Palette.blue : Palette.navyLight).o(0.16));
    }
    // Interior walls.
    for (final (_, r) in _rooms) {
      canvas.drawRect(r, inner);
    }
    // Outer shell.
    canvas.drawRect(const Rect.fromLTWH(0, 0, 300, 200), wall);

    // Stairs.
    if (_stairs) {
      const s = Rect.fromLTWH(62, 124, 44, 74);
      canvas.drawRect(s, thin);
      for (var y = s.top + 8; y < s.bottom; y += 8) {
        canvas.drawLine(Offset(s.left, y), Offset(s.right, y), thin);
      }
      final arrow = Paint()
        ..color = Palette.yellow
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(s.center.dx, s.bottom - 6), Offset(s.center.dx, s.top + 8), arrow);
      canvas.drawPath(
        Path()
          ..moveTo(s.center.dx - 4, s.top + 13)
          ..lineTo(s.center.dx, s.top + 7)
          ..lineTo(s.center.dx + 4, s.top + 13),
        arrow,
      );
    }

    // Entry door swing on the front wall.
    final door = Paint()
      ..color = Palette.yellow.o(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    const hinge = Offset(24, 200);
    canvas.drawLine(hinge, hinge + const Offset(0, -30), door);
    canvas.drawArc(Rect.fromCircle(center: hinge, radius: 30), -math.pi / 2, math.pi / 2, false, door);
    canvas.drawLine(
      hinge,
      hinge + const Offset(30, 0),
      Paint()
        ..color = const Color(0xFF0C2246)
        ..strokeWidth = 6,
    );

    // Window marks on the back wall.
    final win = Paint()
      ..color = Palette.submittedText
      ..strokeWidth = 3;
    for (final x in const [40.0, 200.0]) {
      canvas.drawLine(Offset(x, 0), Offset(x + 50, 0), win);
    }

    // Labels.
    for (final (name, r) in _rooms) {
      _label(canvas, name, r.center, size: 9.5, color: Palette.soft, spacing: 1);
    }

    // Dimension line.
    final dim = Paint()
      ..color = Palette.subtle
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(0, -14), const Offset(300, -14), dim);
    canvas.drawLine(const Offset(0, -18), const Offset(0, -10), dim);
    canvas.drawLine(const Offset(300, -18), const Offset(300, -10), dim);
    _label(
      canvas,
      'NOT TO SCALE',
      const Offset(150, -14),
      size: 7.5,
      color: Palette.subtle,
      pill: const Color(0xFF0C2246),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FloorPlanPainter old) => old.plan != plan;
}

// MARK: Nearby destinations

/// A stylised area map: river, highway, the project pin and generic points of interest.
class _NearbyPainter extends CustomPainter {
  const _NearbyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF0A1932));
    canvas.save();
    _fit(canvas, size, 360, 240);

    // Land blocks.
    final block = Paint()..color = Palette.white(0.035);
    for (var y = 0.0; y < 240; y += 34) {
      for (var x = (y ~/ 34).isEven ? 0.0 : 17.0; x < 360; x += 46) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 38, 26), const Radius.circular(4)), block);
      }
    }
    // River.
    final river = Path()
      ..moveTo(-10, 40)
      ..cubicTo(80, 10, 120, 110, 200, 80)
      ..cubicTo(270, 54, 300, 130, 370, 110);
    canvas.drawPath(
      river,
      Paint()
        ..color = Palette.blue.o(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    // Highway and roads.
    final hw = Paint()
      ..color = Palette.yellow.o(0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawPath(
      Path()
        ..moveTo(-10, 200)
        ..cubicTo(100, 180, 220, 210, 370, 160),
      hw,
    );
    final rd = Paint()
      ..color = Palette.white(0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(const Offset(80, 0), const Offset(130, 240), rd);
    canvas.drawLine(const Offset(250, 0), const Offset(230, 240), rd);
    canvas.drawLine(const Offset(0, 140), const Offset(360, 130), rd);

    // Points of interest.
    const pois = [
      ('School', Offset(70, 110), Palette.submittedText),
      ('Market', Offset(300, 70), Palette.todoText),
      ('Church', Offset(150, 40), Palette.soft),
      ('Hospital', Offset(305, 200), Palette.acceptedText),
      ('Terminal', Offset(40, 205), Palette.reviewedText),
    ];
    for (final (name, at, color) in pois) {
      canvas.drawCircle(at, 9, Paint()..color = color.o(0.22));
      canvas.drawCircle(at, 4.5, Paint()..color = color);
      _label(canvas, name, at + const Offset(0, 17), size: 8, color: Palette.text, pill: Palette.deep.o(0.75));
    }

    // Project pin with radius rings.
    const home = Offset(185, 140);
    for (final r in const [62.0, 40.0]) {
      canvas.drawCircle(
        home,
        r,
        Paint()
          ..color = Palette.yellow.o(r > 50 ? 0.22 : 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    canvas.drawCircle(home, 18, Paint()..color = Palette.yellow.o(0.25));
    final pin = Path()
      ..moveTo(home.dx, home.dy + 2)
      ..cubicTo(home.dx - 12, home.dy - 12, home.dx - 11, home.dy - 26, home.dx, home.dy - 26)
      ..cubicTo(home.dx + 11, home.dy - 26, home.dx + 12, home.dy - 12, home.dx, home.dy + 2);
    canvas.drawPath(pin.shift(const Offset(1, 2)), Paint()..color = const Color(0x66000000));
    canvas.drawPath(pin, Paint()..color = Palette.yellow);
    canvas.drawCircle(home - const Offset(0, 15), 4.5, Paint()..color = Palette.ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NearbyPainter old) => false;
}

// MARK: Amenities

/// Dusk scene: clubhouse with an arched roof, pool, playground and trees.
class _AmenitiesPainter extends CustomPainter {
  const _AmenitiesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF16305B), Color(0xFF2E4F8F), Color(0xFFF2A65E)],
          stops: [0, 0.55, 1],
        ).createShader(sky),
    );
    canvas.save();
    _fit(canvas, size, 360, 240);
    // Sun.
    canvas.drawCircle(const Offset(290, 70), 26, Paint()..color = Palette.yellow.o(0.9));
    canvas.drawCircle(
      const Offset(290, 70),
      40,
      Paint()
        ..color = Palette.yellow.o(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // Lawn.
    canvas.drawRect(const Rect.fromLTWH(-200, 160, 760, 200), Paint()..color = const Color(0xFF1F7A4E));
    canvas.drawRect(const Rect.fromLTWH(-200, 160, 760, 6), Paint()..color = const Color(0xFF2FA96B));

    // Clubhouse: arched roof (the Tahanan arch), door and windows.
    const body = Rect.fromLTWH(40, 92, 130, 72);
    canvas.drawRRect(
      RRect.fromRectAndCorners(body, topLeft: const Radius.circular(65), topRight: const Radius.circular(65)),
      Paint()..color = Palette.blue,
    );
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(88, 124, 34, 40),
        topLeft: const Radius.circular(17),
        topRight: const Radius.circular(17),
      ),
      Paint()..color = Palette.orange,
    );
    for (final x in const [56.0, 136.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, 128, 18, 18), const Radius.circular(3)),
        Paint()..color = Palette.yellow.o(0.85),
      );
    }

    // Pool with ripples.
    final pool = RRect.fromRectAndRadius(const Rect.fromLTWH(190, 176, 130, 34), const Radius.circular(17));
    canvas.drawRRect(pool, Paint()..color = const Color(0xFF5BC0F0));
    canvas.drawRRect(
      pool,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    final ripple = Paint()
      ..color = const Color(0xFFFFFFFF).o(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final (x, y) in const [(215.0, 188.0), (255.0, 196.0), (290.0, 186.0)]) {
      canvas.drawArc(Rect.fromLTWH(x, y, 16, 8), math.pi, math.pi, false, ripple);
    }

    // Playground slide.
    final frame = Paint()
      ..color = Palette.yellow
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(30, 210), const Offset(30, 176), frame);
    canvas.drawLine(const Offset(48, 210), const Offset(48, 176), frame);
    canvas.drawLine(const Offset(30, 176), const Offset(48, 176), frame);
    canvas.drawLine(
      const Offset(48, 178),
      const Offset(84, 210),
      Paint()
        ..color = Palette.orange
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    for (final (x, y, r) in const [
      (16.0, 150.0, 14.0),
      (190.0, 146.0, 16.0),
      (226.0, 152.0, 11.0),
      (338.0, 150.0, 15.0),
      (120.0, 214.0, 10.0),
    ]) {
      canvas.drawLine(
        Offset(x, y + r * 0.5),
        Offset(x, y + r + 10),
        Paint()
          ..color = const Color(0xFF5B3A1E)
          ..strokeWidth = 3,
      );
      _tree(canvas, Offset(x, y), r);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AmenitiesPainter old) => false;
}
