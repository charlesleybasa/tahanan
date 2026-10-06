import SwiftUI

/// Per-scene geometry for the five morphing logo shapes, copied from the `GEO` object in
/// design/buyer/Onboarding-Cinematic.dc.html.
enum OnboardingScene: Int, CaseIterable {
    case intro, discover, scan, track, ready

    /// Autoplay durations (DUR): 4.2s, 5.2s × 3, ready holds.
    var duration: Double? {
        switch self {
        case .intro: return 4.2
        case .discover, .scan, .track: return 5.2
        case .ready: return nil
        }
    }
}

enum OnboardingActor: CaseIterable { case extra, sun, door, bush, roof }

/// Content layers that cross-fade inside the actors.
enum OnboardingLayer: CaseIterable {
    case face, ph, row, hts, scan, chip, journey, pp, book, st1, pv, check, st2, st3
}

/// An interpolatable sRGB color.
struct RGBA: Equatable {
    var r: Double, g: Double, b: Double, a: Double

    static func hex(_ h: UInt32, _ a: Double = 1) -> RGBA {
        RGBA(r: Double((h >> 16) & 0xFF) / 255, g: Double((h >> 8) & 0xFF) / 255, b: Double(h & 0xFF) / 255, a: a)
    }

    static let clear = RGBA(r: 0, g: 0, b: 0, a: 0)
    static let yellow = hex(0xFFC42E), blue = hex(0x2E6BE6), orange = hex(0xF2622E), green = hex(0x2FA96B), ink = hex(0x0B1A33)

    var color: Color { Color(.sRGB, red: r, green: g, blue: b, opacity: a) }
    func with(_ alpha: Double) -> RGBA { RGBA(r: r, g: g, b: b, a: alpha) }

    func lerp(_ o: RGBA, _ p: Double) -> RGBA {
        RGBA(r: mix(r, o.r, p), g: mix(g, o.g, p), b: mix(b, o.b, p), a: mix(a, o.a, p))
    }
}

struct ActorShadow: Equatable {
    var color: RGBA = .clear
    var radius: CGFloat = 0
    var y: CGFloat = 0
    /// The second `0 0 0 Npx` ring in the box-shadow (an outline / spread glow).
    var ringColor: RGBA = .clear
    var ringWidth: CGFloat = 0

    static let none = ActorShadow()
    /// SHP: 0 40px 80px -24px rgba(0,0,0,.85), 0 0 0 1px rgba(255,255,255,.16)
    static let photo = ActorShadow(color: RGBA(r: 0, g: 0, b: 0, a: 0.7), radius: 34, y: 40, ringColor: RGBA(r: 1, g: 1, b: 1, a: 0.16), ringWidth: 1)
    /// SHG: 0 22px 44px -18px rgba(0,0,0,.85), 0 0 0 1px rgba(255,255,255,.13)
    static let glass = ActorShadow(color: RGBA(r: 0, g: 0, b: 0, a: 0.7), radius: 18, y: 22, ringColor: RGBA(r: 1, g: 1, b: 1, a: 0.13), ringWidth: 1)

    func lerp(_ o: ActorShadow, _ p: Double) -> ActorShadow {
        ActorShadow(color: color.lerp(o.color, p), radius: CGFloat(mix(radius, o.radius, p)), y: CGFloat(mix(y, o.y, p)),
                    ringColor: ringColor.lerp(o.ringColor, p), ringWidth: CGFloat(mix(ringWidth, o.ringWidth, p)))
    }
}

struct ActorGeo: Equatable {
    var x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat
    /// tl, tr, br, bl
    var r: (CGFloat, CGFloat, CGFloat, CGFloat)
    var color: RGBA
    var shadow: ActorShadow
    var z: Double
    var opacity: Double
    var delay: Double

    static func == (a: ActorGeo, b: ActorGeo) -> Bool {
        a.x == b.x && a.y == b.y && a.w == b.w && a.h == b.h && a.r == b.r && a.color == b.color && a.z == b.z && a.opacity == b.opacity
    }

