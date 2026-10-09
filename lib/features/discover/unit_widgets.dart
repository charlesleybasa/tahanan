import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../models/models.dart';
import '../../theme/theme.dart';
import '../../widgets/brand.dart';

/// Light entrance used across the brand and unit pages: fade + 18 pt rise, 0.5 s, no blur (blur is the expensive
/// part of `.rise`), staggered by [delay] seconds. Skipped for revisits and when the OS asks for reduced motion.
class Reveal extends StatefulWidget {
  const Reveal({super.key, this.delay = 0, this.dy = 18, required this.child});

  final double delay, dy;
  final Widget child;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final _t = CurvedAnimation(parent: _c, curve: Motion.standard);
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (SkipEntrance.of(context) || reduceMotion(context)) {
      _c.value = 1;
      return;
    }
    _timer = Timer(seconds(widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: _t.value.clamp(0.0, 1.0),
      child: Transform.translate(offset: Offset(0, widget.dy * (1 - _t.value)), child: child),
    ),
  );
}

/// Duration for one-shot intro animations: instant when the entrance is skipped.
Duration introDuration(BuildContext context, int ms) =>
    SkipEntrance.of(context) || reduceMotion(context) ? Duration.zero : Duration(milliseconds: ms);

/// Counts a price up from 0 once the page enters.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.builder, this.delay = 0.2});

  final num value;
  final double delay;
  final Widget Function(String formatted) builder;

  @override
  Widget build(BuildContext context) {
    final d = introDuration(context, 900);
    return _Delayed(
      delay: d == Duration.zero ? 0 : delay,
      child: (go) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: go ? value.toDouble() : 0),
        duration: d,
        curve: Motion.standard,
        builder: (_, v, _) => builder(peso(go ? v.roundToDouble() : value)),
      ),
    );
  }
}

/// Starts its child's animation [delay] seconds after mount.
class _Delayed extends StatefulWidget {
  const _Delayed({required this.delay, required this.child});

  final double delay;
  final Widget Function(bool go) child;

  @override
  State<_Delayed> createState() => _DelayedState();
}

class _DelayedState extends State<_Delayed> {
  late bool _go = widget.delay == 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!_go) {
      _timer = Timer(seconds(widget.delay), () {
        if (mounted) setState(() => _go = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child(_go);
}

/// The brand arch: a tall arch-shaped photo that opens up on entry (scale + fade) while the picture settles from a
/// slight zoom. [children] sit inside the arch (labels, pagers); [badge] floats over its top-right edge.
class ArchHero extends StatelessWidget {
  const ArchHero({super.key, required this.image, this.height = 440, this.children = const [], this.badge});

  final String image;
  final double height;
  final List<Widget> children;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    const shape = ArchBorder(bottomRadius: 30);
    final dur = introDuration(context, 900);
    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: dur,
              curve: Motion.standard,
              builder: (_, t, child) => Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Transform.scale(scale: mix(0.93, 1, t), alignment: Alignment.bottomCenter, child: child),
              ),
              child: Container(
                foregroundDecoration: ShapeDecoration(
                  shape: shape.copyWith(side: BorderSide(color: Palette.white(0.14))),
                ),
                child: ClipPath(
                  clipper: const ShapeBorderClipper(shape: shape),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.14, end: 1),
                        duration: dur * 1.4,
                        curve: Motion.standard,
                        builder: (_, s, child) => Transform.scale(scale: s, child: child),
                        child: Photo(image),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Palette.night.o(0), Palette.night.o(0.88)],
                            stops: const [0.55, 1],
                          ),
                        ),
                      ),
                      ...children,
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (badge != null) Positioned(right: -6, top: 18, child: badge!),
        ],
      ),
    );
  }
}

/// Yellow "sun" from the logo carrying the starting price. Pops in after the arch opens.
class SunBadge extends StatelessWidget {
  const SunBadge({super.key, required this.label, required this.value});

  final String label, value;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      width: 108,
      height: 108,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Palette.yellow,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Palette.yellow.o(0.5), blurRadius: 36, offset: const Offset(0, 16), spreadRadius: -10),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Typo.manrope(10, Typo.extrabold, Palette.ink).copyWith(letterSpacing: 1.4)),
          const SizedBox(height: 2),
          Text(value, style: Typo.outfit(24, Typo.bold, Palette.ink).copyWith(letterSpacing: -0.8)),
        ],
      ),
    );
    return SkipEntrance.of(context) ? badge : badge.pop(0.35);
  }
}

/// Large outlined numeral (01, 02 …) for the unit ladder.
class OutlineNumber extends StatelessWidget {
  const OutlineNumber(this.n, {super.key});

  final int n;

  @override
  Widget build(BuildContext context) => Text(
    n.toString().padLeft(2, '0'),
    style: TextStyle(
      fontFamily: 'Outfit',
      fontSize: 44,
      fontWeight: Typo.semibold,
      height: 1,
      letterSpacing: -1,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Palette.white(0.3),
    ),
  );
}

/// Quiet facts row: big value over a small caps label, hairlines between columns and above/below.
class FactsStrip extends StatelessWidget {
  const FactsStrip(this.facts, {super.key, this.size = 24});

  final List<(String value, String label)> facts;
  final double size;

  @override
  Widget build(BuildContext context) {
    final line = BorderSide(color: Palette.white(0.1));
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(top: line, bottom: line),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, f) in facts.indexed)
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 16),
                  decoration: BoxDecoration(border: i == 0 ? null : Border(left: line)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          f.$1,
                          maxLines: 1,
                          style: Typo.outfit(size, Typo.semibold, Palette.text).copyWith(letterSpacing: -0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.$2.toUpperCase(),
                        style: Typo.manrope(11, Typo.bold, Palette.subtle).copyWith(letterSpacing: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Receipt line with a dotted leader between label and value.
class ReceiptRow extends StatelessWidget {
  const ReceiptRow(this.label, this.value, {super.key, this.valueColor = Palette.text, this.strong = false});

  final String label, value;
  final Color valueColor;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // The label wraps on narrow phones; the leader keeps at least a short run of dots.
        Flexible(
          flex: 4,
          child: Text(
            label,
            style: Typo.manrope(14, strong ? Typo.extrabold : Typo.semibold, strong ? Palette.text : Palette.soft),
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: 5),
            child: SizedBox(height: 1, child: CustomPaint(painter: _DotLeader())),
          ),
        ),
        const SizedBox(width: 8),
        Text(value, style: strong ? Typo.outfit(20, Typo.bold, valueColor) : Typo.manrope(15, Typo.bold, valueColor)),
      ],
    ),
  );
}

class _DotLeader extends CustomPainter {
  const _DotLeader();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Palette.white(0.22);
    for (var x = 0.0; x < size.width; x += 5) {
      canvas.drawCircle(Offset(x + 1, 0), 0.8, p);
    }
  }

  @override
  bool shouldRepaint(_DotLeader old) => false;
}
