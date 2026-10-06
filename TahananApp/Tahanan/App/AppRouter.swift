import Observation
import SwiftUI

/// Every screen in the buyer prototype. Navigation mirrors the prototype's `go(screen)` state machine
/// so each change plays the design's screen-enter transition instead of a push.
enum Screen: Hashable {
    case splash, onboarding, login, signup, welcome, forgotPassword
    case home, brand(Int), location(brand: Int, location: Int), scan, booking, payment, paid
    case application, spouse
    case profile, account, security, about(AboutDoc), help, ticket(String), newTicket
    case componentGallery

    var tab: MainTab? {
        switch self {
        case .home: return .home
        case .application: return .application
        case .help: return .help
        case .profile: return .profile
        default: return nil
        }
    }

    /// Screens that enter without the scale/blur transition (they animate their own content).
    var entersPlain: Bool {
        switch self {
        case .splash, .location, .forgotPassword: return true
        default: return false
        }
    }
}

@MainActor
@Observable
final class AppRouter {
    private(set) var screen: Screen
    /// Bumped on every navigation so re-entering the same screen replays its entrance.
    private(set) var visit = 0
    /// True when the last navigation was between two tab-bar screens.
    private(set) var tabSwitch = false

    init(start: Screen = .splash) { screen = start }

    func go(_ next: Screen, state: AppState? = nil) {
        state?.sheet = nil
        guard next != screen || next.tab == nil else { return }
        tabSwitch = screen.tab != nil && next.tab != nil
        visit += 1
        if next.entersPlain {
            screen = next
        } else if tabSwitch {
            withAnimation(.easeOut(duration: 0.18)) { screen = next }
        } else {
            withAnimation(Motion.screen) { screen = next }
        }
    }

    /// Deep links: tahanan://auth/verify-email, tahanan://auth/reset (Supabase redirect targets).
    func handle(_ url: URL, state: AppState) {
        guard url.scheme == "tahanan" else { return }
        let path = url.host.map { "\($0)\(url.path)" } ?? url.path
        switch path {
        case "auth/verify-email":
            state.emailVerification = .verified
            go(.account, state: state)
        case "auth/reset":
            state.forgotStartStep = 2
            go(.forgotPassword, state: state)
        default:
            break
        }
    }
}
