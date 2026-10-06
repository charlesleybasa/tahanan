import SwiftUI

// MARK: - Glass

/// `.glass`: white 5.5% + 1pt white 9% hairline, with an optional backdrop blur for floating surfaces.
struct GlassBackground: ViewModifier {
    var radius: CGFloat
    var fill: Color = .white(0.055)
    var border: Color = .white(0.09)
    var blur = false

    func body(content: Content) -> some View {
        content
            .background {
                let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
                ZStack {
                    if blur { shape.fill(.ultraThinMaterial).environment(\.colorScheme, .dark) }
                    shape.fill(fill)
                }
            }
            .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(border, lineWidth: 1))
    }
}

extension View {
    func glass(_ radius: CGFloat = Radii.card, fill: Color = .white(0.055), border: Color = .white(0.09), blur: Bool = false) -> some View {
        modifier(GlassBackground(radius: radius, fill: fill, border: border, blur: blur))
    }
}

/// Container that clips grouped rows into a glass card.
struct GlassCard<Content: View>: View {
    var radius: CGFloat = Radii.card
    var padding: EdgeInsets = EdgeInsets()
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0, content: content)
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glass(radius)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// MARK: - Status pills

enum PillTone {
    case accepted, reviewed, submitted, todo, muted, custom(bg: Color, fg: Color)

    var colors: (Color, Color) {
        switch self {
        case .accepted: return (Palette.green.opacity(0.18), Palette.acceptedText)
        case .reviewed: return (Palette.yellow.opacity(0.16), Palette.reviewedText)
        case .submitted: return (Palette.blue.opacity(0.24), Palette.submittedText)
        case .todo: return (Palette.orange.opacity(0.17), Palette.todoText)
        case .muted: return (.white(0.08), Palette.label)
        case let .custom(bg, fg): return (bg, fg)
        }
    }
}

/// `.pill`: 26pt capsule, 12pt 800.
struct StatusPill: View {
    let text: String
    var tone: PillTone = .muted
    var icon: Icon? = nil
    var height: CGFloat = 26
    var mono = false
    var horizontalPadding: CGFloat = 10
    var fontSize: CGFloat = 12

    var body: some View {
        let (bg, fg) = tone.colors
        HStack(spacing: 6) {
            if let icon { IconView(icon, size: 13) }
            Text(text)
                .font(mono ? Typo.mono(fontSize, .semibold) : Typo.manrope(fontSize, .extrabold))
                .lineLimit(1)
                .fixedSize()
        }
        .foregroundStyle(fg)
        .padding(.horizontal, horizontalPadding)
        .frame(height: height)
        .background(Capsule().fill(bg))
    }
}

extension RequirementStatus {
    var tone: PillTone {
        switch self {
        case .accepted: return .accepted
        case .reviewed: return .reviewed
        case .submitted: return .submitted
        case .todo: return .todo
        }
    }
}

// MARK: - Rows

/// `.ico`: 42pt rounded square icon tile.
struct IconTile: View {
    let icon: Icon
    var tint: Color
    var background: Color
    var size: CGFloat = 42
    var radius: CGFloat = 14
    var iconSize: CGFloat = 20

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(background)
            .frame(width: size, height: size)
            .overlay(IconView(icon, size: iconSize).foregroundStyle(tint))
    }
}

/// `.row`: 64pt min, 12/16 padding, 14 gap.
struct RowLayout<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        HStack(spacing: 14, content: content)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .contentShape(Rectangle())
    }
}

/// Inset hairline between rows: 1pt white 7%, 16pt side margins.
struct RowDivider: View {
    var inset: CGFloat = 16
    var opacity: Double = 0.07
    var body: some View {
        Rectangle().fill(Color.white(opacity)).frame(height: 1).padding(.horizontal, inset)
    }
}

