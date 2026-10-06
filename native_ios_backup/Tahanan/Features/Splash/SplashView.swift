import SwiftUI

/// 4.4s splash, timed from the `.sp-*` keyframes in Main.dc.html:
/// dawn rises, arch rings expand, the roof arch grows from the bottom, the sun rises and glows,
/// the door grows, the bush pops, "Tahanan" rises letter by letter, the byline tracks in,
/// then everything blurs and scales out into onboarding.
struct SplashView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var start = Date()

    private let letters = Array("Tahanan")

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSince(start)
            content(t)
        }
        .background(Palette.splash.ignoresSafeArea())
        .task {
            start = Date()
            try? await Task.sleep(nanoseconds: 4_400_000_000)
            router.go(.onboarding, state: state)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tahanan by Raemulan Lands")
    }

    @ViewBuilder
    private func content(_ t: Double) -> some View {
        // .sp-out: 0.85s cubic-bezier(.6,0,.4,1) at 3.55s
        let out = keyframe(t, delay: 3.55, duration: 0.85, curve: CubicBezier(0.6, 0, 0.4, 1))

        DesignCanvas {
            Palette.splash.frame(width: 390, height: 844)

            Group {
                dawn(t)
                ring(t, top: 250, w: 300, h: 400, color: .white(0.22), delay: 0.2)
                ring(t, top: 170, w: 460, h: 560, color: Palette.yellow.opacity(0.3), delay: 0.55)
                ring(t, top: 90, w: 640, h: 760, color: .white(0.14), delay: 0.9)
                MarkIntro(width: 150, t: t).offset(x: 120, y: 300)
                wordmark(t).frame(width: 390).offset(y: 300 + 144.23 + 30)
                tagline(t)
            }
            .opacity(1 - out)
            .scaleEffect(mix(1, 1.12, out))
            .blur(radius: 14 * out)
        }
    }

    /// .sp-dawn: 2.8s from .5s, opacity 0→1 and translateY 35% → 0.
    private func dawn(_ t: Double) -> some View {
        let p = keyframe(t, delay: 0.5, duration: 2.8)
        let w: CGFloat = 390 * 1.8, h: CGFloat = 844 * 0.75
        return CornerBox(w / 2, w / 2, 0, 0)
            .fill(Color.clear)
            .background(
                CSSRadialGradient(rx: 0.5, ry: 0.5, cx: 0.5, cy: 0.5, stops: [
                    .init(color: Palette.blue.opacity(0.55), location: 0),
                    .init(color: Palette.blue.opacity(0.12), location: 0.55),
                    .init(color: Palette.blue.opacity(0), location: 0.75),
                ])
            )
            .clipShape(EllipticTop())
            .frame(width: w, height: h)
            .offset(x: -390 * 0.4, y: 844 + 844 * 0.3 - h + h * 0.35 * (1 - p))
            .opacity(p)
    }

    /// .sp-ring: 3.4s ringOut — scale .15 → 1, opacity 0 → .7 (25%) → 0.
    private func ring(_ t: Double, top: CGFloat, w: CGFloat, h: CGFloat, color: Color, delay: Double) -> some View {
        let curve = CubicBezier.standard
        let raw = min(max((t - delay) / 3.4, 0), 1)
        let scale = mix(0.15, 1, curve(raw))
        let opacity = raw < 0.25 ? mix(0, 0.7, curve(raw / 0.25)) : mix(0.7, 0, curve((raw - 0.25) / 0.75))
        return ArchOutline()
            .stroke(color, lineWidth: 1.5)
            .frame(width: w, height: h)
            .scaleEffect(scale)
            .opacity(t < delay ? 0 : opacity)
            .offset(x: 195 - w / 2, y: top)
    }

    /// "Tahanan" letters (letterA .85s, 60ms stagger from 1.7s) and the tracked byline (trackA 1.5s from 2.2s).
    private func wordmark(_ t: Double) -> some View {
        let track = keyframe(t, delay: 2.2, duration: 1.5)
        return VStack(spacing: 14) {
            HStack(spacing: -0.035 * 54) {
                ForEach(letters.indices, id: \.self) { i in
                    let p = keyframe(t, delay: 1.7 + Double(i) * 0.06, duration: 0.85)
                    Text(String(letters[i]))
                        .font(Typo.fixedOutfit(54, .bold))
                        .foregroundStyle(.white)
                        .opacity(p)
                        .offset(y: 46 * (1 - p))
                        .rotationEffect(.degrees(8 * (1 - p)))
                        .blur(radius: 10 * (1 - p))
                }
            }
            Text("BY RAEMULAN LANDS")
                .font(Typo.fixedManrope(12, .extrabold))
                .tracking(mix(12, 0.34 * 12, track))
                .foregroundStyle(Palette.muted)
                .opacity(track)
                .fixedSize()
        }
    }

    /// .sp-tag: fade 1s ease at 2.7s, bottom 70.
    private func tagline(_ t: Double) -> some View {
        Text("One arch is a roofline. Together, they make a family.")
            .font(Typo.fixedManrope(14))
            .foregroundStyle(Palette.subtle)
            .frame(width: 390)
            .opacity(keyframe(t, delay: 2.7, duration: 1, curve: .ease))
            .offset(y: 844 - 70 - 19)
    }

}

