import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

import 'colors.dart';

/// CSS cubic-bezier easings and timings from the prototype. Spec §4.
abstract final class Motion {
  /// cubic-bezier(.2,.8,.2,1): screen enter, rise, toast.
  static const standard = Cubic(0.2, 0.8, 0.2, 1);

  /// cubic-bezier(.2,.9,.2,1): bottom sheet.
  static const sheet = Cubic(0.2, 0.9, 0.2, 1);

  /// cubic-bezier(.2,.9,.3,1.35): pop (overshoots).
  static const pop = Cubic(0.2, 0.9, 0.3, 1.35);

  /// cubic-bezier(.77,0,.175,1): onboarding morph.
  static const morph = Cubic(0.77, 0, 0.175, 1);

  /// cubic-bezier(.4,0,.2,1): journey progress fill.
  static const upbar = Cubic(0.4, 0, 0.2, 1);

  static const easeInOut = Cubic(0.42, 0, 0.58, 1);
  static const ease = Cubic(0.25, 0.1, 0.25, 1);
  static const easeOut = Cubic(0, 0, 0.58, 1);

  static const screen = Duration(milliseconds: 750);
  static const tabSwitch = Duration(milliseconds: 180);

  /// `.d1`–`.d8` stagger delays.
  static const stagger = [0.0, 0.07, 0.14, 0.21, 0.28, 0.36, 0.44, 0.52, 0.6];
}

double mix(double a, double b, double t) => a + (b - a) * t;

Duration seconds(double s) => Duration(microseconds: (s * 1e6).round());

/// When true, `.rise` content is shown in place (tab switches).
class SkipEntrance extends InheritedWidget {
  const SkipEntrance({super.key, required this.skip, required super.child});

  final bool skip;

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SkipEntrance>()?.skip ?? false;

  @override
  bool updateShouldNotify(SkipEntrance oldWidget) => skip != oldWidget.skip;
}

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Applies a Gaussian blur equal to CSS `filter: blur(r)` (σ = r).
Widget blurred(double radius, Widget child) {
  if (radius < 0.01) return child;
  return ImageFiltered(
    imageFilter: ImageFilter.blur(sigmaX: radius, sigmaY: radius, tileMode: TileMode.decal),
    child: child,
  );
}

/// `.rise`: translateY 26 + blur 6 → 0 with opacity, 0.85 s standard, staggered via `.d1`–`.d8`.
class Rise extends StatefulWidget {
  const Rise({super.key, this.step = 0, this.delay, this.distance = 26, this.blur = 6, required this.child});

  final int step;
  final double? delay;
  final double distance;
  final double blur;
  final Widget child;

  @override
  State<Rise> createState() => _RiseState();
}

class _RiseState extends State<Rise> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
  late final _t = CurvedAnimation(parent: _c, curve: Motion.standard);
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.status != AnimationStatus.dismissed || _timer != null) return;
    if (SkipEntrance.of(context)) {
      _c.value = 1;
      return;
    }
    final d = widget.delay ?? Motion.stagger[widget.step.clamp(0, 8)];
    _timer = Timer(seconds(d), () {
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
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) {
        final p = _t.value;
        return Opacity(
          opacity: p.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, still ? 0 : widget.distance * (1 - p)),
            child: blurred(still ? 0 : widget.blur * (1 - p), child!),
          ),
        );
      },
    );
  }
}

extension RiseX on Widget {
  /// `rise(3)` = `.rise.d3`.
  Widget rise([int step = 0]) => Rise(step: step, child: this);
}

/// Ken Burns: scale 1.06 → 1.22 at (0.6, 0.4) plus translate -2% × scale, 16 s ease-in-out, alternating.
class KenBurns extends StatefulWidget {
  const KenBurns({super.key, this.duration = 16, this.to = 1.22, required this.child});

  final double duration;
  final double to;
  final Widget child;

  @override
  State<KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<KenBurns> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: seconds(widget.duration));
  late final _t = CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion(context) && !_c.isAnimating) _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => AnimatedBuilder(
        animation: _t,
        child: widget.child,
        builder: (context, child) {
          final p = _t.value;
          final s = mix(1.06, widget.to, p);
          return Transform.translate(
            offset: Offset(-0.02 * box.maxWidth * widget.to * p, -0.02 * box.maxHeight * widget.to * p),
            child: Transform.scale(scale: s, alignment: const Alignment(0.2, -0.2), child: child),
          );
        },
      ),
    );
  }
}

/// `.ring`: scale .92 → 1.55 while fading .8 → 0, 2.2 s ease-out, looping.
class PulseRing extends StatefulWidget {
  const PulseRing({super.key, required this.color, this.lineWidth = 2, this.to = 1.55, this.cornerRadius});

