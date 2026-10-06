import SwiftUI

struct SecurityView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var current = ""
    @State private var newPassword = ""
    @State private var confirm = ""

    var body: some View {
        ScreenScroll(bottom: 60) {
            ScreenHeader(title: "Security") { router.go(.profile, state: state) }

            HStack(spacing: 14) {
                IconTile(icon: .fingerprint, tint: Palette.yellow, background: Palette.yellow.opacity(0.16), size: 48, radius: 16, iconSize: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Biometric login").font(Typo.manrope(15, .extrabold)).foregroundStyle(Palette.text)
                    Text("Face ID or fingerprint").font(Typo.manrope(13)).foregroundStyle(Palette.muted)
                }
                Spacer()
                TahananToggle(isOn: Binding(get: { state.biometricsEnabled }, set: toggleBiometrics), label: "Biometric login")
            }
            .padding(18)
            .glass(24)
            .padding(.top, 22)
            .rise(1)

            Text("Change password").sectionTitle(17).padding(.top, 26).rise(2)

            VStack(spacing: 14) {
                TahananTextField(label: "Current password", placeholder: "Current password", text: $current, contentType: .password, secure: true)
                TahananTextField(label: "New password", placeholder: "At least 8 characters", text: $newPassword, contentType: .newPassword, secure: true)
                TahananTextField(label: "Confirm new password", placeholder: "Type it again", text: $confirm, contentType: .newPassword, secure: true)
                PrimaryButton("Update password", icon: nil) {
                    Task { try? await state.auth.updatePassword(newPassword) }
                    current = ""; newPassword = ""; confirm = ""
                    state.showToast("Password updated")
                }
                Button { router.go(.forgotPassword, state: state) } label: {
                    Text("Forgot your current password?").font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.yellow)
                        .frame(maxWidth: .infinity).frame(height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(18)
            .glass(24)
            .padding(.top, 12)
            .rise(2)

            HStack(alignment: .top, spacing: 14) {
                IconView(.shield).foregroundStyle(Palette.submittedText)
                VStack(alignment: .leading, spacing: 0) {
                    Text("Secure sessions").font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text)
                    Text("Your sign-in refreshes every 3 hours. If it can’t refresh, we’ll ask you to log in again.")
                        .font(Typo.manrope(13)).foregroundStyle(Palette.soft).lineSpacing(5)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Palette.blue.opacity(0.12)))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Palette.blue.opacity(0.3), lineWidth: 1))
            .padding(.top, 14)
            .rise(3)
        }
    }

    private func toggleBiometrics(_ on: Bool) {
        if on {
            Task {
                // Confirm with Face ID / Touch ID before enabling (falls through on devices without biometrics).
                let r = await BiometricService.authenticate(reason: "Turn on biometric login")
                guard r == .success || r == .unavailable else { return }
                state.biometricsEnabled = true
                state.showToast("Biometric login turned on")
            }
        } else {
            state.biometricsEnabled = false
            state.showToast("Biometric login turned off")
        }
    }
}

#Preview {
    SecurityView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
