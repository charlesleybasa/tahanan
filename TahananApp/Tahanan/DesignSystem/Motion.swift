import SwiftUI

// MARK: - Curves

/// CSS `cubic-bezier()` easings used in the prototype.
enum Motion {
    /// Screen enter / rise: cubic-bezier(.2,.8,.2,1)
    static func standard(_ duration: Double) -> Animation { .timingCurve(0.2, 0.8, 0.2, 1, duration: duration) }
    /// Bottom sheet: cubic-bezier(.2,.9,.2,1)
    static func sheet(_ duration: Double = 0.55) -> Animation { .timingCurve(0.2, 0.9, 0.2, 1, duration: duration) }
    /// Pop: cubic-bezier(.2,.9,.3,1.35)
    static func pop(_ duration: Double = 0.7) -> Animation { .timingCurve(0.2, 0.9, 0.3, 1.35, duration: duration) }
    /// Onboarding morph: cubic-bezier(.77,0,.175,1)
    static func morph(_ duration: Double = 1.25) -> Animation { .timingCurve(0.77, 0, 0.175, 1, duration: duration) }

    static let screen = standard(0.75)
    /// `.d1`–`.d8` stagger delays from the prototype CSS.
    static let stagger: [Double] = [0, 0.07, 0.14, 0.21, 0.28, 0.36, 0.44, 0.52, 0.6]
}

/// Evaluates a CSS cubic-bezier for timeline-driven keyframes (y may overshoot 0…1).
struct CubicBezier {
    let p1x: Double, p1y: Double, p2x: Double, p2y: Double

    init(_ p1x: Double, _ p1y: Double, _ p2x: Double, _ p2y: Double) {
        self.p1x = p1x; self.p1y = p1y; self.p2x = p2x; self.p2y = p2y
    }

    static let standard = CubicBezier(0.2, 0.8, 0.2, 1)
    static let easeInOut = CubicBezier(0.42, 0, 0.58, 1)
    static let ease = CubicBezier(0.25, 0.1, 0.25, 1)
    static let easeOut = CubicBezier(0, 0, 0.58, 1)
    static let linear = CubicBezier(0, 0, 1, 1)

    private func coord(_ t: Double, _ a: Double, _ b: Double) -> Double {
        let u = 1 - t
        return 3 * u * u * t * a + 3 * u * t * t * b + t * t * t
    }

    func callAsFunction(_ x: Double) -> Double {
        if x <= 0 { return 0 }
        if x >= 1 { return 1 }
        var lo = 0.0, hi = 1.0, t = x
        for _ in 0..<40 {
            let cx = coord(t, p1x, p2x)
            if abs(cx - x) < 1e-5 { break }
            if cx < x { lo = t } else { hi = t }
            t = (lo + hi) / 2
        }
        return coord(t, p1y, p2y)
    }
}

/// Progress of a CSS animation with `both` fill mode at elapsed time `t`.
func keyframe(_ t: Double, delay: Double, duration: Double, curve: CubicBezier = .standard) -> Double {
    let raw = (t - delay) / duration
    return curve(min(max(raw, 0), 1))
}

func mix(_ a: Double, _ b: Double, _ p: Double) -> Double { a + (b - a) * p }

// MARK: - Screen transition

/// `.scr`: fade + scale 1.035 → 1 + blur 10 → 0, 0.75s cubic-bezier(.2,.8,.2,1).
struct ScreenEnterModifier: ViewModifier {
    let active: Bool
    func body(content: Content) -> some View {
        content
            .opacity(active ? 0 : 1)
            .scaleEffect(active ? 1.035 : 1)
            .blur(radius: active ? 10 : 0)
    }
}

extension AnyTransition {
    /// Matches the prototype: the outgoing screen is removed immediately, the incoming one plays `scrIn`.
    static var screen: AnyTransition {
        .asymmetric(
            insertion: .modifier(active: ScreenEnterModifier(active: true), identity: ScreenEnterModifier(active: false)),
            removal: .identity
        )
    }

    static var fadeIn: AnyTransition { .asymmetric(insertion: .opacity, removal: .identity) }
}

// MARK: - Rise

/// `.rise`: translateY 26 + blur 6 → 0 with opacity, 0.85s, staggered via `.d1`–`.d8`.
extension EnvironmentValues {
    /// Tab switches show content in place instead of replaying `.rise` staggers.
    @Entry var skipEntrance = false
}

struct RiseModifier: ViewModifier {
    let delay: Double
    var distance: CGFloat = 26
    var blur: CGFloat = 6
    var duration: Double = 0.85
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.skipEntrance) private var skip

    func body(content: Content) -> some View {
        let visible = shown || skip
        return content
            .opacity(visible ? 1 : 0)
            .offset(y: visible || reduceMotion ? 0 : distance)
            .blur(radius: visible || reduceMotion ? 0 : blur)
            .onAppear {
                guard !skip else { return }
                withAnimation(Motion.standard(duration).delay(delay)) { shown = true }
            }
    }
}

extension View {
    /// `rise(3)` = `.rise.d3`.
    func rise(_ step: Int = 0) -> some View { modifier(RiseModifier(delay: Motion.stagger[min(step, 8)])) }
    func rise(delay: Double) -> some View { modifier(RiseModifier(delay: delay)) }
}

// MARK: - Fade / pop

struct FadeInModifier: ViewModifier {
    var duration: Double = 0.4
    var delay: Double = 0
    @State private var shown = false
    func body(content: Content) -> some View {
        content.opacity(shown ? 1 : 0)
            .onAppear { withAnimation(.easeInOut(duration: duration).delay(delay)) { shown = true } }
    }
}

