import SwiftUI

// MARK: - Floating tab bar

enum MainTab: Hashable { case home, application, help, profile }

/// Glass pill (left/right 14, bottom 20, 74 tall, radius 37) with a raised yellow Scan button and pulsing ring.
struct FloatingTabBar: View {
    var selected: MainTab?
    var onSelect: (MainTab) -> Void
    var onScan: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            item(.home, icon: .home, title: "Tahanan", label: "Home")
            Spacer(minLength: 0)
            item(.application, icon: .document, title: "My docs", label: "My application")
            Spacer(minLength: 0)
            scanButton
            Spacer(minLength: 0)
            item(.help, icon: .help, title: "Help", label: "Help")
            Spacer(minLength: 0)
            item(.profile, icon: .person, title: "Profile", label: "Profile")
        }
        .padding(.horizontal, 8)
        .frame(height: 74)
        .background {
            RoundedRectangle(cornerRadius: 37, style: .continuous).fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
            RoundedRectangle(cornerRadius: 37, style: .continuous).fill(Color(hex: 0x0D1C38, alpha: 0.8))
        }
        .overlay(RoundedRectangle(cornerRadius: 37, style: .continuous).strokeBorder(Color.white(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.6), radius: 22, y: 24)
        .padding(.horizontal, 14)
    }

    private func item(_ tab: MainTab, icon: Icon, title: String, label: String) -> some View {
        Button { onSelect(tab) } label: {
            VStack(spacing: 4) {
                IconView(icon, size: 22)
                Text(title).font(Typo.manrope(11, .extrabold))
            }
            .foregroundStyle(selected == tab ? Palette.yellow : Palette.tabIdle)
            .frame(width: 62, height: 58)
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.25), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selected == tab ? [.isSelected] : [])
    }

    private var scanButton: some View {
        Button(action: onScan) {
            ZStack {
                PulseRing(color: Palette.yellow.opacity(0.55), lineWidth: 2)
                    .frame(width: 76, height: 76)
                Circle().fill(Palette.yellow)
                    .overlay(Circle().strokeBorder(Palette.ink, lineWidth: 5))
                    .frame(width: 66, height: 66)
                    .shadow(color: Palette.yellow.opacity(0.5), radius: 12, y: 14)
                IconView(.scan, size: 26).foregroundStyle(Palette.ink)
            }
            .frame(width: 66, height: 66)
        }
        .buttonStyle(PressStyle())
        .offset(y: -20)
        .accessibilityLabel("Scan QR")
    }
}

// MARK: - Toast

struct ToastData: Equatable {
    var id = UUID()
    var message: String
    var icon: Icon = .check
    var tint: Color = Palette.green
}

/// `.toast`: light capsule at top 56, toastA 2.4s (drop in, hold, fade up).
struct ToastView: View {
    let toast: ToastData

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSince(start)
            let p = min(max(t / 2.4, 0), 1)
            let (o, y) = frame(p)
            HStack(spacing: 10) {
                Circle().fill(toast.tint).frame(width: 28, height: 28)
                    .overlay(IconView(toast.icon, size: 16).foregroundStyle(.white))
                Text(toast.message).font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.ink).lineLimit(1)
            }
            .padding(.leading, 12)
            .padding(.trailing, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(Palette.text))
            .shadow(color: .black.opacity(0.5), radius: 16, y: 20)
            .opacity(o)
            .offset(y: y)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    @State private var start = Date()

    private func frame(_ p: Double) -> (Double, CGFloat) {
        let c = CubicBezier.standard
        if p < 0.12 { let k = c(p / 0.12); return (k, CGFloat(mix(-16, 0, k))) }
        if p < 0.82 { return (1, 0) }
        let k = c((p - 0.82) / 0.18)
        return (1 - k, CGFloat(mix(0, -10, k)))
    }
}

// MARK: - Bottom sheet

