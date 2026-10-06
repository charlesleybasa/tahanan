import 'package:flutter/widgets.dart';

import '../../theme/theme.dart';

/// Per-scene geometry for the five morphing logo shapes, copied from the `GEO` object in
/// design/buyer/Onboarding-Cinematic.dc.html (via the native OnboardingGeometry.swift).
enum OnboardingScene {
  intro,
  discover,
  scan,
  track,
  ready;

  /// Autoplay durations (DUR): 4.2 s, 5.2 s × 3, ready holds.
  double? get duration => switch (this) {
    intro => 4.2,
    discover || scan || track => 5.2,
    ready => null,
  };
}

enum Actor { extra, sun, door, bush, roof }

/// Content layers that cross-fade inside the actors.
enum Layer { face, ph, row, hts, scan, chip, journey, pp, book, st1, pv, check, st2, st3 }

class ActorShadow {
  const ActorShadow({
    this.color = const Color(0x00000000),
    this.radius = 0,
    this.y = 0,
    this.ringColor = const Color(0x00000000),
    this.ringWidth = 0,
  });

  final Color color;
  final double radius, y;

  /// The second `0 0 0 Npx` ring in the box-shadow (an outline / spread glow).
  final Color ringColor;
  final double ringWidth;

  static const none = ActorShadow();

  /// SHP: 0 40px 80px -24px rgba(0,0,0,.85), 0 0 0 1px rgba(255,255,255,.16)
  static const photo = ActorShadow(
    color: Color(0xB3000000),
    radius: 34,
    y: 40,
    ringColor: Color(0x29FFFFFF),
    ringWidth: 1,
  );

  /// SHG: 0 22px 44px -18px rgba(0,0,0,.85), 0 0 0 1px rgba(255,255,255,.13)
  static const glass = ActorShadow(
    color: Color(0xB3000000),
    radius: 18,
    y: 22,
    ringColor: Color(0x21FFFFFF),
    ringWidth: 1,
  );

  ActorShadow lerp(ActorShadow o, double p) => ActorShadow(
    color: Color.lerp(color, o.color, p)!,
    radius: mix(radius, o.radius, p),
    y: mix(y, o.y, p),
    ringColor: Color.lerp(ringColor, o.ringColor, p)!,
    ringWidth: mix(ringWidth, o.ringWidth, p),
  );
}

typedef Radii4 = (double, double, double, double);

class ActorGeo {
  const ActorGeo({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.r,
    required this.color,
    required this.shadow,
    required this.z,
    required this.opacity,
    required this.delay,
  });

  final double x, y, w, h;

  /// tl, tr, br, bl
  final Radii4 r;
  final Color color;
  final ActorShadow shadow;
  final double z, opacity, delay;

  static const _morph = Cubic(0.77, 0, 0.175, 1);

  /// CSS transition between two geometries at elapsed time [t] since the change:
  /// left/top/size/radius 1.25 s cubic-bezier(.77,0,.175,1), background-color .9 s ease,
  /// box-shadow 1.25 s ease, opacity .8 s ease — all after the target's transition-delay.
  ActorGeo transition(ActorGeo o, double t) {
    final dt = t - o.delay;
    final g = keyframe(dt, delay: 0, duration: 1.25, curve: _morph);
    final c = keyframe(dt, delay: 0, duration: 0.9, curve: Motion.ease);
    final s = keyframe(dt, delay: 0, duration: 1.25, curve: Motion.ease);
    final op = keyframe(dt, delay: 0, duration: 0.8, curve: Motion.ease);
    double m(double a, double b) => mix(a, b, g);
    return ActorGeo(
      x: m(x, o.x),
      y: m(y, o.y),
      w: m(w, o.w),
      h: m(h, o.h),
      r: (m(r.$1, o.r.$1), m(r.$2, o.r.$2), m(r.$3, o.r.$3), m(r.$4, o.r.$4)),
      color: Color.lerp(color, o.color, c)!,
      shadow: shadow.lerp(o.shadow, s),
      z: o.z,
      opacity: mix(opacity, o.opacity, op),
      delay: o.delay,
    );
  }

  BorderRadius get radius => cornerBox(r.$1, r.$2, r.$3, r.$4);
}

typedef Geo = Map<Actor, ActorGeo>;

typedef Blobs = ({Offset b1, double b1s, Offset b2, double b2s, double b2o});

