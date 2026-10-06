import SwiftUI

/// `.btnY`: the yellow pill, the only primary-action color. 56pt, navy label, navy circle chip with an icon.
struct PrimaryButton: View {
    let title: String
    var icon: Icon? = .arrowRight
    var iconSize: CGFloat = 20
    var height: CGFloat = 56
    var chipSize: CGFloat = 44
    var centered = false
    var fontSize: CGFloat = 16
    var dimmed = false
    let action: () -> Void

    init(_ title: String, icon: Icon? = .arrowRight, iconSize: CGFloat = 20, height: CGFloat = 56, chipSize: CGFloat = 44,
         centered: Bool = false, fontSize: CGFloat = 16, dimmed: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.iconSize = iconSize
        self.height = height
        self.chipSize = chipSize
        self.centered = centered || icon == nil
        self.fontSize = fontSize
        self.dimmed = dimmed
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(title)
                    .font(Typo.manrope(fontSize, .extrabold))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if !centered, let icon {
                    Spacer(minLength: 8)
                    Circle().fill(Palette.ink)
                        .frame(width: chipSize, height: chipSize)
                        .overlay(IconView(icon, size: iconSize).foregroundStyle(Palette.yellow))
                }
            }
            .padding(.leading, centered ? 24 : 24)
            .padding(.trailing, centered ? 24 : (height - chipSize) / 2)
            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
            .frame(height: height)
            .background(Capsule().fill(Palette.yellow))
            // box-shadow: 0 14px 34px -12px rgba(255,196,46,.6); the negative spread is approximated with a lower alpha
            .shadow(color: Palette.yellow.opacity(0.45), radius: 12, y: 14)
            .opacity(dimmed ? 0.55 : 1)
            .animation(.easeInOut(duration: 0.3), value: dimmed)
        }
        .pressable()
        .accessibilityLabel(title)
    }
}

/// `.btnG`: ghost pill, 52pt, white 6% fill with a 14% hairline.
struct GhostButton: View {
    let title: String
    var icon: Icon? = nil
    var iconSize: CGFloat = 18
    var height: CGFloat = 52
    var tint: Color = Palette.text
    let action: () -> Void

    init(_ title: String, icon: Icon? = nil, iconSize: CGFloat = 18, height: CGFloat = 52, tint: Color = Palette.text, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.iconSize = iconSize
        self.height = height
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let icon { IconView(icon, size: iconSize) }
                Text(title).font(Typo.manrope(15, .bold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Capsule().fill(Color.white(0.06)))
            .overlay(Capsule().strokeBorder(Color.white(0.14), lineWidth: 1))
        }
        .pressable()
    }
}

/// `.ib`: 44pt circle icon button.
struct IconButton: View {
    let icon: Icon
    var size: CGFloat = 44
    var iconSize: CGFloat = 20
    var background: Color = .white(0.07)
    var border: Color? = .white(0.12)
    var blur = false
    let label: String
    let action: () -> Void

    init(_ icon: Icon, label: String, size: CGFloat = 44, iconSize: CGFloat = 20, background: Color = .white(0.07),
         border: Color? = .white(0.12), blur: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.label = label
        self.size = size
        self.iconSize = iconSize
        self.background = background
        self.border = border
        self.blur = blur
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            IconView(icon, size: iconSize)
                .foregroundStyle(Palette.text)
                .frame(width: size, height: size)
                .background {
                    if blur { Circle().fill(.ultraThinMaterial) }
                    Circle().fill(background)
                }
                .overlay { if let border { Circle().strokeBorder(border, lineWidth: 1) } }
        }
        .pressable()
        .accessibilityLabel(label)
    }
}

/// Back arrow icon button used at the top of most screens.
struct BackButton: View {
    var label = "Back"
    let action: () -> Void
    var body: some View { IconButton(.arrowLeft, label: label, action: action) }
}

/// Yellow text button (Forgot password?, See all, Edit …) with a 44pt touch target.
struct LinkButton: View {
    let title: String
    var size: CGFloat = 14
    var weight: Typo.Weight = .bold
    var icon: Icon? = nil
    let action: () -> Void

    init(_ title: String, size: CGFloat = 14, weight: Typo.Weight = .bold, icon: Icon? = nil, action: @escaping () -> Void) {
        self.title = title
        self.size = size
        self.weight = weight
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon { IconView(icon, size: 16) }
                Text(title).font(Typo.manrope(size, weight))
            }
            .foregroundStyle(Palette.yellow)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Log in") {}
        PrimaryButton("Update password", icon: nil) {}
        GhostButton("Log in with biometrics", icon: .fingerprint, iconSize: 22) {}
        HStack { IconButton(.arrowLeft, label: "Back") {}; LinkButton("Forgot password?") {} }
    }
    .padding(24)
    .background(Palette.night)
}
