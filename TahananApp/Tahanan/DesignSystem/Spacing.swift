import SwiftUI

/// Layout constants from the prototype (390 × 844 frame, 54pt status bar area).
enum Spacing {
    /// Horizontal gutter for most screens.
    static let gutter: CGFloat = 20
    /// Gutter for auth screens.
    static let authGutter: CGFloat = 24
    /// Prototype screens pad 56px from the top of a frame whose status bar area is 54px.
    static let belowStatusBar: CGFloat = 2
    /// Bottom padding that clears the floating tab bar (130px in the prototype, minus the 34pt home indicator area).
    static let tabBarClearance: CGFloat = 96
    /// Minimum touch target.
    static let touch: CGFloat = 44
}

enum Radii {
    static let input: CGFloat = 16
    static let card: CGFloat = 22
    static let cardLarge: CGFloat = 26
    static let hero: CGFloat = 28
    static let sheet: CGFloat = 32
}