/// Two-line text block used inside rows.
struct RowText: View {
    let title: String
    var subtitle: String? = nil
    var titleSize: CGFloat = 15
    var subtitleSize: CGFloat = 13
    var subtitleColor: Color = Palette.muted
    var subtitleMono = false
    var overline: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let overline {
                Text(overline).font(Typo.manrope(12, .bold)).foregroundStyle(Palette.subtle)
            }
            Text(title).font(Typo.manrope(titleSize, .extrabold)).foregroundStyle(Palette.text)
            if let subtitle {
                Text(subtitle)
                    .font(subtitleMono ? Typo.mono(11) : Typo.manrope(subtitleSize))
                    .foregroundStyle(subtitleColor)
                    .padding(.top, subtitleMono ? 1 : 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Chips

/// `.chipb`: 40pt filter chip.
struct FilterChip: View {
    let title: String
    var selected: Bool
    /// Help uses a white selection, everything else yellow.
    var selectedFill: Color = Palette.yellow
    var height: CGFloat = 40
    var radius: CGFloat? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Typo.manrope(14, .bold))
                .foregroundStyle(selected ? Palette.ink : Palette.softer)
                .lineLimit(1)
                .padding(.horizontal, 16)
                .frame(height: height)
                .frame(maxWidth: radius == nil ? nil : .infinity)
                .background(shape.fill(selected ? selectedFill : .white(0.05)))
                .overlay(shape.strokeBorder(selected ? selectedFill : .white(0.14), lineWidth: 1))
                .animation(.easeInOut(duration: 0.2), value: selected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: radius ?? height / 2, style: .continuous) }
}

/// Two-option segmented control in a glass pill (Personal info / Requirements, Privacy / Terms).
struct SegmentedPill: View {
    let options: [String]
    @Binding var selection: Int
    var badge: (Int) -> Int? = { _ in nil }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options.indices, id: \.self) { i in
                Button { withAnimation(.easeInOut(duration: 0.3)) { selection = i } } label: {
                    HStack(spacing: 8) {
                        Text(options[i]).font(Typo.manrope(14, .extrabold))
                        if let n = badge(i) {
                            Text("\(n)")
                                .font(Typo.manrope(11, .extrabold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 20, minHeight: 20)
                                .background(Capsule().fill(Palette.orange))
                        }
                    }
                    .foregroundStyle(selection == i ? Palette.ink : Palette.soft)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Capsule().fill(selection == i ? Palette.yellow : .clear))
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == i ? [.isSelected] : [])
            }
        }
        .padding(5)
        .frame(height: 54)
        .glass(27)
    }
}

// MARK: - Progress ring

/// conic-gradient ring with an inner disc, used for section progress and the 68% card.
struct ProgressRing<Center: View>: View {
    var fraction: Double
    var color: Color
    var track: Color = .white(0.1)
    var size: CGFloat
    var inner: CGFloat
    var innerFill: Color = Palette.panelDeep
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle().fill(track)
            Circle()
                .fill(AngularGradient(stops: [
                    .init(color: color, location: 0),
                    .init(color: color, location: fraction),
                    .init(color: .clear, location: fraction),
                    .init(color: .clear, location: 1),
                ], center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)))
            Circle().fill(innerFill).frame(width: inner, height: inner)
            center()
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Misc

/// Avatar circle with initials (Outfit 700).
struct InitialsAvatar: View {
    let initials: String
    var size: CGFloat = 46
    var fontSize: CGFloat = 16
    var fill: AnyShapeStyle = AnyShapeStyle(Palette.avatarGradient)
    var textColor: Color = Palette.text

    var body: some View {
        Circle().fill(fill)
            .frame(width: size, height: size)
            .overlay(Text(initials).font(Typo.outfit(fontSize, .bold)).foregroundStyle(textColor))
            .accessibilityHidden(true)
    }
}

/// Key/value line inside summary cards (`.muted` key, bold value, hairline below).
struct SummaryLine: View {
    let key: String
    let value: String
    var valueColor: Color = Palette.text
    var divider = true
    var verticalPadding: CGFloat = 12
    var mono = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(key).font(Typo.manrope(14)).foregroundStyle(Palette.muted)
                Spacer(minLength: 12)
                Text(value)
                    .font(mono ? Typo.mono(14, .semibold) : Typo.manrope(14, .extrabold))
                    .foregroundStyle(valueColor)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, verticalPadding)
            if divider { Rectangle().fill(Color.white(0.08)).frame(height: 1) }
        }
    }
}

/// Small colored legend dot + label.
struct LegendDot: View {
    let color: Color
    let label: String
    var size: CGFloat = 8
    var radius: CGFloat? = nil

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: radius ?? size / 2).fill(color).frame(width: size, height: size)
            Text(label)
        }
    }
}
