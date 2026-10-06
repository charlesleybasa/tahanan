import SwiftUI

/// Account details: email verification card (code or link with deep-link return), change email / mobile, Homeful ID.
struct AccountView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var code = "31705"

    var body: some View {
        let verified = state.emailVerification == .verified
        ScreenScroll(bottom: 60) {
            ScreenHeader(title: "Account details") { router.go(.profile, state: state) }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Email verification").overline(color: Palette.soft)
                    Spacer()
                    if verified {
                        StatusPill(text: "Verified", tone: .accepted, icon: .check)
                    } else {
                        StatusPill(text: "Not verified", tone: .todo)
                    }
                }
                Text(state.profile?.email ?? "").font(Typo.manrope(16, .extrabold)).foregroundStyle(Palette.text).padding(.top, 10)

                Group {
                    switch state.emailVerification {
                    case .idle: idle
                    case .enterCode: enterCode
                    case .openingLink: opening
                    case .verified: done
                    }
                }
                .id(state.emailVerification)
                .transition(.fadeIn)
            }
            .padding(20)
            .background(
                ZStack(alignment: .topTrailing) {
                    if verified {
                        LinearGradient(colors: [Palette.green.opacity(0.22), Palette.green.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        LinearGradient(colors: [Palette.navyLight, Palette.navy], startPoint: .topLeading, endPoint: .bottomTrailing)
                    }
                    ArchShape(bottomRadius: 0).fill(Color.white(0.05)).frame(width: 140, height: 170).offset(x: 30, y: -40)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(verified ? Palette.green.opacity(0.4) : .white(0.1), lineWidth: 1))
            .animation(.easeInOut(duration: 0.5), value: verified)
            .padding(.top, 22)
            .rise(1)

            GlassCard {
                Button { state.sheet = .changeEmail } label: {
                    RowLayout {
                        IconTile(icon: .mail, tint: Palette.submittedText, background: Palette.blue.opacity(0.22))
                        RowText(title: "Change email address", subtitle: "New email needs verification", subtitleSize: 12, subtitleColor: Palette.subtle)
                        IconView(.chevronRight).foregroundStyle(Palette.muted)
                    }
                }
                .buttonStyle(.plain)
                RowDivider()
                Button { state.sheet = .changeMobile } label: {
                    RowLayout {
                        IconTile(icon: .phone, tint: Palette.submittedText, background: Palette.blue.opacity(0.22))
                        RowText(title: "Change mobile number", subtitle: "Confirmed by SMS code", subtitleSize: 12, subtitleColor: Palette.subtle)
                        IconView(.chevronRight).foregroundStyle(Palette.muted)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
            .rise(2)

            HStack(spacing: 12) {
                IconTile(icon: .person, tint: Palette.yellow, background: Palette.yellow.opacity(0.16))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Homeful ID").font(Typo.manrope(12, .bold)).foregroundStyle(Palette.subtle)
                    Text(state.profile?.homefulId ?? "").font(Typo.mono(15, .semibold)).foregroundStyle(Palette.text)
                }
                Spacer()
                StatusPill(text: "Read-only", tone: .muted)
            }
            .padding(16)
            .glass(22)
            .padding(.top, 14)
            .rise(3)
        }
    }

    private func set(_ s: EmailVerificationState) {
        withAnimation(.easeInOut(duration: 0.4)) { state.emailVerification = s }
    }

    private var idle: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Verify to receive booking receipts and password reset links.")
                .font(Typo.manrope(14)).foregroundStyle(Palette.soft).lineSpacing(5).padding(.top, 8)
            VStack(spacing: 10) {
                PrimaryButton("Send verification code", icon: .send, iconSize: 18) {
                    Task { try? await state.auth.sendEmailVerification() }
                    set(.enterCode)
                }
                GhostButton("Email me a link instead", icon: .external) {
                    // TODO: API — send the magic link; the inbox link returns through tahanan://auth/verify-email
                    // (AppRouter.handle). The demo simulates the round trip.
                    set(.openingLink)
                    Task {
                        try? await Task.sleep(nanoseconds: 1_800_000_000)
                        set(.verified)
                    }
                }
            }
            .padding(.top, 16)
        }
    }

    private var enterCode: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Enter the 6-digit code we sent.").font(Typo.manrope(14)).foregroundStyle(Palette.soft).padding(.top, 8)
            OTPField(code: $code, boxWidth: 44, spacing: 7).padding(.top, 14)
            PrimaryButton("Verify email", icon: .check, iconSize: 18) {
                Task { try? await state.auth.verifyEmail(code: code) }
                set(.verified)
            }
            .padding(.top, 16)
        }
    }

    private var opening: some View {
        HStack(spacing: 14) {
            Spinner(size: 34, lineWidth: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Opening verification link…").font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text)
                Text("You’ll be brought back to Tahanan automatically.").font(Typo.manrope(12)).foregroundStyle(Palette.muted)
            }
        }
        .padding(.top, 16)
    }

    private var done: some View {
        HStack(spacing: 14) {
            Circle().fill(Palette.green).frame(width: 48, height: 48)
                .overlay(IconView(.check, size: 24).foregroundStyle(.white))
                .pop()
            VStack(alignment: .leading, spacing: 2) {
                Text("You’re verified").font(Typo.manrope(15, .extrabold)).foregroundStyle(Palette.text)
                Text("Welcome back from your inbox.").font(Typo.manrope(13)).foregroundStyle(Palette.soft)
            }
            .rise(2)
        }
        .padding(.top, 14)
    }
}

