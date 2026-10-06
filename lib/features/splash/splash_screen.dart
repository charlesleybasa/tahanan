import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/itext.dart';

/// 4.4 s splash, timed from the `.sp-*` keyframes: dawn rises, arch rings expand, the logo assembles,
/// "Tahanan" rises letter by letter, the byline tracks in, then everything blurs and scales out into onboarding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _next;

  @override
  void initState() {
    super.initState();
    _next = Timer(const Duration(milliseconds: 4400), () {
      if (mounted) context.go(const Screen(ScreenKind.onboarding));
    });
  }

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tahanan by Raemulan Lands',
      excludeSemantics: true,
      child: ColoredBox(
        color: Palette.splash,
        child: Timeline(builder: (_, t) => _content(t)),
      ),
    );
  }

  Widget _content(double t) {
    // .sp-out: 0.85 s cubic-bezier(.6,0,.4,1) at 3.55 s
    final out = keyframe(t, delay: 3.55, duration: 0.85, curve: const Cubic(0.6, 0, 0.4, 1));
    return DesignCanvas(
      children: [
        const Positioned.fill(child: ColoredBox(color: Palette.splash)),
        Positioned.fill(
          child: Opacity(
            opacity: (1 - out).clamp(0, 1),
            child: Transform.scale(
              scale: mix(1, 1.12, out),
              child: blurred(
                14 * out,
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _dawn(t),
                    _ring(t, top: 250, w: 300, h: 400, color: Palette.white(0.22), delay: 0.2),
                    _ring(t, top: 170, w: 460, h: 560, color: Palette.yellow.o(0.3), delay: 0.55),
                    _ring(t, top: 90, w: 640, h: 760, color: Palette.white(0.14), delay: 0.9),
                    Positioned(left: 120, top: 300, child: MarkIntro(width: 150, t: t)),
                    Positioned(left: 0, top: 300 + 144.23 + 30, width: 390, child: _wordmark(t)),
                    Positioned(
                      left: 0,
                      top: 844 - 70 - 19,
                      width: 390,
                      child: Opacity(
                        opacity: keyframe(t, delay: 2.7, duration: 1, curve: Motion.ease),
                        child: IText(
                          'One arch is a roofline. Together, they make a family.',
                          textAlign: TextAlign.center,
                          style: Typo.manrope(14, Typo.regular, Palette.subtle),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// .sp-dawn: 2.8 s from .5 s, opacity 0 → 1 and translateY 35% → 0.
  Widget _dawn(double t) {
    final p = keyframe(t, delay: 0.5, duration: 2.8);
    const w = 390 * 1.8, h = 844 * 0.75;
    return Positioned(
      left: -390 * 0.4,
      top: 844 + 844 * 0.3 - h + h * 0.35 * (1 - p),
      width: w,
      height: h,
      child: Opacity(
        opacity: p,
        child: ClipPath(
          clipper: const _EllipticTop(),
          child: CssRadialGradient(
            rx: 0.5,
            ry: 0.5,
            cx: 0.5,
            cy: 0.5,
            colors: [Palette.blue.o(0.55), Palette.blue.o(0.12), Palette.blue.o(0)],
            stops: const [0, 0.55, 0.75],
          ),
        ),
      ),
    );
  }

  /// .sp-ring: 3.4 s ringOut — scale .15 → 1, opacity 0 → .7 (25%) → 0.
  Widget _ring(
    double t, {
    required double top,
    required double w,
    required double h,
    required Color color,
    required double delay,
  }) {
    const c = Motion.standard;
    final raw = ((t - delay) / 3.4).clamp(0.0, 1.0);
    final opacity = raw < 0.25 ? mix(0, 0.7, c.transform(raw / 0.25)) : mix(0.7, 0, c.transform((raw - 0.25) / 0.75));
    return Positioned(
      left: 195 - w / 2,
      top: top,
      width: w,
      height: h,
      child: Opacity(
        opacity: t < delay ? 0 : opacity.clamp(0, 1),
        child: Transform.scale(
          scale: mix(0.15, 1, c.transform(raw)),
          child: ArchOutline(color: color),
        ),
      ),
    );
  }

  /// "Tahanan" letters (letterA .85 s, 60 ms stagger from 1.7 s) and the tracked byline (trackA 1.5 s from 2.2 s).
  Widget _wordmark(double t) {
    final track = keyframe(t, delay: 2.2, duration: 1.5);
    const letters = 'Tahanan';
    final style = Typo.outfit(54, Typo.bold, const Color(0xFFFFFFFF));
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < letters.length; i++)
              Builder(
                builder: (_) {
                  final p = keyframe(t, delay: 1.7 + i * 0.06, duration: 0.85);
                  return Transform.translate(
                    // HStack(spacing: -0.035 × 54), kept centred.
                    offset: Offset(-0.035 * 54 * (i - (letters.length - 1) / 2), 0),
                    child: Opacity(
                      opacity: p.clamp(0, 1),
                      child: Transform.translate(
                        offset: Offset(0, 46 * (1 - p)),
                        child: Transform.rotate(
                          angle: 8 * (1 - p) * math.pi / 180,
                          child: blurred(10 * (1 - p), Text(letters[i], style: style)),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        Opacity(
          opacity: track,
          child: Text(
            'BY RAEMULAN LANDS',
            softWrap: false,
            overflow: TextOverflow.visible,
            style: Typo.manrope(12, Typo.extrabold, Palette.muted).copyWith(letterSpacing: mix(12, 0.34 * 12, track)),
          ),
        ),
      ],
    );
  }
}

/// border-radius: 50% 50% 0 0 — elliptical top corners spanning the full width and half the height.
class _EllipticTop extends CustomClipper<Path> {
  const _EllipticTop();

  @override
  Path getClip(Size size) => Path()
    ..addRRect(
      RRect.fromRectAndCorners(
        Offset.zero & size,
        topLeft: Radius.elliptical(size.width / 2, size.height / 2),
        topRight: Radius.elliptical(size.width / 2, size.height / 2),
      ),
    );

  @override
  bool shouldReclip(_EllipticTop old) => false;
}