/// `.pop`: scale 0 → 1 with opacity, cubic-bezier(.2,.9,.3,1.35).
struct PopModifier: ViewModifier {
    var delay: Double = 0
    var duration: Double = 0.7
    var curve: Animation? = nil
    @State private var shown = false
    func body(content: Content) -> some View {
        content.scaleEffect(shown ? 1 : 0.001).opacity(shown ? 1 : 0)
            .onAppear { withAnimation((curve ?? Motion.pop(duration)).delay(delay)) { shown = true } }
    }
}

extension View {
    func fadeIn(_ duration: Double = 0.4, delay: Double = 0) -> some View { modifier(FadeInModifier(duration: duration, delay: delay)) }
    func pop(delay: Double = 0) -> some View { modifier(PopModifier(delay: delay)) }
}

// MARK: - Ambient loops

/// Ken Burns on photos: scale 1.06 → 1.22 + translate(-2%,-2%), ease-in-out, alternate.
struct KenBurnsModifier: ViewModifier {
    var duration: Double = 16
    var to: CGFloat = 1.22
    @State private var on = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .visualEffect { [on] c, proxy in
                c.scaleEffect(on ? to : 1.06, anchor: UnitPoint(x: 0.6, y: 0.4))
                    .offset(x: on ? -0.02 * proxy.size.width * to : 0, y: on ? -0.02 * proxy.size.height * to : 0)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) { on = true }
            }
    }
}

/// `.float`: translateY 0 → -12 → 0 ease-in-out infinite, with a negative CSS delay as phase.
struct FloatModifier: ViewModifier {
    var period: Double = 6
    var phase: Double = 0
    var amplitude: CGFloat = 12
    var enabled = true
    func body(content: Content) -> some View {
        TimelineView(.animation(paused: !enabled)) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate + phase
            let p = (t.truncatingRemainder(dividingBy: period)) / period
            // 0%,100% at 0, 50% at -12 with ease-in-out per half
            let half = p < 0.5 ? p * 2 : (1 - p) * 2
            content.offset(y: -amplitude * CubicBezier.easeInOut(half))
        }
    }
}

/// `.glow`: opacity .75 ↔ 1 and scale 1 ↔ 1.08 over 5s.
struct GlowPulseModifier: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content.opacity(on ? 1 : 0.75).scaleEffect(on ? 1.08 : 1)
            .onAppear { withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) { on = true } }
    }
}

/// `.ring`: scale .92 → 1.55 while fading .8 → 0, 2.2s ease-out infinite.
struct PulseRing: View {
    var color: Color
    var lineWidth: CGFloat = 2
    var to: CGFloat = 1.55
    var cornerRadius: CGFloat? = nil

    var body: some View {
        TimelineView(.animation) { ctx in
            let p = CubicBezier.easeOut((ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.2)) / 2.2)
            Group {
                if let r = cornerRadius {
                    RoundedRectangle(cornerRadius: r).strokeBorder(color, lineWidth: lineWidth)
                } else {
                    Circle().strokeBorder(color, lineWidth: lineWidth)
                }
            }
            .scaleEffect(mix(0.92, to, p))
            .opacity(mix(0.8, 0, p))
        }
        .allowsHitTesting(false)
    }
}

/// `.spin`: 0.9s linear rotation.
struct Spinner: View {
    var size: CGFloat
    var lineWidth: CGFloat
    var track: Color = .white(0.15)
    var head: Color = Palette.yellow

    var body: some View {
        TimelineView(.animation) { ctx in
            let angle = (ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 0.9)) / 0.9 * 360
            ZStack {
                Circle().stroke(track, lineWidth: lineWidth)
                // border-top-color: the top quarter of the ring
                Circle().trim(from: 0.625, to: 0.875).stroke(head, lineWidth: lineWidth)
            }
            .rotationEffect(.degrees(angle))
            .padding(lineWidth / 2)
            .frame(width: size, height: size)
        }
    }
}

/// `.caret`: 2 × 26 yellow bar blinking with steps(1) every second.
struct BlinkingCaret: View {
    var height: CGFloat = 26
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { ctx in
            let on = Int(ctx.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
            Rectangle().fill(Palette.yellow).frame(width: 2, height: height).opacity(on ? 1 : 0)
        }
    }
}

/// `.scanline`: travels between 8% and 88% of the parent over 2.4s ease-in-out.
struct ScanLine: View {
    var from: CGFloat = 0.08
    var to: CGFloat = 0.88
    var inset: CGFloat = 18
    var thickness: CGFloat = 3
    var glow: CGFloat = 22

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { ctx in
                let p = (ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 2.4)) / 2.4
                let half = p < 0.5 ? p * 2 : (1 - p) * 2
                let y = geo.size.height * mix(from, to, CubicBezier.easeInOut(half))
                Capsule()
                    .fill(Palette.yellow)
                    .frame(width: max(0, geo.size.width - inset * 2), height: thickness)
                    .shadow(color: Palette.yellow.opacity(0.65), radius: glow / 2)
                    .shadow(color: Palette.yellow.opacity(0.4), radius: glow / 4)
                    .position(x: geo.size.width / 2, y: y)
            }
        }
        .allowsHitTesting(false)
    }
}

extension View {
    func kenBurns(_ duration: Double = 16, to: CGFloat = 1.22) -> some View { modifier(KenBurnsModifier(duration: duration, to: to)) }
    func floating(period: Double = 6, phase: Double = 0) -> some View { modifier(FloatModifier(period: period, phase: phase)) }
    func glowPulse() -> some View { modifier(GlowPulseModifier()) }

    /// `.press:active{transform:scale(.97)}`
    func pressable() -> some View { buttonStyle(PressStyle()) }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
            .contentShape(Rectangle())
    }
}