// MARK: - Change email / mobile sheets

struct ChangeEmailSheet: View {
    let onClose: () -> Void
    @State private var step = 0
    @State private var email = ""
    @State private var code = "9418"

    var body: some View {
        Group {
            switch step {
            case 0:
                VStack(alignment: .leading, spacing: 0) {
                    Text("Change email address").h1(26)
                    Text("We’ll keep your current email until the new one is verified.").mutedBody(14).padding(.top, 8)
                    TahananTextField(label: "New email address", placeholder: "you@newmail.com", text: $email, keyboard: .emailAddress, contentType: .emailAddress)
                        .padding(.top, 18)
                    // TODO: API — supabase.auth.update(user: UserAttributes(email:)) sends the code + link
                    PrimaryButton("Send code to new email", icon: .send, iconSize: 18) { next() }.padding(.top, 16)
                }
            case 1:
                VStack(alignment: .leading, spacing: 0) {
                    Text("Verify your new email").h1(26)
                    Text("Enter the code, or tap the link in that inbox.").mutedBody(14).padding(.top, 8)
                    OTPField(code: $code).padding(.top, 18)
                    PrimaryButton("Verify and update", icon: .check, iconSize: 18) { next() }.padding(.top, 18)
                }
            default:
                SheetSuccess(title: "Email updated", message: "Receipts and reset links now go to your new email.", onDone: onClose)
            }
        }
        .id(step)
        .transition(.fadeIn)
    }

    private func next() { withAnimation(.easeInOut(duration: 0.4)) { step += 1 } }
}

struct ChangeMobileSheet: View {
    let onClose: () -> Void
    @State private var step = 0
    @State private var mobile = ""
    @State private var code = "773"

    var body: some View {
        Group {
            switch step {
            case 0:
                VStack(alignment: .leading, spacing: 0) {
                    Text("Change mobile number").h1(26)
                    Text("We’ll text a code to confirm it’s yours.").mutedBody(14).padding(.top, 8)
                    PhoneField(label: "New mobile number", text: $mobile).padding(.top, 18)
                    // TODO: API — send SMS OTP to the new number
                    PrimaryButton("Send SMS code", icon: .send, iconSize: 18) { next() }.padding(.top, 16)
                }
            case 1:
                VStack(alignment: .leading, spacing: 0) {
                    Text("Enter the SMS code").h1(26)
                    OTPField(code: $code).padding(.top, 18)
                    PrimaryButton("Confirm number", icon: .check, iconSize: 18) { next() }.padding(.top, 18)
                }
            default:
                SheetSuccess(title: "Mobile number updated", onDone: onClose)
            }
        }
        .id(step)
        .transition(.fadeIn)
    }

    private func next() { withAnimation(.easeInOut(duration: 0.4)) { step += 1 } }
}

#Preview {
    AccountView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
