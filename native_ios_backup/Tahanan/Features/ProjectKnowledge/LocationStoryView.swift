import SwiftUI

enum SlideKind: Int, CaseIterable { case hero, video, map, home, invest }

/// Full-screen location stories: Hero, Video, Site plan, The home, Investment.
/// Auto-advances every 6s with a yellow progress bar; tap left/right to go back/forward, hold to pause.
struct LocationStoryView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    let brandIndex: Int
    let locationIndex: Int

    @State private var slide = 0
    @State private var showGallery = false
    /// Progress of the running segment, 0…1.
    @State private var progress: Double = 0
    @State private var paused = false
    @State private var lastTick = Date()
    @State private var pressStart: Date?

    private var brand: Brand? { state.brands.indices.contains(brandIndex) ? state.brands[brandIndex] : state.brands.first }
    private var location: Location? {
        guard let b = brand else { return nil }
        return b.locations.indices.contains(locationIndex) ? b.locations[locationIndex] : b.locations.first
    }
    private var kind: SlideKind { SlideKind(rawValue: slide) ?? .hero }

    var body: some View {
        ZStack {
            Palette.deep.ignoresSafeArea()
            if let brand, let location {
                if showGallery {
                    GalleryView(brand: brand, location: location) { showGallery = false; restart() }
                        .transition(.screen)
                } else {
                    story(brand, location)
                }
            }
        }
    }

    private func restart() {
        progress = 0
        lastTick = Date()
    }

    private func setSlide(_ i: Int) {
        slide = max(0, min(SlideKind.allCases.count - 1, i))
        restart()
    }

    // MARK: Story

    private func story(_ b: Brand, _ l: Location) -> some View {
        ZStack {
            slideImage(b)
            LinearGradient(stops: [
                .init(color: Palette.deep.opacity(0.7), location: 0),
                .init(color: Palette.deep.opacity(0), location: 0.22),
                .init(color: Palette.deep.opacity(0.1), location: 0.48),
                .init(color: Palette.deep.opacity(0.92), location: 0.78),
                .init(color: Palette.deep, location: 1),
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            if kind == .map {
                CSSRadialGradient(rx: 0.9, ry: 0.6, cx: 0.5, cy: 0.3, stops: [
                    .init(color: Color(hex: 0x12305E), location: 0),
                    .init(color: Palette.deep, location: 0.75),
                ])
                .ignoresSafeArea()
                .fadeIn()
            }

            tapZones

            if kind == .video { playButton }
            if kind == .map {
                VStack {
                    SitePlanCard().padding(.horizontal, 20).padding(.top, 128 - 54).rise(1)
                    Spacer()
                }
                .id(slide)
            }

            VStack(spacing: 0) {
                segments
                topBar(b, l).padding(.top, 12)
                Spacer()
                caption(b, l)
                    .id(slide)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 0)
            }
        }
        .onReceive(Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()) { now in
            let dt = now.timeIntervalSince(lastTick)
            lastTick = now
            guard !paused else { return }
            progress += dt / 6
            if progress >= 1 {
                if slide < SlideKind.allCases.count - 1 { setSlide(slide + 1) } else { progress = 1 }
            }
        }
    }

    @ViewBuilder
    private func slideImage(_ b: Brand) -> some View {
        switch kind {
        case .map:
            EmptyView()
        case .invest:
            Photo(name: b.image, kenBurns: true).blur(radius: 3).brightness(-0.45).ignoresSafeArea().id(slide).transition(.opacity).fadeIn()
        case .video:
            Photo(name: b.streetImage, kenBurns: true).ignoresSafeArea().id(slide).fadeIn()
        case .home:
            Photo(name: "photoInterior", kenBurns: true).ignoresSafeArea().id(slide).fadeIn()
        case .hero:
            Photo(name: b.image, kenBurns: true).ignoresSafeArea().id(slide).fadeIn()
        }
    }

    /// Tap zones between 120pt from the top and 300pt from the bottom: left 35% = back, right 65% = forward.
    /// Holding anywhere in the zone pauses the story.
    private var tapZones: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if pressStart == nil { pressStart = Date(); paused = true }
                        }
                        .onEnded { v in
                            let held = Date().timeIntervalSince(pressStart ?? Date())
                            pressStart = nil
                            paused = false
                            lastTick = Date()
                            guard held < 0.3 else { return }
                            if v.location.x < geo.size.width * 0.35 { setSlide(slide - 1) }
                            else if slide < SlideKind.allCases.count - 1 { setSlide(slide + 1) }
                        }
                )
                .padding(.top, 120 - 54)
                .padding(.bottom, 300 - 34)
        }
        .accessibilityElement()
        .accessibilityLabel("Slide \(slide + 1) of 5")
        .accessibilityAdjustableAction { dir in
            switch dir {
            case .increment: setSlide(slide + 1)
            case .decrement: setSlide(slide - 1)
            @unknown default: break
            }
        }
    }

    private var playButton: some View {
        ZStack {
            PulseRing(color: .white(0.7), lineWidth: 2).frame(width: 92, height: 92)
            // TODO: API — project video URL from the CMS slide
            Circle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark).frame(width: 92, height: 92)
                .overlay(Circle().fill(Color.white(0.18)))
                .overlay(Circle().strokeBorder(Color.white(0.09), lineWidth: 1))
                .overlay(IconView(.play, size: 34).foregroundStyle(.white))
                .accessibilityLabel("Play project video")
        }
        .pop()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 300 - 54)
        .id(slide)
    }

    private var segments: some View {
        HStack(spacing: 4) {
            ForEach(SlideKind.allCases, id: \.self) { k in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white(0.25))
                        if k.rawValue < slide {
                            Capsule().fill(.white)
                        } else if k.rawValue == slide {
                            Capsule().fill(Palette.yellow).frame(width: geo.size.width * min(1, progress))
                        }
                    }
                }
                .frame(height: 3)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 52 - 54 + 2)
    }

    private func topBar(_ b: Brand, _ l: Location) -> some View {
        HStack(spacing: 10) {
            IconButton(.close, label: "Close", background: Palette.deep.opacity(0.45), blur: true) {
                router.go(.brand(brandIndex), state: state)
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(b.name).font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text)
                Text(l.name).font(Typo.manrope(12)).foregroundStyle(Palette.soft)
            }
            Spacer()
            Button {
                withAnimation(Motion.screen) { showGallery = true }
            } label: {
                HStack(spacing: 8) {
                    IconView(.grid, size: 16)
                    Text("Gallery").font(Typo.manrope(13, .extrabold))
                }
                .foregroundStyle(Palette.text)
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                .background(Capsule().fill(Palette.deep.opacity(0.45)))
                .overlay(Capsule().strokeBorder(Color.white(0.2), lineWidth: 1))
            }
            .pressable()
        }
        .padding(.horizontal, 16)
    }

    // MARK: Captions

    @ViewBuilder
    private func caption(_ b: Brand, _ l: Location) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            switch kind {
            case .hero:
                Text("Welcome to").eyebrow().rise()
                Text(b.name).h1(46).padding(.top, 10).rise(1)
                HStack(spacing: 6) {
                    IconView(.pin, size: 16)
                    Text("\(l.barangay), \(l.name)").font(Typo.manrope(16))
                }
                .foregroundStyle(Palette.soft)
                .padding(.top, 10).rise(2)
                HStack(spacing: 8) {
                    StatusPill(text: b.product, tone: .custom(bg: .white(0.12), fg: .white), height: 32, horizontalPadding: 12)
                    StatusPill(text: "TCP \(l.tcp)", tone: .custom(bg: Palette.yellow, fg: Palette.ink), height: 32, horizontalPadding: 12)
                }
                .padding(.top, 18).rise(3)
            case .video:
                Text("Project video").eyebrow().rise()
                Text("Take the tour").h1(42).padding(.top, 10).rise(1)
                Text("Walk the streets of \(b.name) \(l.name) before you visit.")
                    .font(Typo.manrope(16)).foregroundStyle(Palette.soft).lineSpacing(8).padding(.top, 10).rise(2)
            case .map:
                Text("Site plan").eyebrow().rise()
                Text("Find your lot").h1(42).padding(.top, 10).rise(1)
                Text("Yellow lots are open. Your seller confirms the final lot when you book.")
                    .font(Typo.manrope(16)).foregroundStyle(Palette.soft).lineSpacing(8).padding(.top, 10).rise(2)
            case .home:
                Text("The home").eyebrow().rise()
                Text(b.product).h1(40).padding(.top, 10).rise(1)
                HStack(spacing: 8) {
                    areaTile("FLOOR AREA", l.floorArea)
                    areaTile("LOT AREA", l.lotArea)
                }
                .padding(.top, 16).rise(2)
            case .invest:
                Text("Investment").eyebrow().rise()
                (Text("Own it from \(l.monthlyAmortization)") + Text("/mo").font(Typo.outfit(20, .semibold)).foregroundColor(Palette.muted))
                    .h1(38).padding(.top, 10).rise(1)
                VStack(spacing: 0) {
                    SummaryLine(key: "Total contract price", value: l.tcp)
                    SummaryLine(key: "Consultation fee", value: "₱10,000")
                    SummaryLine(key: "Downpayment", value: "None needed", valueColor: Palette.acceptedText)
                    SummaryLine(key: "Required GMI", value: l.gmi, divider: false)
                }
                .padding(.vertical, 4).padding(.horizontal, 16)
                .glass(22, fill: .white(0.06))
                .padding(.top, 16).rise(2)
                HStack(spacing: 10) {
                    PrimaryButton("Scan seller QR", icon: .scan) { router.go(.scan, state: state) }
                    IconButton(.help, label: "Ask a question", size: 56, iconSize: 22) { router.go(.newTicket, state: state) }
                }
                .padding(.top, 14).rise(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func areaTile(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(Typo.manrope(11, .extrabold)).foregroundStyle(Palette.muted)
            (Text("\(value) ").font(Typo.outfit(26, .semibold)).foregroundColor(Palette.text)
                + Text("sqm").font(Typo.outfit(14, .semibold)).foregroundColor(Palette.muted))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(18, fill: Palette.deep.opacity(0.5), blur: true)
    }
}

/// The drawn lot map: four blocks of 18 lots (open / reserved / sold), main road, highlighted Block 12 · Lot 7.
struct SitePlanCard: View {
    private enum Lot { case open, reserved, sold, mine }

    private static let blocks: [(String, String)] = [
        ("BLOCK 10", "YBYBSYYSYYSBSBSYSS"),
        ("BLOCK 12", "BSSYSBHYSBSSSSYSBS"),
        ("BLOCK 14", "SYYYSBSYBYYBBSSSSS"),
        ("BLOCK 16", "SYSSSBSYSBYYSSYSYY"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                block(0)
                block(1)
                Text("MAIN ROAD")
                    .font(Typo.manrope(10, .extrabold)).tracking(1.4).foregroundStyle(Palette.subtle)
                    .frame(maxWidth: .infinity).frame(height: 26)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white(0.06)))
                block(2)
                block(3)
            }
            .overlay(alignment: .topLeading) {
                Text("Block 12 · Lot 7")
                    .font(Typo.manrope(11, .extrabold)).foregroundStyle(Palette.ink)
                    .padding(.vertical, 6).padding(.horizontal, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(.white))
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 10)
                    .fixedSize()
                    .offset(x: 150, y: 72)
            }

            HStack(spacing: 14) {
                LegendDot(color: Palette.yellow, label: "Open", size: 10, radius: 3)
                LegendDot(color: Palette.blue, label: "Reserved", size: 10, radius: 3)
                LegendDot(color: .white(0.2), label: "Sold", size: 10, radius: 3)
            }
            .font(Typo.manrope(11, .bold))
            .foregroundStyle(Palette.muted)
            .padding(.top, 16)
        }
        .padding(18)
        .glass(26, fill: Color(hex: 0x0D1C38, alpha: 0.7), blur: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Site plan. Your lot is Block 12, Lot 7. Yellow lots are open, blue reserved, grey sold.")
    }

    private func block(_ i: Int) -> some View {
        let (name, lots) = Self.blocks[i]
        let cells = Array(lots)
        return VStack(alignment: .leading, spacing: 6) {
            Text(name).font(Typo.manrope(10, .extrabold)).tracking(0.8).foregroundStyle(Palette.subtle)
            Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                ForEach(0..<2, id: \.self) { r in
                    GridRow {
                        ForEach(0..<9, id: \.self) { c in
                            lot(cells[r * 9 + c])
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func lot(_ ch: Character) -> some View {
        let shape = RoundedRectangle(cornerRadius: 4)
        switch ch {
        case "Y": shape.fill(Palette.yellow.opacity(0.85)).frame(height: 22)
        case "B": shape.fill(Palette.blue).frame(height: 22)
        case "H":
            shape.fill(Palette.yellow).frame(height: 22)
                .overlay(shape.strokeBorder(.white, lineWidth: 2).padding(-2))
                .shadow(color: Palette.yellow.opacity(0.7), radius: 9)
                .overlay(PulseRing(color: Palette.yellow, lineWidth: 2, cornerRadius: 6).padding(-4))
        default: shape.fill(Color.white(0.14)).frame(height: 22)
        }
    }
}

#Preview {
    LocationStoryView(brandIndex: 0, locationIndex: 0).environment(AppState.preview).environment(AppRouter())
}
