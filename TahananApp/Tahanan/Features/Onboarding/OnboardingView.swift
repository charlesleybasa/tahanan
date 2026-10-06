import SwiftUI

/// The cinematic morphing onboarding (design/buyer/Onboarding-Cinematic.dc.html): the five logo shapes
/// persist across intro → discover → scan → track → ready and transition between the `GEO` layouts.
/// Everything is driven from one timeline so each property follows its CSS transition exactly,
/// including interruptions (a new transition starts from the current in-flight value).
struct OnboardingView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router

    /// nil = the "boot" layout shown for 160ms before intro.
    @State private var scene: OnboardingScene? = nil
    @State private var changedAt = Date()
    @State private var from: [OnboardingActor: ActorGeo] = OnboardingGeometry.boot
    @State private var to: [OnboardingActor: ActorGeo] = OnboardingGeometry.boot
    @State private var layerFrom: [OnboardingLayer: Double] = [:]
    @State private var blobFrom = OnboardingGeometry.blobs(nil)
    @State private var blobOpacityFrom: Double = 0
    @State private var autoTask: Task<Void, Never>?

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSince(changedAt)
            DesignCanvas {
                canvas(t, now: ctx.date)
            }
        }
        .background(Palette.splash.ignoresSafeArea())
        .onAppear { boot() }
        .onDisappear { autoTask?.cancel() }
    }

    // MARK: - Flow

    private func boot() {
        autoTask?.cancel()
        snapshot(to: nil, geo: OnboardingGeometry.boot, instant: true)
        autoTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 160_000_000)
            guard !Task.isCancelled else { return }
            goTo(.intro)
        }
    }

    private func goTo(_ next: OnboardingScene) {
        autoTask?.cancel()
        snapshot(to: next, geo: OnboardingGeometry.geo(next), instant: false)
        guard let d = next.duration, let following = OnboardingScene(rawValue: next.rawValue + 1) else { return }
        autoTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(d * 1_000_000_000))
            guard !Task.isCancelled else { return }
            goTo(following)
        }
    }

    /// Freezes the current in-flight values as the new start point, then retargets.
    private func snapshot(to next: OnboardingScene?, geo: [OnboardingActor: ActorGeo], instant: Bool) {
        let t = Date().timeIntervalSince(changedAt)
        var current: [OnboardingActor: ActorGeo] = [:]
        for a in OnboardingActor.allCases {
            current[a] = instant ? geo[a]! : from[a]!.transition(to: to[a]!, at: t)
        }
        var layers: [OnboardingLayer: Double] = [:]
        for l in OnboardingLayer.allCases { layers[l] = instant ? target(l, next) : layerOpacity(l, t) }
        let blobs = instant ? OnboardingGeometry.blobs(next) : blobState(t).0
        let blobOp = instant ? OnboardingGeometry.blobs(next).b2o : blobState(t).1

        from = current
        layerFrom = layers
        blobFrom = blobs
        blobOpacityFrom = blobOp
        to = geo
        scene = next
        changedAt = Date()
    }

    private func target(_ l: OnboardingLayer, _ s: OnboardingScene?) -> Double {
        OnboardingGeometry.layers(s).contains(l) ? 1 : 0
    }

    /// `.ly`: opacity .75s ease, delayed .5s when fading in.
    private func layerOpacity(_ l: OnboardingLayer, _ t: Double) -> Double {
        let start = layerFrom[l] ?? target(l, nil)
        let goal = target(l, scene)
        let p = keyframe(t, delay: goal > start ? 0.5 : 0, duration: 0.75, curve: .ease)
        return mix(start, goal, p)
    }

    /// `.blob`: position/size 1.9s cubic-bezier(.65,0,.35,1), opacity 1.6s ease.
    private func blobState(_ t: Double) -> (OnboardingGeometry.Blobs, Double) {
        let goal = OnboardingGeometry.blobs(scene)
        let p = keyframe(t, delay: 0, duration: 1.9, curve: CubicBezier(0.65, 0, 0.35, 1))
        let o = keyframe(t, delay: 0, duration: 1.6, curve: .ease)
        func m(_ a: CGFloat, _ b: CGFloat) -> CGFloat { CGFloat(mix(Double(a), Double(b), p)) }
        let b = OnboardingGeometry.Blobs(
            b1: CGPoint(x: m(blobFrom.b1.x, goal.b1.x), y: m(blobFrom.b1.y, goal.b1.y)), b1s: m(blobFrom.b1s, goal.b1s),
            b2: CGPoint(x: m(blobFrom.b2.x, goal.b2.x), y: m(blobFrom.b2.y, goal.b2.y)), b2s: m(blobFrom.b2s, goal.b2s),
            b2o: goal.b2o
        )
        return (b, mix(blobOpacityFrom, goal.b2o, o))
    }

    private var index: Int { scene?.rawValue ?? 0 }

    // MARK: - Canvas

    @ViewBuilder
    private func canvas(_ t: Double, now: Date) -> some View {
        let (blobs, b2o) = blobState(t)

        Palette.splash.frame(width: 390, height: 844)

        ClosestSideGlow(Palette.blue, 0.55)
            .place(blobs.b1.x, blobs.b1.y, blobs.b1s, blobs.b1s)
        ClosestSideGlow(Palette.yellow, 0.32)
            .place(blobs.b2.x, blobs.b2.y, blobs.b2s, blobs.b2s)
            .opacity(b2o)
        LinearGradient(stops: [.init(color: Palette.splash.opacity(0), location: 0), .init(color: Palette.splash, location: 0.55)],
                       startPoint: .top, endPoint: .bottom)
            .place(0, 844 - 380, 390, 380)

        sparks(now)

        ForEach(OnboardingActor.allCases, id: \.self) { a in
            actorView(a, geo: from[a]!.transition(to: to[a]!, at: t), t: t)
        }

        if let scene, scene != .intro {
            Sweep(t: t).id(scene).zIndex(8)
        }

        topBar
        text(t)
        if index < 4 { controls(now) }
    }

    // MARK: Actors

    private func actorView(_ a: OnboardingActor, geo g: ActorGeo, t: Double) -> some View {
        let shape = UnevenRoundedRectangle(cornerRadii: g.radii, style: .circular)
        return ZStack {
            Rectangle().fill(g.color.color)
            layers(for: a, t: t)
        }
        .frame(width: max(g.w, 0.01), height: max(g.h, 0.01))
        .clipShape(shape)
        .background(
            shape.fill(g.shadow.ringColor.color)
                .padding(-g.shadow.ringWidth)
                .blur(radius: g.shadow.ringWidth > 2 ? g.shadow.ringWidth / 2 : 0)
        )
        .shadow(color: g.shadow.color.color, radius: g.shadow.radius, y: g.shadow.y)
        .opacity(g.opacity)
        .offset(x: g.x, y: g.y)
        .zIndex(g.z)
    }

    @ViewBuilder
    private func layers(for a: OnboardingActor, t: Double) -> some View {
        switch a {
        case .extra:
            statusRow("Spouse ID", "Submitted", bg: Palette.blue.opacity(0.26), fg: Palette.submittedText)
                .opacity(layerOpacity(.st3, t))
        case .sun:
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Consultation fee").font(Typo.fixedManrope(11, .extrabold)).opacity(0.75)
                    Text("₱10,000.00").font(Typo.fixedOutfit(19, .bold))
                }
                .fixedSize()
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .opacity(layerOpacity(.chip, t))

                journey(t).opacity(layerOpacity(.journey, t))
            }
        case .door:
            ZStack {
                Photo(name: "photoPP", kenBurns: true, kbDuration: 14).opacity(layerOpacity(.pp, t))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Booking found").font(Typo.fixedManrope(14, .extrabold)).foregroundStyle(Palette.text)
                    Text("CAV-PHC-03-B12-L07").font(Typo.fixedMono(11)).foregroundStyle(Palette.muted)
                }
                .fixedSize()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(.leading, 66)
                .opacity(layerOpacity(.book, t))
                statusRow("Valid ID", "Accepted", bg: Palette.green.opacity(0.2), fg: Palette.acceptedText)
                    .opacity(layerOpacity(.st1, t))
            }
        case .bush:
            ZStack {
                Photo(name: "photoPV", kenBurns: true, kbDuration: 14).opacity(layerOpacity(.pv, t))
                IconView(.check, size: 22).foregroundStyle(.white).opacity(layerOpacity(.check, t))
                statusRow("Payslips", "Reviewed", bg: Palette.yellow.opacity(0.16), fg: Palette.reviewedText)
                    .opacity(layerOpacity(.st2, t))
            }
        case .roof:
            ZStack {
                Rectangle().fill(Palette.roofGradient).opacity(layerOpacity(.face, t))
                ZStack(alignment: .bottomLeading) {
                    Photo(name: "photoPH", kenBurns: true, kbDuration: 14)
                    GeometryReader { geo in
                        LinearGradient(colors: [Palette.night.opacity(0), Palette.night.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                            .frame(height: geo.size.height * 0.4)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    Text("Pasinaya Homes").font(Typo.fixedManrope(12, .extrabold)).foregroundStyle(Palette.text)
                        .fixedSize().padding(.leading, 18).padding(.bottom, 16)
                }
                .opacity(layerOpacity(.ph, t))
                Photo(name: "photoRow", kenBurns: true, kbDuration: 14)
                    .brightness(-0.5).saturation(1.1)
                    .opacity(layerOpacity(.row, t))
                Photo(name: "photoHTS", kenBurns: true, kbDuration: 14).opacity(layerOpacity(.hts, t))
                scanLayer.opacity(layerOpacity(.scan, t))
            }
        }
    }

    private func statusRow(_ title: String, _ pill: String, bg: Color, fg: Color) -> some View {
        HStack {
            Text(title).font(Typo.fixedManrope(13, .extrabold)).foregroundStyle(Palette.text).fixedSize()
            Spacer(minLength: 0)
            StatusPill(text: pill, tone: .custom(bg: bg, fg: fg))
        }
        .padding(.leading, 16).padding(.trailing, 12)
    }

    /// The yellow journey pill: family → striped track growing to 62% → house.
    private func journey(_ t: Double) -> some View {
        let grow = scene == .track ? keyframe(t, delay: 0.9, duration: 1.4, curve: CubicBezier(0.65, 0, 0.35, 1)) : 0
        return HStack(spacing: 10) {
            Circle().fill(Palette.ink).frame(width: 48, height: 48)
                .overlay(IconView(.family, size: 22).foregroundStyle(Palette.yellow))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.ink.opacity(0.18))
                    StripesFill(dark: 0.95, light: 0.7).frame(width: geo.size.width * 0.62 * grow).clipShape(Capsule())
                }
            }
            .frame(height: 10)
            Circle().fill(Palette.ink).frame(width: 48, height: 48)
                .overlay(IconView(.home, size: 22).foregroundStyle(Palette.yellow))
        }
        .padding(8)
    }

    private var scanLayer: some View {
        ZStack {
            DecorativeQR().padding(10).frame(width: 150, height: 150)
                .background(RoundedRectangle(cornerRadius: 16).fill(.white))
                .shadow(color: .black.opacity(0.45), radius: 20, y: 20)
            ScanCorners(length: 40, lineWidth: 4, radius: 16, color: Palette.yellow).padding(22)
            if scene == .scan {
                GeometryReader { geo in
                    ScanLine(from: 0.14, to: 0.84, inset: geo.size.width * 0.12)
                }
            }
        }
    }

    // MARK: Sparks

    private func sparks(_ now: Date) -> some View {
        let t = now.timeIntervalSinceReferenceDate
        return ForEach(OnboardingGeometry.sparks.indices, id: \.self) { i in
            let s = OnboardingGeometry.sparks[i]
            let d = 7 + Double(i % 4) * 2
            let p = ((t + Double(i) * 1.3).truncatingRemainder(dividingBy: d)) / d
            let op: Double = p < 0.15 ? mix(0, 0.9, p / 0.15) : (p < 0.85 ? mix(0.9, 0.6, (p - 0.15) / 0.7) : mix(0.6, 0, (p - 0.85) / 0.15))
            RoundedRectangle(cornerRadius: 9)
                .fill(i % 3 == 0 ? Color.white(0.7) : Palette.yellow)
                .place(s.0, s.1 - 140 * p, s.2, s.2)
                .opacity(op)
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            TahananLockup(markWidth: 28, fontSize: 19)
                .opacity(index == 0 || index == 4 ? 0 : 1)
                .animation(.easeInOut(duration: 0.8), value: index)
            Spacer()
            if index < 4 {
                pillButton("Skip", icon: nil) { goTo(.ready) }
            } else {
                pillButton("Replay", icon: .replay) { boot() }
            }
        }
        .frame(width: 350)
        .offset(x: 20, y: 54)
        .zIndex(10)
    }

    private func pillButton(_ title: String, icon: Icon?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { IconView(icon, size: 16) }
                Text(title).font(Typo.fixedManrope(14, .bold))
            }
            .foregroundStyle(Palette.text)
            .padding(.horizontal, icon == nil ? 18 : 16)
            .frame(height: 44)
            .background(Capsule().fill(Color.white(0.08)))
            .overlay(Capsule().strokeBorder(Color.white(0.14), lineWidth: 1))
        }
        .pressable()
    }

    // MARK: Text

    @ViewBuilder
    private func text(_ t: Double) -> some View {
        switch scene {
        case .intro:
            VStack(spacing: 0) {
                WordReveal(word: "Tahanan", size: 54, weight: .bold, color: Palette.text, t: t, delay: 1.5)
                let trk = keyframe(t, delay: 1.9, duration: 1.6)
                Text("BY RAEMULAN LANDS")
                    .font(Typo.fixedManrope(12, .extrabold))
                    .tracking(mix(12, 0.34 * 12, trk))
                    .foregroundStyle(Palette.muted)
                    .opacity(trk)
                    .fixedSize()
                    .padding(.top, 14)
                Text("One arch is a roofline. Together, they make a family.")
                    .font(Typo.fixedManrope(14)).foregroundStyle(Palette.subtle)
                    .modifier(BodyIn(t: t, delay: 2.3))
                    .padding(.top, 26)
            }
            .frame(width: 390)
            .offset(y: 462)
            .zIndex(6)
        case .discover:
            sceneText(.discover, eyebrow: "Tuklasin · Discover", body: "Explore Pasinaya, Pagsikat and Pagsibol communities — slides, galleries and prices in one place.", t: t)
        case .scan:
            sceneText(.scan, eyebrow: "I-scan · Scan", body: "Scan the QR from your Homeful seller to open your booking or payment — nothing to retype.", t: t)
        case .track:
            sceneText(.track, eyebrow: "Subaybayan · Track", body: "Upload requirements, see when they’re reviewed and accepted, and get help without a call.", t: t)
        case .ready:
            readyText(t)
        case nil:
            EmptyView()
        }
    }

    private func sceneText(_ s: OnboardingScene, eyebrow: String, body: String, t: Double) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: eyebrow, t: t, delay: 0.15)
            Headline(scene: s, size: 38, t: t, base: 0.38, step: 0.075, alignment: .leading)
                .padding(.top, 12)
            Text(body)
                .font(Typo.fixedManrope(15)).foregroundStyle(Palette.muted).lineSpacing(15 * 0.3)
                .fixedSize(horizontal: false, vertical: true)
                .modifier(BodyIn(t: t, delay: 0.75))
                .padding(.top, 12)
        }
        .frame(width: 342, alignment: .leading)
        .offset(x: 24, y: 540)
        .zIndex(6)
    }

    private func readyText(_ t: Double) -> some View {
        VStack(spacing: 0) {
            Eyebrow(text: "Handa ka na? · Ready?", t: t, delay: 1.2)
            Headline(scene: .ready, size: 40, t: t, base: 1.3, step: 0.08, alignment: .center)
                .padding(.top, 12)
            Text("Create an account to save homes, book with your seller and track your application.")
                .font(Typo.fixedManrope(15)).foregroundStyle(Palette.muted).lineSpacing(15 * 0.3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .modifier(BodyIn(t: t, delay: 1.7))
                .padding(.top, 12)
            VStack(spacing: 10) {
                PrimaryButton("Create account", icon: .arrowUpRight, height: 58, chipSize: 46) { router.go(.signup, state: state) }
                Button { router.go(.login, state: state) } label: {
                    Text("I already have an account")
                        .font(Typo.fixedManrope(15, .bold)).foregroundStyle(Palette.text)
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Capsule().fill(Color.white(0.06)))
                        .overlay(Capsule().strokeBorder(Color.white(0.15), lineWidth: 1))
                }
                .pressable()
            }
            .modifier(BodyIn(t: t, delay: 1.9))
            .padding(.top, 26)
        }
        .frame(width: 342)
        .offset(x: 24, y: 438)
        .zIndex(6)
    }

    // MARK: Controls

    private func controls(_ now: Date) -> some View {
        let elapsed = now.timeIntervalSince(changedAt)
        return HStack(spacing: 18) {
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { j in
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white(0.18))
                            if j < index {
                                Capsule().fill(Color.white)
                            } else if j == index, let d = OnboardingScene(rawValue: j)?.duration {
                                Capsule().fill(Palette.yellow).frame(width: geo.size.width * min(1, max(0, (scene == nil ? 0 : elapsed) / d)))
                            }
                        }
                    }
                    .frame(height: 4)
                }
            }
            .accessibilityLabel("Onboarding progress")

            Button { goTo(OnboardingScene(rawValue: index + 1) ?? .ready) } label: {
                ZStack {
                    PulseRing(color: Palette.yellow.opacity(0.5), lineWidth: 2, to: 1.5).frame(width: 80, height: 80)
                    Circle().fill(Palette.yellow).frame(width: 68, height: 68)
                        .shadow(color: Palette.yellow.opacity(0.5), radius: 14, y: 16)
                    IconView(.arrowRight, size: 26).foregroundStyle(Palette.ink)
                }
                .frame(width: 68, height: 68)
            }
            .pressable()
            .accessibilityLabel("Next")
        }
        .frame(width: 346)
        .offset(x: 24, y: 844 - 40 - 68)
        .zIndex(10)
    }
}