/// The prototype's sheet: scrim rgba(2,6,14,.62) + blur, panel #0F2142 radius 32, handle 44 × 5, sheetUp .55s.
struct BottomSheet<Content: View>: View {
    var onDismiss: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var shown = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0x02060E, alpha: 0.62))
                .background(.ultraThinMaterial.opacity(0.35))
                .ignoresSafeArea()
                .opacity(shown ? 1 : 0)
                .onTapGesture(perform: onDismiss)
                .accessibilityLabel("Close")
                .accessibilityAddTraits(.isButton)

            VStack(spacing: 0) {
                Capsule().fill(Color.white(0.2)).frame(width: 44, height: 5).padding(.bottom, 18)
                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 12)
            .padding(.horizontal, 22)
            .padding(.bottom, 34)
            .background(
                CornerBox(32, 32, 0, 0).fill(Palette.panel)
                    .overlay(alignment: .top) { CornerBox(32, 32, 0, 0).stroke(Color.white(0.12), lineWidth: 1).mask(alignment: .top) { Rectangle().frame(height: 33) } }
                    .ignoresSafeArea(edges: .bottom)
            )
            .offset(y: panelShown ? 0 : 900)
            .gesture(DragGesture().onEnded { v in if v.translation.height > 80 { onDismiss() } })
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4)) { shown = true }
            withAnimation(Motion.sheet()) { panelShown = true }
        }
    }

    @State private var panelShown = false
}

// MARK: - Decorative QR and scan corners

/// The 25 × 25 QR pattern from the design (decorative; real codes come from the camera).
struct DecorativeQR: View {
    static let rows = [
        "#######.##.#.##.#.#######", "#.....#.####.##...#.....#", "#.###.#..#.#.####.#.###.#", "#.###.#..#..#.###.#.###.#",
        "#.###.#..##.##..#.#.###.#", "#.....#.....#.##..#.....#", "#######.#.#.#.#.#.#######", "........#.#....#.........",
        "..#..##.#....##.#####.###", ".##.....###..####..####..", "....#.#...###.###########", "..####.#..#.####.##..#.#.",
        "...####...##......#.#####", "..#....#####...#..#....##", ".#..###..###..#...#.##...", ".#..##.##.###.##..#....##",
        "##.##.#.#...#.########...", ".........#.#....#...#####", "#######.#...#..##.#.#...#", "#.....#.#.###.#.#...##...",
        "#.###.#.###.###.#####.##.", "#.###.#.##...#.#.##..##.#", "#.###.#.######.#.#####..#", "#.....#.#.#.#..#...#...##",
        "#######.###.###...#######",
    ].map { Array($0) }

    var body: some View {
        Canvas { ctx, size in
            let cell = min(size.width, size.height) / 25
            for (r, row) in Self.rows.enumerated() {
                for (c, ch) in row.enumerated() where ch == "#" {
                    let rect = CGRect(x: CGFloat(c) * cell, y: CGFloat(r) * cell, width: cell, height: cell)
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 1), with: .color(Palette.ink))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("QR code")
    }
}

/// Four L-shaped corner brackets.
struct ScanCorners: View {
    var length: CGFloat
    var lineWidth: CGFloat
    var radius: CGFloat
    var color: Color

    var body: some View {
        ZStack {
            corner.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            corner.rotationEffect(.degrees(90)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            corner.rotationEffect(.degrees(180)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            corner.rotationEffect(.degrees(270)).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .allowsHitTesting(false)
    }

    private var corner: some View {
        CornerBracket(radius: radius)
            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
            .padding(lineWidth / 2)
            .frame(width: length, height: length)
    }
}

private struct CornerBracket: Shape {
    var radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let r = min(radius, rect.width)
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

/// `.cornerP`: brackets breathing 1 → .96 → 1 over 2.4s.
struct BreathingModifier: ViewModifier {
    @State private var on = false
    func body(content: Content) -> some View {
        content.scaleEffect(on ? 0.96 : 1)
            .onAppear { withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { on = true } }
    }
}

// MARK: - Flow layout

/// Wraps children onto lines, like inline words in the headlines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 0
    var lineSpacing: CGFloat = 0
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(proposal.width ?? .infinity, subviews)
        let height = rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * lineSpacing
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(bounds.width, subviews) {
            var x: CGFloat
            switch alignment {
            case .center: x = bounds.minX + (bounds.width - row.width) / 2
            case .trailing: x = bounds.maxX - row.width
            default: x = bounds.minX
            }
            for (i, idx) in row.items.enumerated() {
                let size = subviews[idx].sizeThatFits(.unspecified)
                subviews[idx].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + (i < row.items.count - 1 ? spacing : 0)
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row { var items: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(_ maxWidth: CGFloat, _ subviews: Subviews) -> [Row] {
        var rows: [Row] = [Row()]
        for i in subviews.indices {
            let size = subviews[i].sizeThatFits(.unspecified)
            let add = rows[rows.count - 1].items.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if add > maxWidth && !rows[rows.count - 1].items.isEmpty {
                rows.append(Row(items: [i], width: size.width, height: size.height))
            } else {
                rows[rows.count - 1].items.append(i)
                rows[rows.count - 1].width = add
                rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
            }
        }
        return rows
    }
}
