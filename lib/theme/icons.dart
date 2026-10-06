import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

/// The prototype's 44 line icons: 24 × 24 viewBox, 1.8 stroke, round caps and joins (`play` is filled).
/// Path data is copied verbatim from the native Icons.swift. Spec §5.
enum TIcon {
  check(['M5 12.5 10 17 19 7']),
  family([
    'M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z',
    'M2 21a7 7 0 0 1 14 0',
    'M16 3.5a4 4 0 0 1 0 7.5',
    'M18 14a7 7 0 0 1 4 6.5',
  ]),
  home(['M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z']),
  arrowRight(['M5 12h14', 'm13 6 6 6-6 6']),
  arrowUpRight(['M7 17 17 7', 'M8 7h9v9']),
  eye(['M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z', 'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z']),
  fingerprint([
    'M12 11v3a8 8 0 0 1-1.5 4.7',
    'M8.5 7.5A5 5 0 0 1 17 11v2a12 12 0 0 1-.6 3.8',
    'M7 11a5 5 0 0 1 .3-1.7',
    'M7 14a11 11 0 0 1-1 4',
    'M4.5 6.5A9 9 0 0 1 21 11v1',
    'M3 11a9 9 0 0 1 .5-3',
  ]),
  arrowLeft(['M19 12H5', 'm11 6-6 6 6 6']),
  lock(['M6 11h12a1 1 0 0 1 1 1v8a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-8a1 1 0 0 1 1-1z', 'M8 11V7a4 4 0 0 1 8 0v4']),
  send(['M4 12 20 4l-6 16-3-7z', 'm11 13 9-9']),
  mail(['M4 5h16a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z', 'm3 7 9 6 9-6']),
  external(['M14 4h6v6', 'm20 4-9 9', 'M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5']),
  shield(['M12 3 4 6v6c0 5 3.5 8 8 9 4.5-1 8-4 8-9V6z', 'm9 12 2 2 4-4']),
  bell(['M6 8a6 6 0 1 1 12 0c0 7 3 9 3 9H3s3-2 3-9', 'M10.3 21a1.94 1.94 0 0 0 3.4 0']),
  pin(['M12 21s7-6.2 7-12a7 7 0 0 0-14 0c0 5.8 7 12 7 12z', 'M12 11.5a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5z']),
  link(['M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1', 'M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1']),
  chevronRight(['m9 6 6 6-6 6']),
  wallet(['M4 6h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H5a1 1 0 0 1-1-1z', 'M4 6a2 2 0 0 1 2-2h10v2', 'M16 13h.01']),
  calendar(['M4 6h16v14H4z', 'M4 10h16M8 3v4M16 3v4']),
  heart(['M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z']),
  play(['M7 4.5v15l13-7.5z']),
  close(['M6 6l12 12M18 6 6 18']),
  grid(['M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z']),
  scan(['M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3', 'M4 12h16']),
  help([
    'M21 12a8 8 0 0 1-11.6 7.1L4 20l1-4.6A8 8 0 1 1 21 12z',
    'M9.5 9.5a2.5 2.5 0 0 1 4.9.7c0 1.6-2.4 2-2.4 3.3',
    'M12 16.5h.01',
  ]),
  image(['M4 4h16v16H4z', 'm4 16 5-5 4 4 2-2 5 5', 'M15.5 9.5h.01']),
  bolt(['M13 2 4 14h7l-1 8 9-12h-7z']),
  card(['M3 6h18v12H3z', 'M3 10h18M7 15h3']),
  bank(['M3 10 12 4l9 6', 'M5 10v8M9.5 10v8M14.5 10v8M19 10v8M3 20h18']),
  store(['M4 9l1.5-5h13L20 9', 'M4 9v11h16V9', 'M4 9h16', 'M10 20v-5h4v5']),
  chevronDown(['m6 9 6 6 6-6']),
  document(['M14 3H7a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V8z', 'M14 3v5h5', 'M9 13h6M9 17h4']),
  upload(['M12 16V4', 'm7 9 5-5 5 5', 'M4 16v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3']),
  settings([
    'M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
    'M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z',
  ]),
  camera([
    'M4 7h3l2-3h6l2 3h3a1 1 0 0 1 1 1v11a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V8a1 1 0 0 1 1-1z',
    'M12 17a4 4 0 1 0 0-8 4 4 0 0 0 0 8z',
  ]),
  phone(['M7 2h10a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1z', 'M11 18h2']),
  person(['M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8z', 'M4 21a8 8 0 0 1 16 0']),
  logout(['M15 4h3a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-3', 'm10 16-4-4 4-4', 'M6 12h10']),
  search(['M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14z', 'm20 20-3.5-3.5']),
  plus(['M12 5v14M5 12h14']),
  paperclip(['m21 11-8.5 8.5a5 5 0 0 1-7-7L14 4a3.5 3.5 0 0 1 5 5l-8.5 8.5a2 2 0 0 1-3-3L15 7']),
  replay(['M20 11a8 8 0 1 0-2.3 5.7', 'M20 4v7h-7']),
  info(['M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z', 'M12 11v5M12 8h.01']),
  edit(['M4 20h4L19 9l-4-4L4 16z', 'm13.5 6.5 4 4']);

  const TIcon(this.paths);

  final List<String> paths;

  bool get filled => this == TIcon.play;

  static final _cache = <TIcon, Path>{};

  /// Parsed once, in 24 × 24 space.
  Path get path => _cache.putIfAbsent(this, () {
    final p = Path();
    for (final d in paths) {
      p.addPath(parseSvgPathData(d), Offset.zero);
    }
    return p;
  });
}

/// An icon at a given CSS pixel size; the stroke scales with it like the SVG would.
/// Color comes from [color] or the ambient [DefaultTextStyle] / [IconTheme] color (SVG `currentColor`).
class TIconView extends StatelessWidget {
  const TIconView(this.icon, {super.key, this.size = 20, this.color});

  final TIcon icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c =
        color ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFFFFFFFF);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _IconPainter(icon, c)),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color);

  final TIcon icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 24;
    canvas.scale(s);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    if (icon.filled) {
      paint.style = PaintingStyle.fill;
    } else {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
    }
    canvas.drawPath(icon.path, paint);
  }

  @override
  bool shouldRepaint(_IconPainter old) => old.icon != icon || old.color != color;
}
