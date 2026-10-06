import SwiftUI

/// Link an existing account: Homeful ID → SMS OTP → linked.
struct LinkAccountSheet: View {
    @Environment(AppState.self) private var state
    let onClose: () -> Void
    @State private var step = 0
    @State private var homefulId = ""
    @State private var code = "50261"

    var body: some View {
        Group {
            switch step {
            case 0:
                VStack(alignment: .leading, spacing: 0) {
                    IconTile(icon: .link, tint: Palette.submittedText, background: Palette.blue.opacity(0.25), size: 56, radius: 18, iconSize: 26)
                    Text("Link your Homeful account").h1(26).padding(.top, 16)
                    Text("Find past bookings using your Homeful ID or contract number.").mutedBody(14).padding(.top, 8)
                    TahananTextField(label: "Homeful ID or contract no.", placeholder: "HF-0000-000000", text: $homefulId, mono: true, capitalization: .characters)
                        .padding(.top, 18)
                    PrimaryButton("Send code to my mobile", icon: .send, iconSize: 18) { next() }.padding(.top, 16)
                }
            case 1:
                VStack(alignment: .leading, spacing: 0) {
                    Text("Enter the SMS code").h1(26)
                    Text("Sent to \(state.profile?.mobileMasked ?? "+63 917 ••• 4821")").mutedBody(14).padding(.top, 8)
                    OTPField(code: $code).padding(.top, 18)
                    PrimaryButton("Link account", icon: .link, iconSize: 18) {
                        Task { try? await state.repos.buyer.linkAccount(homefulId: homefulId, otp: code) }
                        next()
                    }
                    .padding(.top, 18)
                }
            default:
                SheetSuccess(title: "Account linked", message: "We found 1 past transaction. It now shows on your home.", onDone: onClose)
            }
        }
        .id(step)
        .transition(.fadeIn)
    }

    private func next() { withAnimation(.easeInOut(duration: 0.4)) { step += 1 } }
}

/// Shared sheet success state: 84pt popping check, title, message, Done.
struct SheetSuccess: View {
    let title: String
    var message: String? = nil
    var color: Color = Palette.green
    var topPadding: CGFloat = 8
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Circle().fill(color).frame(width: 84, height: 84)
                .overlay(IconView(.check, size: 40).foregroundStyle(.white))
                .pop()
            Text(title).h1(26).multilineTextAlignment(.center).padding(.top, 18)
            if let message {
                Text(message).mutedBody(14).multilineTextAlignment(.center).padding(.top, 8)
            }
            PrimaryButton("Done", icon: nil) { onDone() }.padding(.top, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, topPadding)
    }
}