// MARK: - Text effects

/// `.eb`: eyebrow tracking in from .6em to .16em with blur, 1.2s.
private struct Eyebrow: View {
    let text: String
    let t: Double
    let delay: Double

    var body: some View {
        let p = keyframe(t, delay: delay, duration: 1.2)
        Text(text.uppercased())
            .font(Typo.fixedManrope(12, .extrabold))
            .tracking(mix(0.6, 0.16, p) * 12)
            .foregroundStyle(Palette.yellow)
            .opacity(p)
            .blur(radius: 4 * (1 - p))
            .fixedSize()
    }
}

/// `.bd`: translateY 14 + blur 5 → 0, 1s.
private struct BodyIn: ViewModifier {
    let t: Double
    let delay: Double
    func body(content: Content) -> some View {
        let p = keyframe(t, delay: delay, duration: 1)
        content.opacity(p).offset(y: 14 * (1 - p)).blur(radius: 5 * (1 - p))
    }
}

/// Headline words rising from behind a mask (`.wm` / `.wi`), staggered, with the accent word in yellow.
private struct Headline: View {
    let scene: OnboardingScene
    let size: CGFloat
    let t: Double
    let base: Double
    let step: Double
    let alignment: HorizontalAlignment

    var body: some View {
        let words = OnboardingGeometry.titles[scene] ?? []
        let accent = OnboardingGeometry.accent[scene]
        FlowLayout(spacing: 0.24 * size, lineSpacing: -0.22 * size, alignment: alignment) {
            ForEach(words.indices, id: \.self) { j in
                WordReveal(word: words[j], size: size, weight: .semibold, color: words[j] == accent ? Palette.yellow : Palette.text,
                           t: t, delay: base + Double(j) * step)
            }
        }
        .frame(width: 342, alignment: alignment == .center ? .center : .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(words.joined(separator: " "))
    }
}

private struct WordReveal: View {
    let word: String
    let size: CGFloat
    let weight: Typo.Weight
    let color: Color
    let t: Double
    let delay: Double