    /// CSS transition between two geometries at elapsed time `t` since the change:
    /// left/top/size/radius 1.25s cubic-bezier(.77,0,.175,1), background-color .9s ease,
    /// box-shadow 1.25s ease, opacity .8s ease — all after the target's transition-delay.
    func transition(to o: ActorGeo, at t: Double) -> ActorGeo {
        let dt = t - o.delay
        let g = keyframe(dt, delay: 0, duration: 1.25, curve: CubicBezier(0.77, 0, 0.175, 1))
        let c = keyframe(dt, delay: 0, duration: 0.9, curve: .ease)
        let s = keyframe(dt, delay: 0, duration: 1.25, curve: .ease)
        let op = keyframe(dt, delay: 0, duration: 0.8, curve: .ease)
        func m(_ a: CGFloat, _ b: CGFloat) -> CGFloat { CGFloat(mix(Double(a), Double(b), g)) }
        return ActorGeo(
            x: m(x, o.x), y: m(y, o.y), w: m(w, o.w), h: m(h, o.h),
            r: (m(r.0, o.r.0), m(r.1, o.r.1), m(r.2, o.r.2), m(r.3, o.r.3)),
            color: color.lerp(o.color, c), shadow: shadow.lerp(o.shadow, s),
            z: o.z, opacity: mix(opacity, o.opacity, op), delay: o.delay
        )
    }

    var radii: RectangleCornerRadii {
        RectangleCornerRadii(topLeading: r.0, bottomLeading: r.3, bottomTrailing: r.2, topTrailing: r.1)
    }
}

enum OnboardingGeometry {
    /// GLASS: rgba(16,33,64,.94)
    static let glassColor = RGBA.hex(0x102140, 0.94)
    static let panel = RGBA.hex(0x0F2142)

    private static func act(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: (CGFloat, CGFloat, CGFloat, CGFloat),
                            _ c: RGBA, _ s: ActorShadow, _ z: Double, _ o: Double, _ dl: Double) -> ActorGeo {
        ActorGeo(x: x, y: y, w: w, h: h, r: r, color: c, shadow: s, z: z, opacity: o, delay: dl)
    }

    private static func all(_ r: CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat) { (r, r, r, r) }

    /// mark(L, T, k, delays): the logo laid out at a scale; delays are [roof, sun, door, bush].
    private static func mark(_ L: CGFloat, _ T: CGFloat, _ k: CGFloat, _ dl: [Double]) -> [OnboardingActor: ActorGeo] {
        let sunGlow = ActorShadow(color: RGBA.yellow.with(0.45), radius: 30, y: 0, ringColor: RGBA.yellow.with(0.2), ringWidth: 10)
        return [
            .sun: act(L + 50 * k, T, 54 * k, 54 * k, all(27 * k), RGBA.yellow, sunGlow, 1, 1, dl[1]),
            .roof: act(L, T + 18 * k, 70 * k, 82 * k, (35 * k, 35 * k, 5 * k, 5 * k), RGBA.blue, .none, 2, 1, dl[0]),
            .door: act(L + 22 * k, T + 62 * k, 26 * k, 38 * k, (13 * k, 13 * k, 0, 0), RGBA.orange, .none, 3, 1, dl[2]),
            .bush: act(L + 81 * k, T + 77 * k, 19 * k, 23 * k, (9.5 * k, 9.5 * k, 3 * k, 3 * k), RGBA.green, .none, 3, 1, dl[3]),
            .extra: act(L + 40 * k, T + 70 * k, 20, 20, all(10), glassColor, .none, 0, 0, 0),
        ]
    }

    static let boot: [OnboardingActor: ActorGeo] = {
        let k: CGFloat = 180 / 104, L: CGFloat = 105, T: CGFloat = 244
        let base = T + 100 * k
        return [
            .sun: act(L + 50 * k + 27 * k, base - 20, 0, 0, all(0), RGBA.yellow, .none, 1, 0, 0),
            .roof: act(L, base, 70 * k, 0, (35 * k, 35 * k, 0, 0), RGBA.blue, .none, 2, 1, 0),
            .door: act(L + 22 * k, base, 26 * k, 0, all(0), RGBA.orange, .none, 3, 1, 0),
            .bush: act(L + 81 * k + 9 * k, base, 0, 0, all(0), RGBA.green, .none, 3, 1, 0),
            .extra: act(180, 360, 20, 20, all(10), glassColor, .none, 0, 0, 0),
        ]
    }()

