import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var email = ""
    @State private var password = ""
    @State private var busy = false

    var body: some View {
        ZStack(alignment: .top) {
            // Hero photo: 360 tall, 75% opacity, Ken Burns, fading into the night ground
            ZStack {
                Photo(name: "photoPH", kenBurns: true).opacity(0.75)
                LinearGradient(stops: [
                    .init(color: Palette.night.opacity(0.35), location: 0),
                    .init(color: Palette.night.opacity(0.55), location: 0.45),
                    .init(color: Palette.night, location: 0.96),
                ], startPoint: .top, endPoint: .bottom)
            }
            .frame(height: 360)
            .ignoresSafeArea(edges: .top)
            .accessibilityHidden(true)

            ScreenScroll(horizontal: Spacing.authGutter) {
                TahananLockup().rise()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Maligayang pagbabalik").eyebrow().rise(1)
                    Text("Log in to your tahanan").h1(36).rise(2)
                }
                .padding(.top, 150)

                VStack(alignment: .leading, spacing: 16) {
                    TahananTextField(label: "Email address", placeholder: "you@email.com", text: $email, keyboard: .emailAddress, contentType: .emailAddress)
                        .rise(3)
                    TahananTextField(label: "Password", placeholder: "Your password", text: $password, contentType: .password, secure: true)
                        .rise(4)
                    HStack {
                        Spacer()
                        LinkButton("Forgot password?") { router.go(.forgotPassword, state: state) }
                    }
                    .padding(.top, -4)
                    .rise(4)
                    PrimaryButton("Log in", action: logIn).rise(5)
                }
                .padding(.top, 28)

                HStack(spacing: 12) {
                    Rectangle().fill(Color.white(0.1)).frame(height: 1)
                    Text("OR").font(Typo.manrope(12, .bold)).foregroundStyle(Palette.placeholder)
                    Rectangle().fill(Color.white(0.1)).frame(height: 1)
                }
                .padding(.vertical, 22)
                .rise(6)

                GhostButton("Log in with biometrics", icon: .fingerprint, iconSize: 22, action: biometricLogIn).rise(6)

                HStack(spacing: 0) {
                    Text("New to Tahanan? ").font(Typo.manrope(15)).foregroundStyle(Palette.muted)
                    Button { router.go(.signup, state: state) } label: {
                        Text("Create an account").font(Typo.manrope(15, .extrabold)).foregroundStyle(Palette.yellow)
                            .padding(.vertical, 10).padding(.horizontal, 4)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .rise(7)
            }
        }
    }

    private func logIn() {
        guard !busy else { return }
        busy = true
        Task {
            defer { busy = false }
            do {
                let s = try await state.auth.signIn(email: email, password: password)
                state.session.start(s)
                router.go(.home, state: state)
            } catch {
                state.showToast(error.localizedDescription, icon: .info, tint: Palette.orange)
            }
        }
    }

    private func biometricLogIn() {
        Task {
            switch await BiometricService.authenticate() {
            case .success, .unavailable:
                // TODO: API — exchange the Keychain-stored refresh token for a new session instead of a mock sign-in.
                // Demo: devices without Face ID / Touch ID (and the simulator) go straight in.
                logIn()
            case .cancelled, .failed:
                break
            }
        }
    }
}

#Preview {
    LoginView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
