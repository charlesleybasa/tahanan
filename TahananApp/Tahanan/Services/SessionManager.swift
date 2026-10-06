import Foundation
import Observation
import UIKit

/// Holds the API session in the Keychain and keeps it fresh: the token expires every 3 hours,
/// so it refreshes silently shortly before expiry and whenever the app returns to the foreground.
/// If a refresh fails, `onExpired` sends the user back to Login.
@MainActor
@Observable
final class SessionManager {
    private(set) var session: AuthSession?
    var onExpired: (() -> Void)?

    private let auth: AuthService
    private var refreshTask: Task<Void, Never>?
    private var foregroundObserver: NSObjectProtocol?
    private static let key = "session"

    init(auth: AuthService) {
        self.auth = auth
        session = KeychainStore.codable(AuthSession.self, for: Self.key)
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in await self?.refreshIfNeeded() }
        }
        scheduleRefresh()
    }

    var isSignedIn: Bool { session != nil }

    func start(_ session: AuthSession) {
        self.session = session
        KeychainStore.setCodable(session, for: Self.key)
        scheduleRefresh()
    }

    func end() {
        refreshTask?.cancel()
        session = nil
        KeychainStore.delete(Self.key)
    }

    /// Refreshes when the token is inside the leeway window (or already expired).
    func refreshIfNeeded() async {
        guard let s = session else { return }
        if s.expiresAt.timeIntervalSinceNow <= AppConfig.refreshLeeway {
            await refresh()
        } else {
            scheduleRefresh()
        }
    }

    func refresh() async {
        guard let s = session else { return }
        do {
            start(try await auth.refresh(s))
        } catch {
            end()
            onExpired?()
        }
    }

    private func scheduleRefresh() {
        refreshTask?.cancel()
        guard let s = session else { return }
        let delay = max(0, s.expiresAt.timeIntervalSinceNow - AppConfig.refreshLeeway)
        refreshTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }
}