    var body: some View {
        // wiA: translateY 115% rotate 7deg blur 6 → none, 1.05s cubic-bezier(.16,1,.3,1)
        let p = keyframe(t, delay: delay, duration: 1.05, curve: CubicBezier(0.16, 1, 0.3, 1))
        let h = size * 1.18
        Text(word)
            .font(Typo.fixedOutfit(size, weight))
            .tracking(-0.035 * size)
            .foregroundStyle(color)
            .fixedSize()
            .opacity(p)
            .rotationEffect(.degrees(7 * (1 - p)), anchor: .bottomLeading)
            .offset(y: h * 1.15 * (1 - p))
            .blur(radius: 6 * (1 - p))
            .padding(.bottom, size * 0.1)
            .clipped()
    }
}

/// Light sweep that crosses the canvas on each scene change (1.6s cubic-bezier(.6,0,.2,1)).
private struct Sweep: View {
    let t: Double
    var body: some View {
        let p = keyframe(t, delay: 0, duration: 1.6, curve: CubicBezier(0.6, 0, 0.2, 1))
        let w: CGFloat = 390 * 2.2
        LinearGradient(stops: [
            .init(color: .white(0), location: 0.42),
            .init(color: .white(0.09), location: 0.5),
            .init(color: Palette.yellow.opacity(0.06), location: 0.53),
            .init(color: .white(0), location: 0.61),
        ], startPoint: UnitPoint(x: 0.02, y: 0.4), endPoint: UnitPoint(x: 0.98, y: 0.6))
        .frame(width: w, height: 844 * 1.2)
        .offset(x: -390 * 0.6 + w * CGFloat(mix(-0.45, 0.45, p)), y: -84.4)
        .opacity(p >= 1 ? 0 : 1)
        .allowsHitTesting(false)
    }
}

#Preview {
    OnboardingView().environment(AppState.preview).environment(AppRouter())
}
