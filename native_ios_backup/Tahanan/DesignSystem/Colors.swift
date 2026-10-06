import SwiftUI

extension Color {
    /// `Color(hex: 0x08142A)` or `Color(hex: 0xFFFFFF, alpha: 0.09)`, matching the CSS values in the design files.
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    static func white(_ alpha: Double) -> Color { Color(hex: 0xFFFFFF, alpha: alpha) }
}

/// Brand tokens from tahanan-design/CLAUDE.md plus the supporting values used inline in the prototype.
enum Palette {
    // Brand
    static let night = Color(hex: 0x08142A)
    static let navy = Color(hex: 0x16305B)
    static let blue = Color(hex: 0x2E6BE6)
    static let yellow = Color(hex: 0xFFC42E)
    static let orange = Color(hex: 0xF2622E)
    static let green = Color(hex: 0x2FA96B)

    // Text
    static let text = Color(hex: 0xF3F6FC)
    static let muted = Color(hex: 0xA2B2CE)
    static let subtle = Color(hex: 0x8C9DBC)
    static let label = Color(hex: 0xAAB9D3)
    static let placeholder = Color(hex: 0x7F91B2)
    static let soft = Color(hex: 0xC9D4E8)
    static let softer = Color(hex: 0xE2E8F3)
    static let dim = Color(hex: 0x6F82A6)
    static let tabIdle = Color(hex: 0x8C9BB8)
    static let ringIdle = Color(hex: 0x5C6F93)

    // Grounds
    /// Navy text/ink on yellow (`#0B1A33`).
    static let ink = Color(hex: 0x0B1A33)
    static let deep = Color(hex: 0x050D1C)
    static let splash = Color(hex: 0x071226)
    static let panel = Color(hex: 0x0F2142)
    static let panelDeep = Color(hex: 0x10223F)
    static let scanGround = Color(hex: 0x02060E)
    static let navyLight = Color(hex: 0x1D3B6E)

    // Status pill text
    static let acceptedText = Color(hex: 0x62D69C)
    static let reviewedText = Color(hex: 0xFFC94A)
    static let submittedText = Color(hex: 0x93B4FF)
    static let todoText = Color(hex: 0xFF9468)

    /// The roof arch gradient: linear-gradient(160deg, #4A85F5 0%, #2E6BE6 45%, #2459C9 100%).
    static let roofGradient = LinearGradient(
        stops: [
            .init(color: Color(hex: 0x4A85F5), location: 0),
            .init(color: Color(hex: 0x2E6BE6), location: 0.45),
            .init(color: Color(hex: 0x2459C9), location: 1),
        ],
        startPoint: UnitPoint(x: 0.329, y: 0.03),
        endPoint: UnitPoint(x: 0.671, y: 0.97)
    )

    /// Avatar gradient: linear-gradient(135deg, #3D7BF0, #1D3B6E).
    static let avatarGradient = LinearGradient(
        colors: [Color(hex: 0x3D7BF0), Color(hex: 0x1D3B6E)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}