abstract final class OnboardingGeometry {
  /// GLASS: rgba(16,33,64,.94)
  static const glassColor = Color(0xF0102140);
  static const panel = Color(0xFF0F2142);

  static ActorGeo _act(
    double x,
    double y,
    double w,
    double h,
    Radii4 r,
    Color c,
    ActorShadow s,
    double z,
    double o,
    double dl,
  ) => ActorGeo(x: x, y: y, w: w, h: h, r: r, color: c, shadow: s, z: z, opacity: o, delay: dl);

  static Radii4 _all(double r) => (r, r, r, r);

  /// mark(L, T, k, delays): the logo laid out at a scale; delays are [roof, sun, door, bush].
  static Geo _mark(double L, double T, double k, List<double> dl) {
    final sunGlow = ActorShadow(
      color: Palette.yellow.o(0.45),
      radius: 30,
      ringColor: Palette.yellow.o(0.2),
      ringWidth: 10,
    );
    return {
      Actor.sun: _act(L + 50 * k, T, 54 * k, 54 * k, _all(27 * k), Palette.yellow, sunGlow, 1, 1, dl[1]),
      Actor.roof: _act(
        L,
        T + 18 * k,
        70 * k,
        82 * k,
        (35 * k, 35 * k, 5 * k, 5 * k),
        Palette.blue,
        ActorShadow.none,
        2,
        1,
        dl[0],
      ),
      Actor.door: _act(
        L + 22 * k,
        T + 62 * k,
        26 * k,
        38 * k,
        (13 * k, 13 * k, 0, 0),
        Palette.orange,
        ActorShadow.none,
        3,
        1,
        dl[2],
      ),
      Actor.bush: _act(
        L + 81 * k,
        T + 77 * k,
        19 * k,
        23 * k,
        (9.5 * k, 9.5 * k, 3 * k, 3 * k),
        Palette.green,
        ActorShadow.none,
        3,
        1,
        dl[3],
      ),
      Actor.extra: _act(L + 40 * k, T + 70 * k, 20, 20, _all(10), glassColor, ActorShadow.none, 0, 0, 0),
    };
  }

  static final Geo boot = () {
    const k = 180 / 104, L = 105.0, T = 244.0;
    const base = T + 100 * k;
    return {
      Actor.sun: _act(L + 50 * k + 27 * k, base - 20, 0, 0, _all(0), Palette.yellow, ActorShadow.none, 1, 0, 0),
      Actor.roof: _act(L, base, 70 * k, 0, (35 * k, 35 * k, 0, 0), Palette.blue, ActorShadow.none, 2, 1, 0),
      Actor.door: _act(L + 22 * k, base, 26 * k, 0, _all(0), Palette.orange, ActorShadow.none, 3, 1, 0),
      Actor.bush: _act(L + 81 * k + 9 * k, base, 0, 0, _all(0), Palette.green, ActorShadow.none, 3, 1, 0),
      Actor.extra: _act(180, 360, 20, 20, _all(10), glassColor, ActorShadow.none, 0, 0, 0),
    };
  }();