  final Color color;
  final double lineWidth;
  final double to;
  final double? cornerRadius;

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final p = Motion.easeOut.transform(_c.value);
          return Opacity(
            opacity: mix(0.8, 0, p),
            child: Transform.scale(
              scale: mix(0.92, widget.to, p),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: widget.cornerRadius == null ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: widget.cornerRadius == null ? null : BorderRadius.circular(widget.cornerRadius!),
                  border: Border.all(color: widget.color, width: widget.lineWidth),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// `.press:active{transform:scale(.97)}` with 0.15 s ease-out.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.onTap, required this.child, this.semanticLabel, this.scale = 0.97});

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: widget.semanticLabel != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

/// A plain tap target with no visual feedback (SwiftUI `.buttonStyle(.plain)`).
class Tap extends StatelessWidget {
  const Tap({super.key, required this.onTap, required this.child, this.semanticLabel, this.selected});

  final VoidCallback? onTap;
  final Widget child;
  final String? semanticLabel;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      selected: selected,
      excludeSemantics: semanticLabel != null,
      child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child),
    );
  }
}

/// Runs a one-shot 0 → 1 animation after [delay], exposing progress to [builder].
class _Once extends StatefulWidget {
  const _Once({required this.duration, required this.delay, required this.curve, required this.builder, this.child});

  final Duration duration;
  final double delay;
  final Curve curve;
  final Widget Function(BuildContext, double, Widget?) builder;
  final Widget? child;

  @override
  State<_Once> createState() => _OnceState();
}

class _OnceState extends State<_Once> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.duration);
  late final _t = CurvedAnimation(parent: _c, curve: widget.curve);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay <= 0) {
      _c.forward();
    } else {
      _timer = Timer(seconds(widget.delay), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _t, child: widget.child, builder: (c, child) => widget.builder(c, _t.value, child));
}

/// Fade in, 0.4 s ease-in-out by default.
class FadeIn extends StatelessWidget {
  const FadeIn({super.key, this.duration = 0.4, this.delay = 0, required this.child});

  final double duration, delay;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Once(
    duration: seconds(duration),
    delay: delay,
    curve: Motion.easeInOut,
    child: child,
    builder: (_, p, c) => Opacity(opacity: p.clamp(0, 1), child: c),
  );
}

/// `.pop`: scale 0 → 1 with opacity, cubic-bezier(.2,.9,.3,1.35), 0.7 s.
class Pop extends StatelessWidget {
  const Pop({super.key, this.delay = 0, this.duration = 0.7, required this.child});

  final double delay, duration;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Once(
    duration: seconds(duration),
    delay: delay,
    curve: Motion.pop,
    child: child,
    builder: (_, p, c) => Opacity(
      opacity: p.clamp(0, 1),
      child: Transform.scale(scale: p < 0.001 ? 0.001 : p, child: c),
    ),
  );
}

/// In-screen panel entrance: slide up 400 → 0, 0.55 s sheet curve.
class SheetUp extends StatelessWidget {
  const SheetUp({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => _Once(
    duration: const Duration(milliseconds: 550),
    delay: 0,
    curve: Motion.sheet,
    child: child,
    builder: (_, p, c) => Transform.translate(offset: Offset(0, 400 * (1 - p)), child: c),
  );
}

extension MotionX on Widget {
  Widget fadeIn([double duration = 0.4, double delay = 0]) => FadeIn(duration: duration, delay: delay, child: this);
  Widget pop([double delay = 0]) => Pop(delay: delay, child: this);
  Widget riseAt(double delay) => Rise(delay: delay, child: this);
}

/// A repeating 0 → 1 clock for ambient loops; [reverse] ping-pongs like CSS `alternate`.
class Loop extends StatefulWidget {
  const Loop({
    super.key,
    required this.period,
    this.reverse = false,
    this.curve = Curves.linear,
    required this.builder,
    this.child,
  });

  final double period;
  final bool reverse;
  final Curve curve;
  final Widget Function(BuildContext, double, Widget?) builder;
  final Widget? child;

  @override
  State<Loop> createState() => _LoopState();
}

class _LoopState extends State<Loop> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: seconds(widget.period))..repeat(reverse: widget.reverse);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (c, child) => widget.builder(c, widget.curve.transform(_c.value), child),
  );
}

