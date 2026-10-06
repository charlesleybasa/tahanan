import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

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
  const PulseRing({super.key, required this.color, this.lineWidth = 2, this.to = 1.55});

  final Color color;
  final double lineWidth;
  final double to;

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
                  shape: BoxShape.circle,
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
