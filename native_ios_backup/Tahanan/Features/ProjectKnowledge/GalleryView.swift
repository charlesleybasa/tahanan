import SwiftUI

/// Location gallery with filter chips; empty categories show the "Upload in admin" placeholder.
struct GalleryView: View {
    let brand: Brand
    let location: Location
    let onBack: () -> Void
    @State private var filter = "All"

    private static let filters = ["All", "Facade", "Amenities", "Interior", "Nearby", "Site map"]

    private struct Tile: Identifiable {
        let label: String
        let image: String?
        let span: Int
        let category: String
        var id: String { label }
    }

    private var tiles: [Tile] {
        // TODO: API — gallery items per location come from the CMS (admin uploads).
        [
            Tile(label: "Facade", image: brand.image, span: 2, category: "Facade"),
            Tile(label: "Interior", image: "photoInterior", span: 1, category: "Interior"),
            Tile(label: "Amenities", image: nil, span: 1, category: "Amenities"),
            Tile(label: "Streetscape", image: brand.streetImage, span: 1, category: "Facade"),
            Tile(label: "Nearby destinations", image: nil, span: 2, category: "Nearby"),
            Tile(label: "Sales map", image: nil, span: 1, category: "Site map"),
        ]
    }

    var body: some View {
        ScreenScroll {
            HStack(spacing: 10) {
                BackButton(label: "Back to slides", action: onBack)
                VStack(alignment: .leading, spacing: 0) {
                    Text(brand.name).font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text)
                    Text("\(location.name) · Gallery").font(Typo.manrope(12)).foregroundStyle(Palette.muted)
                }
                Spacer()
                Button(action: onBack) {
                    HStack(spacing: 8) {
                        IconView(.play, size: 14)
                        Text("Slides").font(Typo.manrope(13, .extrabold))
                    }
                    .foregroundStyle(Palette.text)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Capsule().fill(Color.white(0.06)))
                    .overlay(Capsule().strokeBorder(Color.white(0.18), lineWidth: 1))
                }
                .pressable()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.filters, id: \.self) { f in
                        FilterChip(title: f, selected: filter == f) { filter = f }
                    }
                }
            }
            .contentMargins(.horizontal, Spacing.gutter, for: .scrollContent)
            .padding(.horizontal, -Spacing.gutter)
            .padding(.top, 18)
            .rise(1)

            grid.padding(.top, 16).rise(2)
        }
        .background(Palette.night.ignoresSafeArea())
    }

    @ViewBuilder
    private var grid: some View {
        if filter == "All" {
            // CSS grid with 150pt rows: Facade spans 2 rows on the left, Nearby spans 2 on the right.
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 10) { tile(tiles[0]); tile(tiles[3]); tile(tiles[5]) }
                VStack(spacing: 10) { tile(tiles[1]); tile(tiles[2]); tile(tiles[4]) }
            }
        } else {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(tiles.filter { $0.category == filter }) { t in tile(t, forceSpan: 1) }
            }
        }
    }

    private func tile(_ t: Tile, forceSpan: Int? = nil) -> some View {
        let span = CGFloat(forceSpan ?? t.span)
        return ZStack(alignment: .bottomLeading) {
            Palette.panel
            if let img = t.image {
                Photo(name: img)
            } else {
                ZStack {
                    DiagonalStripes()
                    VStack(spacing: 6) {
                        IconView(.image, size: 26)
                        Text("Upload in admin").font(Typo.manrope(11, .extrabold))
                    }
                    .foregroundStyle(Palette.ringIdle)
                }
            }
            StatusPill(text: t.label, tone: .custom(bg: Palette.deep.opacity(0.65), fg: .white))
                .background(Capsule().fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                .padding(10)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 150 * span + 10 * (span - 1))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.white(0.08), lineWidth: 1))
    }
}

/// repeating-linear-gradient(135deg, rgba(255,255,255,.03) 0 10px, transparent 10px 20px)
private struct DiagonalStripes: View {
    var body: some View {
        Canvas { ctx, size in
            let period: CGFloat = 20 * sqrt(2)
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                var p = Path()
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x + period / 2, y: 0))
                p.addLine(to: CGPoint(x: x + period / 2 + size.height, y: size.height))
                p.addLine(to: CGPoint(x: x + size.height, y: size.height))
                p.closeSubpath()
                ctx.fill(p, with: .color(.white.opacity(0.03)))
                x += period
            }
        }
    }
}
