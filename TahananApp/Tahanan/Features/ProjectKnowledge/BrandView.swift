import SwiftUI

struct BrandView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    let brandIndex: Int

    private var brand: Brand? { state.brands.indices.contains(brandIndex) ? state.brands[brandIndex] : state.brands.first }

    var body: some View {
        if let brand {
            GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    hero(brand, topInset: geo.safeAreaInsets.top)
                    content(brand)
                        .padding(.horizontal, Spacing.gutter)
                        .padding(.top, 8)
                        .padding(.bottom, 60)
                }
            }
            .ignoresSafeArea(edges: .top)
            }
        }
    }

    private func hero(_ b: Brand, topInset: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            Photo(name: b.image, kenBurns: true)
            LinearGradient(stops: [
                .init(color: Palette.night.opacity(0.45), location: 0),
                .init(color: Palette.night.opacity(0), location: 0.26),
                .init(color: Palette.night.opacity(0.2), location: 0.55),
                .init(color: Palette.night, location: 1),
            ], startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 0) {
                StatusPill(text: b.product, tone: .custom(bg: Palette.yellow, fg: Palette.ink)).rise()
                Text(b.name).h1(44).padding(.top, 12).rise(1)
                HStack(spacing: 6) {
                    IconView(.pin, size: 15)
                    Text(b.heroLocationLabel).font(Typo.manrope(14, .semibold))
                }
                .foregroundStyle(Palette.soft)
                .padding(.top, 8)
                .rise(2)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .frame(height: 440)
        .clipped()
        .overlay(alignment: .top) {
            HStack {
                IconButton(.arrowLeft, label: "Back", background: Palette.night.opacity(0.5), blur: true) { router.go(.home, state: state) }
                Spacer()
                // TODO: API — saved homes (no saved list in the design yet)
                IconButton(.heart, label: "Save", background: Palette.night.opacity(0.5), blur: true) {}
            }
            .padding(.horizontal, 20)
            .padding(.top, topInset)
        }
    }

    private func content(_ b: Brand) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                stat("STARTS AT", b.from, color: Palette.yellow)
                stat("MIN. GMI", b.gmi)
                stat("MONTHLY", b.monthly)
            }
            .rise(3)

            Text(b.description)
                .font(Typo.manrope(15)).foregroundStyle(Palette.muted).lineSpacing(15 * 0.35)
                .padding(.top, 18)
                .rise(4)

            HStack(alignment: .firstTextBaseline) {
                Text("Choose a location").sectionTitle()
                Spacer()
                Text("Tap to view slides").font(Typo.manrope(13, .bold)).foregroundStyle(Palette.subtle)
            }
            .padding(.top, 26)
            .rise(5)

            VStack(spacing: 10) {
                ForEach(Array(b.locations.enumerated()), id: \.offset) { i, loc in
                    Button { router.go(.location(brand: brandIndex, location: i), state: state) } label: {
                        HStack(spacing: 14) {
                            Photo(name: b.image)
                                .frame(width: 58, height: 70)
                                .clipShape(ArchShape(bottomRadius: 12))
                            VStack(alignment: .leading, spacing: 0) {
                                Text(loc.name).font(Typo.manrope(15, .extrabold)).foregroundStyle(Palette.text)
                                Text(loc.barangay).font(Typo.manrope(12)).foregroundStyle(Palette.subtle).padding(.top, 2)
                                HStack(spacing: 6) {
                                    StatusPill(text: "\(loc.floorArea) sqm", tone: .muted, height: 22)
                                    StatusPill(text: "TCP \(loc.tcp)", tone: .reviewed, height: 22)
                                }
                                .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            IconView(.chevronRight).foregroundStyle(Palette.muted)
                        }
                        .padding(.vertical, 10).padding(.leading, 10).padding(.trailing, 14)
                        .glass(22)
                        .contentShape(Rectangle())
                    }
                    .pressable()
                }
            }
            .padding(.top, 12)
            .rise(6)
        }
    }

    private func stat(_ label: String, _ value: String, color: Color = Palette.text) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(Typo.manrope(10, .extrabold)).tracking(0.6).foregroundStyle(Palette.subtle)
            Text(value).font(Typo.outfit(17, .bold)).foregroundStyle(color).lineLimit(1).minimumScaleFactor(0.7)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(18)
    }
}

#Preview {
    BrandView(brandIndex: 0).environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
