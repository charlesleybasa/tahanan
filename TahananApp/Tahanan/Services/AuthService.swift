import Foundation

enum AuthError: LocalizedError {
    case invalidCredentials, refreshFailed, network

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Email or password is incorrect."
        case .refreshFailed: return "Your session expired. Please log in again."
        case .network: return "Can’t reach Tahanan right now."
        }
    }
}

/// Auth operations the app needs. The live version wraps Supabase Auth; the demo uses `MockAuthService`.
protocol AuthService {
    func signIn(email: String, password: String) async throws -> AuthSession
    /// New buyers are saved as Leads.
    func signUp(name: String, email: String, mobile: String) async throws -> AuthSession
    func sendPasswordReset(email: String) async throws
    func verifyResetCode(email: String, code: String) async throws
    func updatePassword(_ newPassword: String) async throws
    func refresh(_ session: AuthSession) async throws -> AuthSession
    func signOut() async
    func sendEmailVerification() async throws
    func verifyEmail(code: String) async throws
}

/// Accepts any credentials so the demo can be explored on TestFlight without a backend.
struct MockAuthService: AuthService {
    private func session(_ email: String) -> AuthSession {
        AuthSession(
            accessToken: "mock-access-\(UUID().uuidString)",
            refreshToken: "mock-refresh-\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(AppConfig.tokenLifetime),
            userId: "mock-user",
            email: email.isEmpty ? "maria.santos@email.com" : email
        )
    }

    // TODO: API — supabase.auth.signIn(email:password:)
    func signIn(email: String, password: String) async throws -> AuthSession { session(email) }

    // TODO: API — supabase.auth.signUp + POST /api/v1/leads { name, email, mobile }
    func signUp(name: String, email: String, mobile: String) async throws -> AuthSession { session(email) }

    // TODO: API — supabase.auth.resetPasswordForEmail(email, redirectTo: "tahanan://auth/reset")
    func sendPasswordReset(email: String) async throws {}

    // TODO: API — supabase.auth.verifyOTP(email:token:type: .recovery)
    func verifyResetCode(email: String, code: String) async throws {}

    // TODO: API — supabase.auth.update(user: UserAttributes(password:))
    func updatePassword(_ newPassword: String) async throws {}

    // TODO: API — supabase.auth.refreshSession(refreshToken:)
    func refresh(_ old: AuthSession) async throws -> AuthSession {
        var s = old
        s.accessToken = "mock-access-\(UUID().uuidString)"
        s.expiresAt = Date().addingTimeInterval(AppConfig.tokenLifetime)
        return s
    }

    // TODO: API — supabase.auth.signOut()
    func signOut() async {}

    // TODO: API — supabase.auth.resend(email:type: .signup, emailRedirectTo: "tahanan://auth/verify-email")
    func sendEmailVerification() async throws {}

    // TODO: API — supabase.auth.verifyOTP(email:token:type: .email)
    func verifyEmail(code: String) async throws {}
}