    static func geo(_ scene: OnboardingScene) -> [OnboardingActor: ActorGeo] {
        switch scene {
        case .intro:
            return mark(105, 244, 180 / 104, [0.15, 0.75, 1.05, 1.3])
        case .discover:
            return [
                .roof: act(100, 150, 190, 312, (95, 95, 24, 24), panel, .photo, 3, 1, 0),
                .sun: act(214, 104, 150, 150, all(75), RGBA.yellow, ActorShadow(color: RGBA.yellow.with(0.42), radius: 55, ringColor: RGBA.yellow.with(0.16), ringWidth: 28), 1, 1, 0.1),
                .door: act(18, 296, 124, 196, (62, 62, 18, 18), panel, .photo, 2, 1, 0.18),
                .bush: act(250, 286, 122, 192, (61, 61, 18, 18), panel, .photo, 2, 1, 0.26),
                .extra: act(180, 360, 20, 20, all(10), glassColor, .none, 0, 0, 0),
            ]
        case .scan:
            return [
                .roof: act(65, 140, 260, 310, all(36), RGBA.ink, .photo, 2, 1, 0),
                .sun: act(22, 118, 172, 60, all(18), RGBA.yellow, ActorShadow(color: RGBA.yellow.with(0.45), radius: 16, y: 22), 4, 1, 0.12),
                .door: act(146, 420, 224, 66, all(20), glassColor, .glass, 3, 1, 0.2),
                .bush: act(158, 431, 44, 44, all(22), RGBA.green, ActorShadow(ringColor: RGBA.green.with(0.22), ringWidth: 6), 5, 1, 0.32),
                .extra: act(180, 360, 20, 20, all(10), glassColor, .none, 0, 0, 0),
            ]
        case .track:
            return [
                .roof: act(150, 138, 212, 292, (106, 106, 24, 24), panel, .photo, 1, 1, 0),
                .sun: act(20, 452, 350, 64, all(32), RGBA.yellow, ActorShadow(color: RGBA.yellow.with(0.45), radius: 16, y: 18), 4, 1, 0.3),
                .door: act(20, 186, 214, 54, all(18), glassColor, .glass, 3, 1, 0.08),
                .bush: act(36, 256, 214, 54, all(18), glassColor, .glass, 3, 1, 0.16),
                .extra: act(20, 326, 214, 54, all(18), glassColor, .glass, 3, 1, 0.24),
            ]
        case .ready:
            return mark(120, 196, 150 / 104, [0.25, 0.15, 0.08, 0])
        }
    }

    /// LAYERS: which content layers are visible per scene.
    static func layers(_ scene: OnboardingScene?) -> Set<OnboardingLayer> {
        switch scene {
        case nil, .intro, .ready: return [.face]
        case .discover: return [.ph, .pp, .pv]
        case .scan: return [.row, .scan, .chip, .book, .check]
        case .track: return [.hts, .journey, .st1, .st2, .st3]
        }
    }

    struct Blobs: Equatable {
        var b1: CGPoint, b1s: CGFloat, b2: CGPoint, b2s: CGFloat, b2o: Double
    }

    /// BG: drifting glow positions per scene.
    static func blobs(_ scene: OnboardingScene?) -> Blobs {
        switch scene {
        case nil: return Blobs(b1: CGPoint(x: -40, y: 520), b1s: 470, b2: CGPoint(x: 120, y: 300), b2s: 160, b2o: 0)
        case .intro: return Blobs(b1: CGPoint(x: -80, y: 380), b1s: 560, b2: CGPoint(x: 110, y: 160), b2s: 320, b2o: 1)
        case .discover: return Blobs(b1: CGPoint(x: -120, y: 160), b1s: 520, b2: CGPoint(x: 150, y: 20), b2s: 320, b2o: 1)
        case .scan: return Blobs(b1: CGPoint(x: 20, y: 80), b1s: 420, b2: CGPoint(x: -120, y: 20), b2s: 300, b2o: 0.7)
        case .track: return Blobs(b1: CGPoint(x: 120, y: 40), b1s: 420, b2: CGPoint(x: -80, y: 330), b2s: 360, b2o: 0.9)
        case .ready: return Blobs(b1: CGPoint(x: -80, y: 320), b1s: 560, b2: CGPoint(x: 110, y: 110), b2s: 320, b2o: 1)
        }
    }

    static let titles: [OnboardingScene: [String]] = [
        .discover: ["Every", "family’s", "home", "begins", "here."],
        .scan: ["Scan", "once.", "Book", "in", "minutes."],
        .track: ["Watch", "every", "step", "home."],
        .ready: ["Your", "tahanan", "is", "waiting."],
    ]

    static let accent: [OnboardingScene: String] = [.discover: "home", .scan: "minutes.", .track: "home.", .ready: "tahanan"]

    /// SPARKS: [x, y, size]; every third is white, durations 7–13s, negative delays.
    static let sparks: [(CGFloat, CGFloat, CGFloat)] = [
        (40, 520, 4), (92, 300, 3), (150, 610, 5), (210, 250, 3), (262, 560, 4),
        (320, 340, 5), (350, 620, 3), (70, 690, 3), (300, 180, 4), (180, 700, 4),
    ]
}
