import Foundation
import LocalAuthentication

/// Face ID / Touch ID for "Log in with biometrics".
enum BiometricService {
    enum Outcome { case success, cancelled, unavailable, failed }

    static var isAvailable: Bool {
        var error: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    static func authenticate(reason: String = "Log in to Tahanan") async -> Outcome {
        let context = LAContext()
        context.localizedCancelTitle = "Use password"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .unavailable
        }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) ? .success : .failed
        } catch let e as LAError where [.userCancel, .appCancel, .systemCancel, .userFallback].contains(e.code) {
            return .cancelled
        } catch {
            return .failed
        }
    }
}
