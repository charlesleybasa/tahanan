import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router

    var body: some View {
        ScreenScroll(bottom: Spacing.tabBarClearance) {
            header.rise()

            (Text("Find your\n") + Text("tahanan.").foregroundColor(Palette.yellow))
                .h1(42)
                .padding(.top, 26)
                .rise(1)

            HStack(alignment: .firstTextBaseline) {
                Text("Explore communities").sectionTitle()
                Spacer()
                Text("\(state.brands.count) brands").font(Typo.manrope(13, .bold)).foregroundStyle(Palette.subtle)
            }
            .padding(.top, 26)
            .rise(2)

            carousel
                .padding(.top, 14)
                .padding(.horizontal, -Spacing.gutter)
                .rise(3)

            JourneyCard(todo: state.todoCount, unit: state.profile?.unit) { router.go(.application, state: state) }
                .padding(.top, 22)
                .rise(4)

            Button { state.sheet = .link } label: {
                RowLayout {
                    IconTile(icon: .link, tint: Palette.submittedText, background: Palette.blue.opacity(0.25))
                    RowText(title: "Link an existing account", subtitle: "Bought with Homeful before? See it here.")
                    IconView(.chevronRight).foregroundStyle(Palette.muted)
                }
                .glass(22)
            }
            .buttonStyle(.plain)
            .padding(.top, 14)
            .rise(5)

            HStack(alignment: .firstTextBaseline) {
                Text("Transactions").sectionTitle()
                Spacer()
                Text("See all").font(Typo.manrope(13, .extrabold)).foregroundStyle(Palette.yellow).frame(height: 44)
            }
            .padding(.top, 26)
            .rise(6)

            GlassCard {
                ForEach(Array(state.transactions.enumerated()), id: \.element.id) { i, tx in
                    if i > 0 { RowDivider() }
                    TransactionRow(tx: tx)
                }
            }
            .padding(.top, 6)
            .rise(7)
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 12) {
                InitialsAvatar(initials: state.profile?.initials ?? "MS")
                    .overlay(Circle().strokeBorder(Palette.yellow.opacity(0.8), lineWidth: 2))
                VStack(alignment: .leading, spacing: 0) {
                    Text("Magandang umaga,").font(Typo.manrope(13, .semibold)).foregroundStyle(Palette.muted)
                    Text(state.profile?.firstName ?? "Maria").font(Typo.outfit(19, .semibold)).tracking(-0.19).foregroundStyle(Palette.text)
                }
            }
            Spacer()
            // TODO: API — notifications inbox (no destination in the design yet)
            IconButton(.bell, label: "Notifications") {}
                .overlay(alignment: .topTrailing) {
                    Circle().fill(Palette.yellow).frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Palette.panel, lineWidth: 2))
                        .padding(.top, 10).padding(.trailing, 11)
                        .allowsHitTesting(false)
                }
        }
    }

    private var carousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 14) {
                ForEach(Array(state.brands.enumerated()), id: \.element.id) { i, brand in
                    BrandArchCard(brand: brand) { router.go(.brand(i), state: state) }
                }
            }
            .scrollTargetLayout()
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
        .contentMargins(.horizontal, Spacing.gutter, for: .scrollContent)
        .scrollTargetBehavior(.viewAligned)
    }
}

/// 252 × 340 arch card with Ken Burns photo, location pill, name, "STARTS AT" price and arrow chip.
struct BrandArchCard: View {
    let brand: Brand
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Photo(name: brand.image, kenBurns: true)
                LinearGradient(stops: [
                    .init(color: Palette.night.opacity(0), location: 0.3),
                    .init(color: Palette.night.opacity(0.55), location: 0.55),
                    .init(color: Palette.night.opacity(0.96), location: 1),
                ], startPoint: .top, endPoint: .bottom)

                VStack {
                    StatusPill(text: brand.carouselLocationLabel, tone: .custom(bg: Palette.night.opacity(0.6), fg: Palette.text), icon: .pin)
                        .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                        .overlay(Capsule().strokeBorder(Color.white(0.14), lineWidth: 1))
                        .padding(.top, 74)
                    Spacer()
                    VStack(alignment: .leading, spacing: 10) {
                        Text(brand.name)
                            .font(Typo.outfit(24, .semibold)).tracking(-0.48)
                            .foregroundStyle(Palette.text)
                            .multilineTextAlignment(.leading)
                        HStack(alignment: .bottom) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("STARTS AT").font(Typo.manrope(11, .bold)).foregroundStyle(Palette.muted)
                                Text(brand.from).font(Typo.outfit(20, .bold)).foregroundStyle(Palette.yellow)
                            }
                            Spacer()
                            Circle().fill(Palette.yellow).frame(width: 44, height: 44)
                                .overlay(IconView(.arrowUpRight).foregroundStyle(Palette.ink))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
                }
            }
            .frame(width: 252, height: 340)
            .background(Palette.panel)
            .clipShape(ArchShape(bottomRadius: 28))
            .overlay(ArchShape(bottomRadius: 28).stroke(Color.white(0.14), lineWidth: 1))
            .shadow(color: .black.opacity(0.6), radius: 24, y: 30)
        }
        .pressable()
        .accessibilityLabel("\(brand.name), starts at \(brand.from)")
    }
}