  static Geo geo(OnboardingScene scene) {
    final hidden = _act(180, 360, 20, 20, _all(10), glassColor, ActorShadow.none, 0, 0, 0);
    return switch (scene) {
      OnboardingScene.intro => _mark(105, 244, 180 / 104, const [0.15, 0.75, 1.05, 1.3]),
      OnboardingScene.discover => {
        Actor.roof: _act(100, 150, 190, 312, (95, 95, 24, 24), panel, ActorShadow.photo, 3, 1, 0),
        Actor.sun: _act(
          214,
          104,
          150,
          150,
          _all(75),
          Palette.yellow,
          ActorShadow(color: Palette.yellow.o(0.42), radius: 55, ringColor: Palette.yellow.o(0.16), ringWidth: 28),
          1,
          1,
          0.1,
        ),
        Actor.door: _act(18, 296, 124, 196, (62, 62, 18, 18), panel, ActorShadow.photo, 2, 1, 0.18),
        Actor.bush: _act(250, 286, 122, 192, (61, 61, 18, 18), panel, ActorShadow.photo, 2, 1, 0.26),
        Actor.extra: hidden,
      },
      OnboardingScene.scan => {
        Actor.roof: _act(65, 140, 260, 310, _all(36), Palette.ink, ActorShadow.photo, 2, 1, 0),
        Actor.sun: _act(
          22,
          118,
          172,
          60,
          _all(18),
          Palette.yellow,
          ActorShadow(color: Palette.yellow.o(0.45), radius: 16, y: 22),
          4,
          1,
          0.12,
        ),
        Actor.door: _act(146, 420, 224, 66, _all(20), glassColor, ActorShadow.glass, 3, 1, 0.2),
        Actor.bush: _act(
          158,
          431,
          44,
          44,
          _all(22),
          Palette.green,
          ActorShadow(ringColor: Palette.green.o(0.22), ringWidth: 6),
          5,
          1,
          0.32,
        ),
        Actor.extra: hidden,
      },
      OnboardingScene.track => {
        Actor.roof: _act(150, 138, 212, 292, (106, 106, 24, 24), panel, ActorShadow.photo, 1, 1, 0),
        Actor.sun: _act(
          20,
          452,
          350,
          64,
          _all(32),
          Palette.yellow,
          ActorShadow(color: Palette.yellow.o(0.45), radius: 16, y: 18),
          4,
          1,
          0.3,
        ),
        Actor.door: _act(20, 186, 214, 54, _all(18), glassColor, ActorShadow.glass, 3, 1, 0.08),
        Actor.bush: _act(36, 256, 214, 54, _all(18), glassColor, ActorShadow.glass, 3, 1, 0.16),
        Actor.extra: _act(20, 326, 214, 54, _all(18), glassColor, ActorShadow.glass, 3, 1, 0.24),
      },
      OnboardingScene.ready => _mark(120, 196, 150 / 104, const [0.25, 0.15, 0.08, 0]),
    };
  }

  /// LAYERS: which content layers are visible per scene.
  static Set<Layer> layers(OnboardingScene? scene) => switch (scene) {
    null || OnboardingScene.intro || OnboardingScene.ready => {Layer.face},
    OnboardingScene.discover => {Layer.ph, Layer.pp, Layer.pv},
    OnboardingScene.scan => {Layer.row, Layer.scan, Layer.chip, Layer.book, Layer.check},
    OnboardingScene.track => {Layer.hts, Layer.journey, Layer.st1, Layer.st2, Layer.st3},
  };

  /// BG: drifting glow positions per scene.
  static Blobs blobs(OnboardingScene? scene) => switch (scene) {
    null => (b1: const Offset(-40, 520), b1s: 470, b2: const Offset(120, 300), b2s: 160, b2o: 0),
    OnboardingScene.intro => (b1: const Offset(-80, 380), b1s: 560, b2: const Offset(110, 160), b2s: 320, b2o: 1),
    OnboardingScene.discover => (b1: const Offset(-120, 160), b1s: 520, b2: const Offset(150, 20), b2s: 320, b2o: 1),
    OnboardingScene.scan => (b1: const Offset(20, 80), b1s: 420, b2: const Offset(-120, 20), b2s: 300, b2o: 0.7),
    OnboardingScene.track => (b1: const Offset(120, 40), b1s: 420, b2: const Offset(-80, 330), b2s: 360, b2o: 0.9),
    OnboardingScene.ready => (b1: const Offset(-80, 320), b1s: 560, b2: const Offset(110, 110), b2s: 320, b2o: 1),
  };

  static const titles = {
    OnboardingScene.discover: ['Every', 'family’s', 'home', 'begins', 'here.'],
    OnboardingScene.scan: ['Scan', 'once.', 'Book', 'in', 'minutes.'],
    OnboardingScene.track: ['Watch', 'every', 'step', 'home.'],
    OnboardingScene.ready: ['Your', 'tahanan', 'is', 'waiting.'],
  };

  static const accent = {
    OnboardingScene.discover: 'home',
    OnboardingScene.scan: 'minutes.',
    OnboardingScene.track: 'home.',
    OnboardingScene.ready: 'tahanan',
  };

  /// SPARKS: (x, y, size); every third is white, durations 7–13 s.
  static const sparks = [
    (40.0, 520.0, 4.0),
    (92.0, 300.0, 3.0),
    (150.0, 610.0, 5.0),
    (210.0, 250.0, 3.0),
    (262.0, 560.0, 4.0),
    (320.0, 340.0, 5.0),
    (350.0, 620.0, 3.0),
    (70.0, 690.0, 3.0),
    (300.0, 180.0, 4.0),
    (180.0, 700.0, 4.0),
  ];
}
