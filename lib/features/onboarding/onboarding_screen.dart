import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../theme/theme.dart';
import '../../widgets/art.dart';
import '../../widgets/brand.dart';
import '../../widgets/buttons.dart';
import '../../widgets/surfaces.dart';
import '../project/project_screens.dart' show adjusted;
import 'onboarding_geometry.dart';
import '../../widgets/itext.dart';

double _now() => DateTime.now().microsecondsSinceEpoch / 1e6;

/// The cinematic morphing onboarding: the five logo shapes persist across intro → discover → scan → track → ready
/// and transition between the `GEO` layouts. Everything is driven from one timeline so each property follows its
/// CSS transition exactly, including interruptions (a new transition starts from the current in-flight value).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  /// null = the "boot" layout shown for 160 ms before intro.
  OnboardingScene? _scene;
  double _changedAt = _now();
  Geo _from = OnboardingGeometry.boot;
  Geo _to = OnboardingGeometry.boot;
  Map<Layer, double> _layerFrom = {};
  Blobs _blobFrom = OnboardingGeometry.blobs(null);
  double _blobOpacityFrom = 0;
  Timer? _auto;
  late final _ticker = AnimationController(vsync: this, duration: const Duration(days: 1))..forward();

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _auto?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  int get _index => _scene?.index ?? 0;

  // MARK: Flow

  void _boot() {
    _auto?.cancel();
    _snapshot(null, OnboardingGeometry.boot, instant: true);
    _auto = Timer(const Duration(milliseconds: 160), () {
      if (mounted) _goTo(OnboardingScene.intro);
    });
  }

  void _goTo(OnboardingScene next) {
    _auto?.cancel();
    _snapshot(next, OnboardingGeometry.geo(next), instant: false);
    final d = next.duration;
    if (d == null || next.index + 1 >= OnboardingScene.values.length) return;
    _auto = Timer(seconds(d), () {
      if (mounted) _goTo(OnboardingScene.values[next.index + 1]);
    });
  }

  /// Freezes the current in-flight values as the new start point, then retargets.
  void _snapshot(OnboardingScene? next, Geo geo, {required bool instant}) {
    final t = _now() - _changedAt;
    final current = {for (final a in Actor.values) a: instant ? geo[a]! : _from[a]!.transition(_to[a]!, t)};
    final layers = {for (final l in Layer.values) l: instant ? _target(l, next) : _layerOpacity(l, t)};
    final (blobs, blobOp) = instant
        ? (OnboardingGeometry.blobs(next), OnboardingGeometry.blobs(next).b2o)
        : _blobState(t);
    setState(() {
      _from = current;
      _layerFrom = layers;
      _blobFrom = blobs;
      _blobOpacityFrom = blobOp;
      _to = geo;
      _scene = next;
      _changedAt = _now();
    });
  }

  double _target(Layer l, OnboardingScene? s) => OnboardingGeometry.layers(s).contains(l) ? 1 : 0;

  /// `.ly`: opacity .75 s ease, delayed .5 s when fading in.
  double _layerOpacity(Layer l, double t) {
    final start = _layerFrom[l] ?? _target(l, null);
    final goal = _target(l, _scene);
    final p = keyframe(t, delay: goal > start ? 0.5 : 0, duration: 0.75, curve: Motion.ease);
    return mix(start, goal, p);
  }

  /// `.blob`: position/size 1.9 s cubic-bezier(.65,0,.35,1), opacity 1.6 s ease.
  (Blobs, double) _blobState(double t) {
    final goal = OnboardingGeometry.blobs(_scene);
    final p = keyframe(t, delay: 0, duration: 1.9, curve: const Cubic(0.65, 0, 0.35, 1));
    final o = keyframe(t, delay: 0, duration: 1.6, curve: Motion.ease);
    return (
      (
        b1: Offset.lerp(_blobFrom.b1, goal.b1, p)!,
        b1s: mix(_blobFrom.b1s, goal.b1s, p),
        b2: Offset.lerp(_blobFrom.b2, goal.b2, p)!,
        b2s: mix(_blobFrom.b2s, goal.b2s, p),
        b2o: goal.b2o,
      ),
      mix(_blobOpacityFrom, goal.b2o, o),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Palette.splash,
      child: AnimatedBuilder(
        animation: _ticker,
        builder: (context, _) {
          final now = _now();
          return DesignCanvas(children: _canvas(now - _changedAt, now));
        },
      ),
    );
  }

  // MARK: Canvas

  List<Widget> _canvas(double t, double now) {
    final (blobs, b2o) = _blobState(t);
    final layered = <(double, Widget)>[
      for (final a in Actor.values)
        () {
          final g = _from[a]!.transition(_to[a]!, t);
          return (g.z, _actor(a, g, t));
        }(),
      if (_scene != null && _scene != OnboardingScene.intro)
        (
          8,
          KeyedSubtree(
            key: ValueKey(_scene),
            child: _Sweep(t: t),
          ),
        ),
      (6, _text(t)),
      (10, _topBar()),
      if (_index < 4) (10, _controls(now)),
    ];
    // Stable sort by z, like SwiftUI zIndex.
    final ordered = [...layered.indexed]
      ..sort((a, b) {
        final c = a.$2.$1.compareTo(b.$2.$1);
        return c != 0 ? c : a.$1.compareTo(b.$1);
      });

    return [
      const Positioned.fill(child: ColoredBox(color: Palette.splash)),
      place(blobs.b1.dx, blobs.b1.dy, blobs.b1s, blobs.b1s, const ClosestSideGlow(Palette.blue, 0.55)),
      place(
        blobs.b2.dx,
        blobs.b2.dy,
        blobs.b2s,
        blobs.b2s,
        Opacity(opacity: b2o.clamp(0, 1), child: const ClosestSideGlow(Palette.yellow, 0.32)),
      ),
      place(
        0,
        844 - 380,
        390,
        380,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00071226), Palette.splash],
              stops: [0, 0.55],
            ),
          ),
        ),
      ),
      ..._sparks(now),
      for (final (_, (_, w)) in ordered) w,
    ];
  }

  // MARK: Actors

  Widget _actor(Actor a, ActorGeo g, double t) {
    final radius = g.radius;
    final s = g.shadow;
    return place(
      g.x,
      g.y,
      g.w,
      g.h,
      Opacity(
        opacity: g.opacity.clamp(0, 1),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (s.ringWidth > 0)
              Positioned(
                left: -s.ringWidth,
                top: -s.ringWidth,
                right: -s.ringWidth,
                bottom: -s.ringWidth,
                child: blurred(
                  s.ringWidth > 2 ? s.ringWidth / 2 : 0,
                  DecoratedBox(
                    decoration: BoxDecoration(color: s.ringColor, borderRadius: radius),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: s.radius > 0 || s.y != 0
                      ? [BoxShadow(color: s.color, blurRadius: s.radius, offset: Offset(0, s.y))]
                      : null,
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: g.color),
                    _layers(a, t),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fade(Layer l, double t, Widget child) {
    final o = _layerOpacity(l, t);
    if (o <= 0.001) return const SizedBox.shrink();
    return Opacity(opacity: o.clamp(0, 1), child: child);
  }

  Widget _layers(Actor a, double t) {
    switch (a) {
      case Actor.extra:
        return _fade(Layer.st3, t, _statusRow('Spouse ID', 'Submitted', Palette.blue.o(0.26), Palette.submittedText));
      case Actor.sun:
        return Stack(
          fit: StackFit.expand,
          children: [
            _fade(
              Layer.chip,
              t,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: 0.75,
                      child: Text(
                        'Consultation fee',
                        softWrap: false,
                        style: Typo.manrope(11, Typo.extrabold, Palette.ink),
                      ),
                    ),
                    Text('₱10,000.00', softWrap: false, style: Typo.outfit(19, Typo.bold, Palette.ink)),
                  ],
                ),
              ),
            ),
            _fade(Layer.journey, t, _journey(t)),
          ],
        );
      case Actor.door:
        return Stack(
          fit: StackFit.expand,
          children: [
            _fade(Layer.pp, t, const Photo('photoPP', kenBurns: true, kbDuration: 14)),
            _fade(
              Layer.book,
              t,
              Padding(
                padding: const EdgeInsets.only(left: 66),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking found', softWrap: false, style: Typo.manrope(14, Typo.extrabold, Palette.text)),
                    const SizedBox(height: 3),
                    Text('CAV-PHC-03-B12-L07', softWrap: false, style: Typo.mono(11, Typo.medium, Palette.muted)),
                  ],
                ),
              ),
            ),
            _fade(Layer.st1, t, _statusRow('Valid ID', 'Accepted', Palette.green.o(0.2), Palette.acceptedText)),
          ],
        );
      case Actor.bush:
        return Stack(
          fit: StackFit.expand,
          children: [
            _fade(Layer.pv, t, const Photo('photoPV', kenBurns: true, kbDuration: 14)),
            _fade(Layer.check, t, const Center(child: TIconView(TIcon.check, size: 22, color: Color(0xFFFFFFFF)))),
            _fade(Layer.st2, t, _statusRow('Payslips', 'Reviewed', Palette.yellow.o(0.16), Palette.reviewedText)),
          ],
        );
      case Actor.roof:
        return Stack(
          fit: StackFit.expand,
          children: [
            _fade(Layer.face, t, const DecoratedBox(decoration: BoxDecoration(gradient: Palette.roofGradient))),
            _fade(
              Layer.ph,
              t,
              Stack(
                fit: StackFit.expand,
                children: [
                  const Photo('photoPH', kenBurns: true, kbDuration: 14),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: 0.4,
                      widthFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Palette.night.o(0), Palette.night.o(0.85)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    bottom: 16,
                    child: Text(
                      'Pasinaya Homes',
                      softWrap: false,
                      style: Typo.manrope(12, Typo.extrabold, Palette.text),
                    ),
                  ),
                ],
              ),
            ),
            _fade(
              Layer.row,
              t,
              adjusted(const Photo('photoRow', kenBurns: true, kbDuration: 14), brightness: -0.5, saturation: 1.1),
            ),
            _fade(Layer.hts, t, const Photo('photoHTS', kenBurns: true, kbDuration: 14)),
            _fade(Layer.scan, t, _scanLayer()),
          ],
        );
    }
  }

  Widget _statusRow(String title, String pill, Color bg, Color fg) => Padding(
    padding: const EdgeInsets.only(left: 16, right: 12),
    child: Row(
      children: [
        Text(title, softWrap: false, style: Typo.manrope(13, Typo.extrabold, Palette.text)),
        const Spacer(),
        StatusPill(pill, background: bg, foreground: fg),
      ],
    ),
  );

  /// The yellow journey pill: family → striped track growing to 62% → house.
  Widget _journey(double t) {
    final grow = _scene == OnboardingScene.track
        ? keyframe(t, delay: 0.9, duration: 1.4, curve: const Cubic(0.65, 0, 0.35, 1))
        : 0.0;
    Widget cap(TIcon icon) => Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Palette.ink, shape: BoxShape.circle),
      child: TIconView(icon, size: 22, color: Palette.yellow),
    );
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          cap(TIcon.family),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 10,
              child: LayoutBuilder(
                builder: (_, box) => Stack(
                  children: [
                    DecoratedBox(
                      decoration: ShapeDecoration(color: Palette.ink.o(0.18), shape: const StadiumBorder()),
                      child: const SizedBox.expand(),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: SizedBox(
                        width: box.maxWidth * 0.62 * grow,
                        height: 10,
                        child: const CustomPaint(painter: StripesPainter(light: 0.7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          cap(TIcon.home),
        ],
      ),
    );
  }

  Widget _scanLayer() => Stack(
    fit: StackFit.expand,
    children: [
      Center(
        child: Container(
          width: 150,
          height: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: const Color(0xFF000000).o(0.45), blurRadius: 20, offset: const Offset(0, 20))],
          ),
          child: const DecorativeQR(),
        ),
      ),
      const Padding(
        padding: EdgeInsets.all(22),
        child: ScanCorners(length: 40, lineWidth: 4, radius: 16, color: Palette.yellow),
      ),
      if (_scene == OnboardingScene.scan)
        LayoutBuilder(builder: (_, box) => ScanLine(from: 0.14, to: 0.84, inset: box.maxWidth * 0.12)),
    ],
  );

  // MARK: Sparks

  List<Widget> _sparks(double now) => [
    for (final (i, s) in OnboardingGeometry.sparks.indexed)
      () {
        final d = 7 + (i % 4) * 2.0;
        final p = ((now + i * 1.3) % d) / d;
        final op = p < 0.15
            ? mix(0, 0.9, p / 0.15)
            : (p < 0.85 ? mix(0.9, 0.6, (p - 0.15) / 0.7) : mix(0.6, 0, (p - 0.85) / 0.15));
        return place(
          s.$1,
          s.$2 - 140 * p,
          s.$3,
          s.$3,
          Opacity(
            opacity: op.clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: i % 3 == 0 ? Palette.white(0.7) : Palette.yellow,
                borderRadius: BorderRadius.circular(9),
              ),
            ),
          ),
        );
      }(),
  ];

  // MARK: Top bar

  Widget _topBar() => Positioned(
    left: 20,
    top: 54,
    width: 350,
    child: Row(
      children: [
        AnimatedOpacity(
          opacity: _index == 0 || _index == 4 ? 0 : 1,
          duration: const Duration(milliseconds: 800),
          curve: Motion.easeInOut,
          child: const TahananLockup(markWidth: 28, fontSize: 19),
        ),
        const Spacer(),
        if (_index < 4)
          _pill('Skip', null, () => _goTo(OnboardingScene.ready))
        else
          _pill('Replay', TIcon.replay, _boot),
      ],
    ),
  );

  Widget _pill(String title, TIcon? icon, VoidCallback onTap) => Pressable(
    onTap: onTap,
    semanticLabel: title,
    child: Container(
      height: 44,
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 18 : 16),
      decoration: ShapeDecoration(
        color: Palette.white(0.08),
        shape: StadiumBorder(side: hairline(Palette.white(0.14))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[TIconView(icon, size: 16, color: Palette.text), const SizedBox(width: 8)],
          Text(title, style: Typo.manrope(14, Typo.bold, Palette.text)),
        ],
      ),
    ),
  );

  // MARK: Text

  Widget _text(double t) {
    switch (_scene) {
      case OnboardingScene.intro:
        final trk = keyframe(t, delay: 1.9, duration: 1.6);
        return Positioned(
          left: 0,
          top: 462,
          width: 390,
          child: Column(
            children: [
              _WordReveal(word: 'Tahanan', size: 54, weight: Typo.bold, color: Palette.text, t: t, delay: 1.5),
              const SizedBox(height: 14),
              Opacity(
                opacity: trk,
                child: Text(
                  'BY RAEMULAN LANDS',
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: Typo.manrope(
                    12,
                    Typo.extrabold,
                    Palette.muted,
                  ).copyWith(letterSpacing: mix(12, 0.34 * 12, trk)),
                ),
              ),
              const SizedBox(height: 26),
              _BodyIn(
                t: t,
                delay: 2.3,
                child: Text(
                  'One arch is a roofline. Together, they make a family.',
                  style: Typo.manrope(14, Typo.regular, Palette.subtle),
                ),
              ),
            ],
          ),
        );
      case OnboardingScene.discover:
        return _sceneText(
          OnboardingScene.discover,
          'Tuklasin · Discover',
          'Explore Pasinaya, Pagsikat and Pagsibol communities — slides, galleries and prices in one place.',
          t,
        );
      case OnboardingScene.scan:
        return _sceneText(
          OnboardingScene.scan,
          'I-scan · Scan',
          'Scan the QR from your Homeful seller to open your booking or payment — nothing to retype.',
          t,
        );
      case OnboardingScene.track:
        return _sceneText(
          OnboardingScene.track,
          'Subaybayan · Track',
          'Upload requirements, see when they’re reviewed and accepted, and get help without a call.',
          t,
        );
      case OnboardingScene.ready:
        return _readyText(t);
      case null:
        return const SizedBox.shrink();
    }
  }

  static final _body = Typo.manrope(15, Typo.regular, Palette.muted).copyWith(height: 1.366 + 0.3);

  Widget _sceneText(OnboardingScene s, String eyebrow, String body, double t) => Positioned(
    left: 24,
    top: 540,
    width: 342,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Eyebrow(text: eyebrow, t: t, delay: 0.15),
        const SizedBox(height: 12),
        _Headline(scene: s, size: 38, t: t, base: 0.38, step: 0.075, center: false),
        const SizedBox(height: 12),
        _BodyIn(
          t: t,
          delay: 0.75,
          child: Text(body, style: _body),
        ),
      ],
    ),
  );

  Widget _readyText(double t) => Positioned(
    left: 24,
    top: 438,
    width: 342,
    child: Column(
      children: [
        _Eyebrow(text: 'Handa ka na? · Ready?', t: t, delay: 1.2),
        const SizedBox(height: 12),
        _Headline(scene: OnboardingScene.ready, size: 40, t: t, base: 1.3, step: 0.08, center: true),
        const SizedBox(height: 12),
        _BodyIn(
          t: t,
          delay: 1.7,
          child: IText(
            'Create an account to save homes, book with your seller and track your application.',
            textAlign: TextAlign.center,
            style: _body,
          ),
        ),
        const SizedBox(height: 26),
        _BodyIn(
          t: t,
          delay: 1.9,
          child: Column(
            children: [
              PrimaryButton(
                'Create account',
                icon: TIcon.arrowUpRight,
                height: 58,
                chipSize: 46,
                onTap: () => context.go(const Screen(ScreenKind.signup)),
              ),
              const SizedBox(height: 10),
              Pressable(
                onTap: () => context.go(const Screen(ScreenKind.login)),
                semanticLabel: 'I already have an account',
                child: Container(
                  height: 54,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: Palette.white(0.06),
                    shape: StadiumBorder(side: hairline(Palette.white(0.15))),
                  ),
                  child: Text('I already have an account', style: Typo.manrope(15, Typo.bold, Palette.text)),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  // MARK: Controls

  Widget _controls(double now) {
    final elapsed = now - _changedAt;
    return Positioned(
      left: 24,
      top: 844 - 40 - 68,
      width: 346,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Onboarding progress',
              child: Row(
                children: [
                  for (var j = 0; j < 4; j++) ...[
                    if (j > 0) const SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 4,
                        child: LayoutBuilder(
                          builder: (_, box) {
                            final d = OnboardingScene.values[j].duration;
                            return Stack(
                              children: [
                                DecoratedBox(
                                  decoration: ShapeDecoration(color: Palette.white(0.18), shape: const StadiumBorder()),
                                  child: const SizedBox.expand(),
                                ),
                                if (j < _index)
                                  const DecoratedBox(
                                    decoration: ShapeDecoration(color: Color(0xFFFFFFFF), shape: StadiumBorder()),
                                    child: SizedBox.expand(),
                                  )
                                else if (j == _index && d != null)
                                  Container(
                                    width: box.maxWidth * ((_scene == null ? 0 : elapsed) / d).clamp(0, 1),
                                    decoration: const ShapeDecoration(color: Palette.yellow, shape: StadiumBorder()),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Pressable(
            onTap: () => _goTo(
              _index + 1 < OnboardingScene.values.length ? OnboardingScene.values[_index + 1] : OnboardingScene.ready,
            ),
            semanticLabel: 'Next',
            child: SizedBox.square(
              dimension: 68,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: -6,
                    top: -6,
                    width: 80,
                    height: 80,
                    child: PulseRing(color: Palette.yellow.o(0.5), to: 1.5),
                  ),
                  Container(
                    width: 68,
                    height: 68,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Palette.yellow,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Palette.yellow.o(0.5), blurRadius: 14, offset: const Offset(0, 16))],
                    ),
                    child: const TIconView(TIcon.arrowRight, size: 26, color: Palette.ink),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: Text effects

/// `.eb`: eyebrow tracking in from .6em to .16em with blur, 1.2 s.
class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text, required this.t, required this.delay});

  final String text;
  final double t, delay;

  @override
  Widget build(BuildContext context) {
    final p = keyframe(t, delay: delay, duration: 1.2);
    return Opacity(
      opacity: p,
      child: blurred(
        4 * (1 - p),
        Text(
          text.toUpperCase(),
          softWrap: false,
          overflow: TextOverflow.visible,
          style: Typo.manrope(12, Typo.extrabold, Palette.yellow).copyWith(letterSpacing: mix(0.6, 0.16, p) * 12),
        ),
      ),
    );
  }
}

/// `.bd`: translateY 14 + blur 5 → 0, 1 s.
class _BodyIn extends StatelessWidget {
  const _BodyIn({required this.t, required this.delay, required this.child});

  final double t, delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = keyframe(t, delay: delay, duration: 1);
    return Opacity(
      opacity: p,
      child: Transform.translate(offset: Offset(0, 14 * (1 - p)), child: blurred(5 * (1 - p), child)),
    );
  }
}

/// Headline words rising from behind a mask (`.wm` / `.wi`), staggered, with the accent word in yellow.
class _Headline extends StatelessWidget {
  const _Headline({
    required this.scene,
    required this.size,
    required this.t,
    required this.base,
    required this.step,
    required this.center,
  });

  final OnboardingScene scene;
  final double size, t, base, step;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final words = OnboardingGeometry.titles[scene] ?? const <String>[];
    final accent = OnboardingGeometry.accent[scene];
    return Semantics(
      label: words.join(' '),
      excludeSemantics: true,
      child: SizedBox(
        width: 342,
        child: Wrap(
          alignment: center ? WrapAlignment.center : WrapAlignment.start,
          spacing: 0.24 * size,
          runSpacing: -0.22 * size,
          children: [
            for (final (j, w) in words.indexed)
              _WordReveal(
                word: w,
                size: size,
                weight: Typo.semibold,
                color: w == accent ? Palette.yellow : Palette.text,
                t: t,
                delay: base + j * step,
              ),
          ],
        ),
      ),
    );
  }
}

class _WordReveal extends StatelessWidget {
  const _WordReveal({
    required this.word,
    required this.size,
    required this.weight,
    required this.color,
    required this.t,
    required this.delay,
  });

  final String word;
  final double size;
  final FontWeight weight;
  final Color color;
  final double t, delay;

  @override
  Widget build(BuildContext context) {
    // wiA: translateY 115% rotate 7deg blur 6 → none, 1.05 s cubic-bezier(.16,1,.3,1)
    final p = keyframe(t, delay: delay, duration: 1.05, curve: const Cubic(0.16, 1, 0.3, 1));
    final h = size * 1.18;
    return ClipRect(
      child: Padding(
        padding: EdgeInsets.only(bottom: size * 0.1),
        child: Opacity(
          opacity: p.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, h * 1.15 * (1 - p)),
            child: Transform.rotate(
              angle: 7 * (1 - p) * math.pi / 180,
              alignment: Alignment.bottomLeft,
              child: blurred(
                6 * (1 - p),
                Text(
                  word,
                  softWrap: false,
                  style: Typo.outfit(size, weight, color).copyWith(letterSpacing: -0.035 * size),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Light sweep that crosses the canvas on each scene change (1.6 s cubic-bezier(.6,0,.2,1)).
class _Sweep extends StatelessWidget {
  const _Sweep({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final p = keyframe(t, delay: 0, duration: 1.6, curve: const Cubic(0.6, 0, 0.2, 1));
    if (p >= 1) return const SizedBox.shrink();
    const w = 390 * 2.2;
    return Positioned(
      left: -390 * 0.6 + w * mix(-0.45, 0.45, p),
      top: -84.4,
      width: w,
      height: 844 * 1.2,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(-0.96, -0.2),
              end: const Alignment(0.96, 0.2),
              colors: [Palette.white(0), Palette.white(0.09), Palette.yellow.o(0.06), Palette.white(0)],
              stops: const [0.42, 0.5, 0.53, 0.61],
            ),
          ),
        ),
      ),
    );
  }
}