/// The yellow "My home journey" card: family → house track across five stages.
struct JourneyCard: View {
    let todo: Int
    let unit: BuyerProfile.Unit?
    let action: () -> Void
    @State private var grow = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("MY HOME JOURNEY").font(Typo.manrope(12, .extrabold)).tracking(1.2)
                Spacer()
                Text(unit?.code ?? "CAV-PHC-03-B12-L07")
                    .font(Typo.mono(11, .semibold))
                    .padding(.vertical, 5).padding(.horizontal, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Palette.ink.opacity(0.1)))
            }
            Text("Documents in review")
                .font(Typo.outfit(27, .semibold)).tracking(-0.675)
                .padding(.top, 12)
            Text("\(unit?.brandName ?? "Pasinaya Homes") · \(unit?.location ?? "Ternate, Cavite")")
                .font(Typo.manrope(13, .semibold)).opacity(0.78)
                .padding(.top, 4)

            HStack(spacing: 10) {
                endCap(.family)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Palette.ink.opacity(0.16))
                        StripesFill().frame(width: grow ? geo.size.width * 0.38 : 0).clipShape(Capsule())
                        HStack {
                            ForEach(0..<5, id: \.self) { i in
                                Circle().fill(i < 2 ? Palette.yellow : Palette.ink).frame(width: 8, height: 8)
                                if i < 4 { Spacer(minLength: 0) }
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                }
                .frame(height: 12)
                endCap(.home)
            }
            .padding(.top, 18)

            HStack {
                ForEach(["Booked", "Docs", "Pre-qual", "Loan", "Move-in"], id: \.self) { s in
                    Text(s.uppercased()).font(Typo.manrope(10, .extrabold)).tracking(0.4)
                    if s != "Move-in" { Spacer(minLength: 0) }
                }
            }
            .opacity(0.7)
            .padding(.top, 8)
            .padding(.horizontal, 50)

            Button(action: action) {
                HStack {
                    Text("Next: upload \(todo) document\(todo == 1 ? "" : "s")")
                        .font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text)
                    Spacer()
                    Circle().fill(Palette.yellow).frame(width: 40, height: 40)
                        .overlay(IconView(.arrowRight, size: 18).foregroundStyle(Palette.ink))
                }
                .padding(.leading, 20).padding(.trailing, 6)
                .frame(height: 52)
                .background(Capsule().fill(Palette.ink))
            }
            .pressable()
            .padding(.top, 16)
        }
        .foregroundStyle(Palette.ink)
        .padding(20)
        .background(
            ZStack(alignment: .topTrailing) {
                Palette.yellow
                ArchShape(bottomRadius: 0).fill(Color.white(0.22)).frame(width: 170, height: 200).offset(x: 40, y: -60)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onAppear {
            // .upbar: width 0 → 38%, 1.6s cubic-bezier(.4,0,.2,1), .6s delay
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 1.6).delay(0.6)) { grow = true }
        }
    }

    private func endCap(_ icon: Icon) -> some View {
        Circle().fill(Palette.ink).frame(width: 46, height: 46)
            .overlay(IconView(icon, size: 22).foregroundStyle(Palette.yellow))
    }
}

struct TransactionRow: View {
    let tx: Transaction

    var body: some View {
        RowLayout {
            switch tx.icon {
            case .wallet: IconTile(icon: .wallet, tint: Palette.acceptedText, background: Palette.green.opacity(0.2))
            case .home: IconTile(icon: .home, tint: Palette.submittedText, background: Palette.blue.opacity(0.24))
            case .calendar: IconTile(icon: .calendar, tint: Palette.muted, background: .white(0.07))
            }
            RowText(title: tx.title, subtitle: tx.subtitle, titleSize: 14, subtitleSize: 12, subtitleColor: Palette.subtle, subtitleMono: tx.mono)
            if let amount = tx.amount {
                VStack(alignment: .trailing, spacing: 4) {
                    Text(amount).font(Typo.outfit(15, .bold)).foregroundStyle(Palette.text)
                    StatusPill(text: tx.status, tone: tone, height: 22)
                }
            } else {
                StatusPill(text: tx.status, tone: tone)
            }
        }
    }

    private var tone: PillTone {
        switch tx.tone {
        case .acc: return .accepted
        case .sub: return .submitted
        case .mut: return .muted
        }
    }
}

#Preview {
    HomeView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
