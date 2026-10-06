import SwiftUI

struct SignupView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var name = ""
    @State private var email = ""
    @State private var mobile = ""
    @State private var agreed = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ClosestSideGlow(Palette.yellow, 0.35)
                .frame(width: 240, height: 240)
                .glowPulse()
                .offset(x: 60, y: -40)
                .ignoresSafeArea()

            ScreenScroll(horizontal: Spacing.authGutter) {
                BackButton { router.go(.login, state: state) }.rise()

                Text("Sumali · Join").eyebrow().padding(.top, 28).rise(1)
                Text("Create your account").h1(36).padding(.top, 10).rise(2)
                Text("Just three details to start. You can complete your buyer profile anytime.")
                    .mutedBody().padding(.top, 12).rise(3)

                VStack(alignment: .leading, spacing: 16) {
                    TahananTextField(label: "Full name", placeholder: "Juan Dela Cruz", text: $name, contentType: .name, capitalization: .words).rise(3)
                    TahananTextField(label: "Email address", placeholder: "you@email.com", text: $email, keyboard: .emailAddress, contentType: .emailAddress).rise(4)
                    PhoneField(label: "Mobile number", text: $mobile).rise(5)

                    CheckboxRow(isOn: $agreed) {
                        Text(termsText).font(Typo.manrope(14)).foregroundStyle(Palette.muted).lineSpacing(14 * 0.5 - 4)
                            .environment(\.openURL, OpenURLAction { url in
                                router.go(.about(url.host == "privacy" ? .privacy : .terms), state: state)
                                return .handled
                            })
                    }
                    .padding(.top, 4)
                    .rise(6)

                    PrimaryButton("Create account", action: create).padding(.top, 6).rise(7)
                }
                .padding(.top, 26)

                HStack(spacing: 0) {
                    Text("Already have an account? ").font(Typo.manrope(15)).foregroundStyle(Palette.muted)
                    Button { router.go(.login, state: state) } label: {
                        Text("Log in").font(Typo.manrope(15, .extrabold)).foregroundStyle(Palette.yellow)
                            .padding(.vertical, 10).padding(.horizontal, 4)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
                .rise(8)
            }
        }
    }

    private var termsText: AttributedString {
        var s = AttributedString("I agree to Homeful’s ")
        var terms = AttributedString("Terms and Conditions")
        terms.link = URL(string: "tahanan-doc://terms")
        terms.foregroundColor = Palette.yellow
        var privacy = AttributedString("Privacy Policy")
        privacy.link = URL(string: "tahanan-doc://privacy")
        privacy.foregroundColor = Palette.yellow
        s.append(terms)
        s.append(AttributedString(" and "))
        s.append(privacy)
        s.append(AttributedString("."))
        return s
    }

    private func create() {
        Task {
            // New users are saved as Leads (see AuthService.signUp).
            if let s = try? await state.auth.signUp(name: name, email: email, mobile: mobile) {
                state.session.start(s)
            }
            router.go(.welcome, state: state)
        }
    }
}

#Preview {
    SignupView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
