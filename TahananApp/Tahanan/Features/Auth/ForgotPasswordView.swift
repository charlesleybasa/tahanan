import SwiftUI

/// Forgot password: email → 6-digit code (or reset link) → new password with strength meter → success.
struct ForgotPasswordView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var step = 0
    @State private var email = ""
    @State private var code = "4829"
    @State private var newPassword = ""
    @State private var confirm = ""
    @State private var resendIn = 42

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                BackButton(action: back)
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Palette.yellow : .white(0.22))
                            .frame(width: i == step ? 22 : 6, height: 6)
                    }
                }
                .animation(.easeInOut(duration: 0.4), value: step)
                .accessibilityLabel("Step \(step + 1) of 4")
            }
            .padding(.horizontal, Spacing.authGutter)
            .padding(.top, Spacing.belowStatusBar)

            ScrollView(showsIndicators: false) {
                Group {
                    switch step {
                    case 0: emailStep
                    case 1: codeStep
                    case 2: passwordStep
                    default: doneStep
                    }
                }
                .id(step)
                .transition(.screen)
                .padding(.horizontal, Spacing.authGutter)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .onAppear {
            if state.forgotStartStep > 0 { step = state.forgotStartStep; state.forgotStartStep = 0 }
        }
    }

    private func go(_ s: Int) { withAnimation(Motion.screen) { step = s } }

    private func back() {
        if step == 0 || step == 3 { router.go(.login, state: state) } else { go(step - 1) }
    }

    private func stepIcon(_ icon: Icon, bg: Color, fg: Color) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous).fill(bg)
            .frame(width: 64, height: 64)
            .overlay(IconView(icon, size: 28).foregroundStyle(fg))
            .padding(.top, 36)
            .rise()
    }

    // MARK: Steps

    private var emailStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon(.lock, bg: Palette.yellow, fg: Palette.ink)
            Text("Forgot your password?").h1(34).padding(.top, 24).rise(1)
            Text("Enter your registered email. We’ll send a 6-digit code and a reset link.").mutedBody().padding(.top, 12).rise(2)
            TahananTextField(label: "Registered email", placeholder: "you@email.com", text: $email, keyboard: .emailAddress, contentType: .emailAddress)
                .padding(.top, 28).rise(3)
            PrimaryButton("Send reset code", icon: .send, iconSize: 18) {
                Task { try? await state.auth.sendPasswordReset(email: email) }
                go(1)
            }
            .padding(.top, 22).rise(4)
        }
    }

    private var codeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon(.mail, bg: Palette.blue, fg: .white)
            Text("Check your inbox").h1(34).padding(.top, 24).rise(1)
            (Text("We sent a 6-digit code to ") + Text(state.profile?.emailMasked ?? "m••••••@email.com").foregroundColor(Palette.text).font(Typo.manrope(15, .bold)))
                .mutedBody().padding(.top, 12).rise(2)
            OTPField(code: $code).padding(.top, 28).rise(3)
            HStack(spacing: 0) {
                Text("Resend code in ").font(Typo.manrope(14)).foregroundStyle(Palette.subtle)
                Text(String(format: "0:%02d", resendIn)).font(Typo.mono(14)).foregroundStyle(Palette.text)
            }
            .padding(.top, 16).rise(4)
            .task {
                while resendIn > 0 && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    resendIn -= 1
                }
            }
            VStack(spacing: 12) {
                PrimaryButton("Verify code") {
                    Task { try? await state.auth.verifyResetCode(email: email, code: code) }
                    go(2)
                }
                // TODO: API — the real link opens Mail; Supabase redirects back via tahanan://auth/reset.
                GhostButton("Open reset link instead", icon: .external) { go(2) }
            }
            .padding(.top, 26).rise(5)
        }
    }

    private var passwordStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepIcon(.shield, bg: Palette.green, fg: .white)
            Text("Create a new password").h1(34).padding(.top, 24).rise(1)
            TahananTextField(label: "New password", placeholder: "At least 8 characters", text: $newPassword, contentType: .newPassword, secure: true)
                .padding(.top, 24).rise(2)
            TahananTextField(label: "Confirm new password", placeholder: "Type it again", text: $confirm, contentType: .newPassword, secure: true)
                .padding(.top, 14).rise(3)
            PasswordStrengthMeter(password: newPassword).padding(.top, 16).rise(4)
            VStack(alignment: .leading, spacing: 8) {
                rule("8 or more characters", met: newPassword.count >= 8)
                rule("A number and a symbol", met: PasswordStrength.hasNumberAndSymbol(newPassword))
            }
            .padding(.top, 16).rise(5)
            PrimaryButton("Update password", icon: .check, iconSize: 18) {
                Task { try? await state.auth.updatePassword(newPassword) }
                go(3)
            }
            .padding(.top, 24).rise(6)
        }
    }

    private func rule(_ text: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            IconView(.check, size: 16).foregroundStyle(met ? Palette.acceptedText : Palette.dim)
            Text(text).font(Typo.manrope(13)).foregroundStyle(Palette.muted)
        }
        .animation(.easeInOut(duration: 0.2), value: met)
    }

    private var doneStep: some View {
        VStack(spacing: 0) {
            Circle().fill(Palette.green)
                .frame(width: 104, height: 104)
                .overlay(IconView(.check, size: 54).foregroundStyle(.white))
                .background(Circle().fill(Palette.green.opacity(0.15)).padding(-14))
                .background(Circle().fill(Palette.green.opacity(0.07)).padding(-30))
                .pop()
                .padding(.top, 110)
            Text("Password updated").h1(34).padding(.top, 40).rise(3)
            Text("Log in with your new password. We’ve signed you out of other devices.")
                .mutedBody().multilineTextAlignment(.center).padding(.top, 12).rise(4)
            PrimaryButton("Back to log in") { router.go(.login, state: state) }.padding(.top, 30).rise(5)
        }
        .frame(maxWidth: .infinity)
    }
}

enum PasswordStrength {
    static func hasNumberAndSymbol(_ p: String) -> Bool {
        p.contains(where: \.isNumber) && p.contains(where: { !$0.isLetter && !$0.isNumber && !$0.isWhitespace })
    }

    /// 0–4 lit bars.
    static func score(_ p: String) -> Int {
        guard !p.isEmpty else { return 0 }
        var s = 1
        if p.count >= 8 { s += 1 }
        if hasNumberAndSymbol(p) { s += 1 }
        if p.count >= 12 && p.contains(where: \.isUppercase) { s += 1 }
        return s
    }
}

/// Four 5pt bars + label. The design shows the "Strong" state (3 green bars).
struct PasswordStrengthMeter: View {
    let password: String

    var body: some View {
        let score = PasswordStrength.score(password)
        let (label, color, text): (String, Color, Color) = score >= 3
            ? ("Strong", Palette.green, Palette.acceptedText)
            : (score == 2 ? ("Fair", Palette.yellow, Palette.reviewedText) : ("Weak", Palette.orange, Palette.todoText))
        HStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { i in
                Capsule().fill(i < score ? color : .white(0.12)).frame(height: 5)
            }
            if score > 0 {
                Text(label).font(Typo.manrope(12, .extrabold)).foregroundStyle(text).padding(.leading, 6)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: score)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(score > 0 ? "Password strength: \(label)" : "Password strength")
    }
}

#Preview {
    ForgotPasswordView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
