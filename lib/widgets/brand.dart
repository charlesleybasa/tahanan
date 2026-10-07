import 'package:flutter/widgets.dart';

import '../theme/theme.dart';

/// The Tahanan logo on the design's 104 × 100 grid:
/// sun (50,0) 54², roof (0,18) 70×82 r35/5, door (22,62) 26×38 r13, bush (81,77) 19×23 r9.5/3.
class TahananMark extends StatelessWidget {
  const TahananMark({super.key, required this.width, this.sunGlow, this.sunGlowRadius = 0});

  final double width;
  final Color? sunGlow;
  final double sunGlowRadius;

  @override
  Widget build(BuildContext context) {
    final k = width / 104;
    Widget at(double x, double y, double w, double h, Decoration d) => Positioned(
      left: x * k,
      top: y * k,
      width: w * k,
      height: h * k,
      child: DecoratedBox(decoration: d),
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: width,
        height: 100 * k,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            at(
              50,
              0,
              54,
              54,
              BoxDecoration(
                color: Palette.yellow,
                shape: BoxShape.circle,
                boxShadow: sunGlow == null ? null : [BoxShadow(color: sunGlow!, blurRadius: sunGlowRadius)],
              ),
            ),
            at(
              0,
              18,
              70,
              82,
              BoxDecoration(gradient: Palette.roofGradient, borderRadius: cornerBox(35 * k, 35 * k, 5 * k, 5 * k)),
            ),
            at(22, 62, 26, 38, BoxDecoration(color: Palette.orange, borderRadius: cornerBox(13 * k, 13 * k, 0, 0))),
            at(
              81,
              77,
              19,
              23,
              BoxDecoration(color: Palette.green, borderRadius: cornerBox(9.5 * k, 9.5 * k, 3 * k, 3 * k)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mark + "Tahanan" wordmark (30 mark, Outfit 700 20, -0.02em).
class TahananLockup extends StatelessWidget {
  const TahananLockup({super.key, this.markWidth = 30, this.fontSize = 20});

  final double markWidth, fontSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tahanan',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TahananMark(width: markWidth),
          const SizedBox(width: 10),
          Text(
            'Tahanan',
            style: Typo.outfit(fontSize, Typo.bold, Palette.text).copyWith(letterSpacing: -0.02 * fontSize),
          ),
        ],
      ),
    );
  }
}

/// A photo filling its frame (object-fit: cover), optionally with Ken Burns. [name] is a bundled image
/// (`assets/images/<name>.jpg`) or an absolute `http(s)` URL from the API.
class Photo extends StatelessWidget {
  const Photo(this.name, {super.key, this.kenBurns = false, this.kbDuration = 16});

  final String name;
  final bool kenBurns;
  final double kbDuration;

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty) return const ColoredBox(color: Palette.panel);
    final img = Image(
      image: photoProvider(name),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
    return ClipRect(
      child: kenBurns ? KenBurns(duration: kbDuration, child: img) : img,
    );
  }
}

/// Bundled asset name or network URL → image provider.
ImageProvider photoProvider(String name) =>
    name.startsWith('http') ? NetworkImage(name) : AssetImage('assets/images/$name.jpg') as ImageProvider;