/// `.glow`: opacity .75 ↔ 1 and scale 1 ↔ 1.08 over 2.5 s each way.
class GlowPulse extends StatelessWidget {
  const GlowPulse({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Loop(
    period: 2.5,
    reverse: true,
    curve: Curves.easeInOut,
    child: child,
    builder: (_, p, c) => Opacity(
      opacity: mix(0.75, 1, p),
      child: Transform.scale(scale: mix(1, 1.08, p), child: c),
    ),
  );
}

/// `.float`: translateY 0 → -12 → 0 with ease-in-out per half; [phase] offsets the cycle.
class Floating extends StatelessWidget {
  const Floating({super.key, this.period = 6, this.phase = 0, this.amplitude = 12, required this.child});

  final double period, phase, amplitude;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Clock(
    child: child,
    builder: (_, t, c) {
      final p = ((t + phase) % period) / period;
      final half = p < 0.5 ? p * 2 : (1 - p) * 2;
      return Transform.translate(offset: Offset(0, -amplitude * Motion.easeInOut.transform(half)), child: c);
    },
  );
}

/// Wall-clock seconds, for loops whose phase must not reset (SwiftUI `TimelineView`).
class _Clock extends StatefulWidget {
  const _Clock({required this.builder, this.child});

  final Widget Function(BuildContext, double, Widget?) builder;
  final Widget? child;

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(days: 1))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (c, child) => widget.builder(c, DateTime.now().microsecondsSinceEpoch / 1e6, child),
  );
}

/// Seconds since this widget was first built, rebuilt every frame (for timeline-driven screens).
class Timeline extends StatefulWidget {
  const Timeline({super.key, required this.builder});

  final Widget Function(BuildContext context, double t) builder;

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(days: 1))..forward();
  final _start = DateTime.now();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (c, _) => widget.builder(c, DateTime.now().difference(_start).inMicroseconds / 1e6),
  );
}

/// Progress of a CSS animation with `both` fill mode at elapsed time [t].
double keyframe(double t, {required double delay, required double duration, Curve curve = Motion.standard}) =>
    curve.transform(((t - delay) / duration).clamp(0.0, 1.0));

/// `.spin`: 0.9 s linear rotation; the head is the top quarter of the ring.
class Spinner extends StatelessWidget {
  const Spinner({super.key, required this.size, required this.lineWidth, this.head = Palette.yellow});

  final double size, lineWidth;
  final Color head;

  @override
  Widget build(BuildContext context) => Loop(
    period: 0.9,
    builder: (_, p, _) => Transform.rotate(
      angle: p * 6.283185307179586,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _SpinnerPainter(lineWidth, head)),
      ),
    ),
  );
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter(this.w, this.head);

  final double w;
  final Color head;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(w / 2);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w;
    canvas.drawOval(rect, p..color = Palette.white(0.15));
    // trim(.625 … .875) of a circle starting at 3 o'clock = the top quarter.
    canvas.drawArc(rect, 6.283185307179586 * 0.625, 6.283185307179586 * 0.25, false, p..color = head);
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) => false;
}

/// `.caret`: 2 × [height] yellow bar blinking every 0.5 s.
class BlinkingCaret extends StatelessWidget {
  const BlinkingCaret({super.key, this.height = 26});

  final double height;

  @override
  Widget build(BuildContext context) => _Clock(
    builder: (_, t, _) => Opacity(
      opacity: (t * 2).floor().isEven ? 1 : 0,
      child: SizedBox(
        width: 2,
        height: height,
        child: const ColoredBox(color: Palette.yellow),
      ),
    ),
  );
}

/// `.scanline`: travels between [from] and [to] of the parent height over 2.4 s ease-in-out.
class ScanLine extends StatelessWidget {
  const ScanLine({super.key, this.from = 0.08, this.to = 0.88, this.inset = 18, this.thickness = 3, this.glow = 22});

  final double from, to, inset, thickness, glow;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, box) => _Clock(
        builder: (_, t, _) {
          final p = (t % 2.4) / 2.4;
          final half = p < 0.5 ? p * 2 : (1 - p) * 2;
          final y = box.maxHeight * mix(from, to, Motion.easeInOut.transform(half));
          return Stack(
            children: [
              Positioned(
                left: inset,
                right: inset,
                top: y - thickness / 2,
                height: thickness,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Palette.yellow,
                    borderRadius: BorderRadius.circular(thickness),
                    boxShadow: [
                      BoxShadow(color: Palette.yellow.o(0.65), blurRadius: glow / 2),
                      BoxShadow(color: Palette.yellow.o(0.4), blurRadius: glow / 4),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// `.cornerP`: scale 1 → .96 → 1 over 2.4 s.
class Breathing extends StatelessWidget {
  const Breathing({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Loop(
    period: 1.2,
    reverse: true,
    curve: Curves.easeInOut,
    child: child,
    builder: (_, p, c) => Transform.scale(scale: mix(1, 0.96, p), child: c),
  );
}
