import SwiftUI

/// Bundled Google Fonts (OFL): Outfit for headlines and numbers, Manrope for UI and body,
/// JetBrains Mono for codes such as CAV-PHC-03-B12-L07. All sizes scale with Dynamic Type.
enum Typo {
    enum Weight { case regular, medium, semibold, bold, extrabold }

    static func outfit(_ size: CGFloat, _ weight: Weight = .semibold) -> Font {
        let name: String
        switch weight {
        case .regular: name = "Outfit-Regular"
        case .medium: name = "Outfit-Medium"
        case .semibold: name = "Outfit-SemiBold"
        case .bold, .extrabold: name = "Outfit-Bold"
        }
        return .custom(name, size: size, relativeTo: style(for: size))
    }

    static func manrope(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        let name: String
        switch weight {
        case .regular: name = "Manrope-Regular"
        case .medium: name = "Manrope-Medium"
        case .semibold: name = "Manrope-SemiBold"
        case .bold: name = "Manrope-Bold"
        case .extrabold: name = "Manrope-ExtraBold"
        }
        return .custom(name, size: size, relativeTo: style(for: size))
    }

    static func mono(_ size: CGFloat, _ weight: Weight = .medium) -> Font {
        let name = weight == .semibold || weight == .bold || weight == .extrabold ? "JetBrainsMono-SemiBold" : "JetBrainsMono-Medium"
        return .custom(name, size: size, relativeTo: style(for: size))
    }

    /// Fixed-size variant for art that must not reflow (splash, onboarding canvas).
    static func fixedOutfit(_ size: CGFloat, _ weight: Weight = .semibold) -> Font {
        switch weight {
        case .regular: return .custom("Outfit-Regular", fixedSize: size)
        case .medium: return .custom("Outfit-Medium", fixedSize: size)
        case .semibold: return .custom("Outfit-SemiBold", fixedSize: size)
        case .bold, .extrabold: return .custom("Outfit-Bold", fixedSize: size)
        }
    }

    static func fixedManrope(_ size: CGFloat, _ weight: Weight = .regular) -> Font {
        switch weight {
        case .regular: return .custom("Manrope-Regular", fixedSize: size)
        case .medium: return .custom("Manrope-Medium", fixedSize: size)
        case .semibold: return .custom("Manrope-SemiBold", fixedSize: size)
        case .bold: return .custom("Manrope-Bold", fixedSize: size)
        case .extrabold: return .custom("Manrope-ExtraBold", fixedSize: size)
        }
    }

    static func fixedMono(_ size: CGFloat) -> Font { .custom("JetBrainsMono-Medium", fixedSize: size) }

    private static func style(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 34...: return .largeTitle
        case 26..<34: return .title
        case 20..<26: return .title3
        case 16..<20: return .body
        case 14..<16: return .subheadline
        case 12..<14: return .footnote
        default: return .caption
        }
    }
}

extension View {
    /// CSS letter-spacing in em.
    func trackingEm(_ em: CGFloat, size: CGFloat) -> some View { tracking(em * size) }
}

// MARK: - Named text styles from the prototype's CSS classes

extension Text {
    /// `.h1`: Outfit 600, letter-spacing -0.035em, line-height 1.02.
    func h1(_ size: CGFloat) -> some View {
        font(Typo.outfit(size, .semibold))
            .tracking(-0.035 * size)
            .foregroundStyle(Palette.text)
            .lineSpacing(0)
    }

    /// `.eyebrow`: 12px, 800, letter-spacing .16em, uppercase, yellow.
    func eyebrow() -> some View {
        textCase(.uppercase)
            .font(Typo.manrope(12, .extrabold))
            .tracking(0.16 * 12)
            .foregroundStyle(Palette.yellow)
    }

    /// `.sec`: Outfit 20px 600, letter-spacing -.015em.
    func sectionTitle(_ size: CGFloat = 20) -> some View {
        font(Typo.outfit(size, .semibold))
            .tracking(-0.015 * size)
            .foregroundStyle(Palette.text)
    }

    /// `.lbl`: 13px 700 #AAB9D3.
    func fieldLabel() -> some View {
        font(Typo.manrope(13, .bold)).foregroundStyle(Palette.label)
    }

    /// `.muted` paragraph: 15px, line-height 1.55.
    func mutedBody(_ size: CGFloat = 15) -> some View {
        font(Typo.manrope(size)).foregroundStyle(Palette.muted).lineSpacing(size * 0.3)
    }

    /// Uppercase overline used for settings groups (12px 800 .1em #8C9DBC).
    func overline(color: Color = Palette.subtle, tracking em: CGFloat = 0.1) -> some View {
        textCase(.uppercase)
            .font(Typo.manrope(12, .extrabold))
            .tracking(em * 12)
            .foregroundStyle(color)
    }
}