/// The logo assembling itself, as on the splash and Welcome: roof archUp (.35s, 1.05s), sun sunUp (.85s, 1.3s)
/// with a pulsing glow from 2.2s, door archUp (1.25s, .75s), bush pop (1.55s, .65s).
struct MarkIntro: View {
    let width: CGFloat
    /// Seconds since the animation started.
    let t: Double

    var body: some View {
        let k: CGFloat = width / 104
        let roof = keyframe(t, delay: 0.35, duration: 1.05, curve: CubicBezier(0.2, 0.9, 0.2, 1))
        let sun = keyframe(t, delay: 0.85, duration: 1.3)
        let door = keyframe(t, delay: 1.25, duration: 0.75, curve: CubicBezier(0.2, 0.9, 0.2, 1))
        let bush = keyframe(t, delay: 1.55, duration: 0.65, curve: CubicBezier(0.2, 0.9, 0.3, 1.5))
        // sunGlow: 3.2s ease-in-out infinite from 2.2s, 36/4 .45 <-> 70/14 .65 (at 150px; scales with the mark)
        let g = t < 2.2 ? 0 : CubicBezier.easeInOut(Self.triangle((t - 2.2) / 3.2))
        let f = width / 150
        let glowBlur = mix(36, 70, g) * f, glowSpread = mix(4, 14, g) * f, glowAlpha = mix(0.45, 0.65, g)

        ZStack(alignment: .topLeading) {
            ZStack {
                Circle().fill(Palette.yellow.opacity(glowAlpha))
                    .frame(width: 54 * k + glowSpread * 2, height: 54 * k + glowSpread * 2)
                    .blur(radius: glowBlur / 2)
                Circle().fill(Palette.yellow).frame(width: 54 * k, height: 54 * k)
            }
            .frame(width: 54 * k, height: 54 * k)
            .scaleEffect(mix(0.55, 1, sun))
            .offset(x: 50 * k, y: 54 * k * 0.7 * (1 - sun))
            .opacity(sun)

            CornerBox(35 * k, 35 * k, 5 * k, 5 * k).fill(Palette.roofGradient)
                .frame(width: 70 * k, height: 82 * k)
                .scaleEffect(x: 1, y: max(roof, 0.0001), anchor: .bottom)
                .offset(y: 18 * k)

            CornerBox(13 * k, 13 * k, 0, 0).fill(Palette.orange)
                .frame(width: 26 * k, height: 38 * k)
                .scaleEffect(x: 1, y: max(door, 0.0001), anchor: .bottom)
                .offset(x: 22 * k, y: 62 * k)

            CornerBox(9.5 * k, 9.5 * k, 3 * k, 3 * k).fill(Palette.green)
                .frame(width: 19 * k, height: 23 * k)
                .scaleEffect(max(bush, 0.0001))
                .opacity(min(1, max(0, bush)))
                .offset(x: 81 * k, y: 77 * k)
        }
        .frame(width: width, height: 100 * k, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    static func triangle(_ x: Double) -> Double {
        let f = x - floor(x)
        return f < 0.5 ? f * 2 : (1 - f) * 2
    }
}

/// border-radius: 50% 50% 0 0 — elliptical top corners spanning the full width and half the height.
private struct EllipticTop: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let rx = rect.width / 2, ry = rect.height / 2
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + ry))
        p.addArc(center: CGPoint(x: rect.midX, y: rect.minY + ry), radius: rx, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false,
                 transform: CGAffineTransform(translationX: rect.midX, y: rect.minY + ry).scaledBy(x: 1, y: ry / rx).translatedBy(x: -rect.midX, y: -(rect.minY + ry)))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

#Preview {
    SplashView().environment(AppState.preview).environment(AppRouter())
}
