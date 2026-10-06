import SwiftUI

/// "Maligayang pagdating!" — the logo assembles as on the splash, with looping arch rings.
struct WelcomeView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var start = Date()

    var body: some View {
        ZStack {
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSince(start)
                ZStack(alignment: .top) {
                    LoopingArchRing(t: t, width: 300, height: 380, color: Palette.yellow.opacity(0.35), delay: 0)
                        .padding(.top, 170 - 54)
                    LoopingArchRing(t: t, width: 420, height: 500, color: .white(0.18), delay: 1)
                        .padding(.top, 120 - 54)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                TimelineView(.animation) { ctx in
                    MarkIntro(width: 120, t: ctx.date.timeIntervalSince(start))
                }
                .frame(width: 120, height: 115.38)

                Text("Account created").eyebrow().padding(.top, 40).rise(delay: 1.6)
                Text("Maligayang pagdating!").h1(38).multilineTextAlignment(.center).padding(.top, 12).rise(delay: 1.75)
                Text("You’re all set. Explore communities now, and scan your seller’s QR whenever you’re ready to book.")
                    .mutedBody().multilineTextAlignment(.center).padding(.top, 14).rise(delay: 1.9)
                PrimaryButton("Explore homes") { router.go(.home, state: state) }
                    .padding(.top, 34)
                    .rise(delay: 2.05)
            }
            .padding(.horizontal, 28)
        }
        .onAppear { start = Date() }
    }
}

/// `.sp-ring` set to loop (3s): an open arch outline scaling .15 → 1 while fading 0 → .7 → 0.
struct LoopingArchRing: View {
    let t: Double
    let width: CGFloat
    let height: CGFloat
    let color: Color
    let delay: Double
    var duration: Double = 3

    var body: some View {
        let local = t - delay
        let raw = local < 0 ? 0 : (local.truncatingRemainder(dividingBy: duration)) / duration
        let c = CubicBezier.standard
        let opacity = local < 0 ? 0 : (raw < 0.25 ? mix(0, 0.7, c(raw / 0.25)) : mix(0.7, 0, c((raw - 0.25) / 0.75)))
        ArchOutline()
            .stroke(color, lineWidth: 1.5)
            .frame(width: width, height: height)
            .scaleEffect(mix(0.15, 1, c(raw)))
            .opacity(opacity)
    }
}

#Preview {
    WelcomeView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
