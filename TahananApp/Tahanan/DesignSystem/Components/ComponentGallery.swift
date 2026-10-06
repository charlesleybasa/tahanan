import SwiftUI

/// Design-system gallery for reviewing tokens and components side by side with the prototype.
/// Debug builds: long-press the version line on Profile.
struct ComponentGallery: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var text = ""
    @State private var focusText = "maria.santos@email.com"
    @State private var code = "4829"
    @State private var toggle = true
    @State private var check = true
    @State private var tab = 0

    var body: some View {
        ScreenScroll(bottom: 80) {
            ScreenHeader(title: "Component gallery") { router.go(.profile, state: state) }

            group("Colors") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                    swatch("Night", Palette.night); swatch("Navy", Palette.navy); swatch("Blue", Palette.blue); swatch("Yellow", Palette.yellow)
                    swatch("Orange", Palette.orange); swatch("Green", Palette.green); swatch("Text", Palette.text); swatch("Muted", Palette.muted)
                }
            }

            group("Type") {
                Text("Find your tahanan.").h1(42)
                Text("Explore communities").sectionTitle()
                Text("Tuklasin · Discover").eyebrow()
                Text("Body copy in Manrope 15 with 1.55 line height for comfortable reading.").mutedBody()
                Text("CAV-PHC-03-B12-L07").font(Typo.mono(13)).foregroundStyle(Palette.text)
            }

            group("Logo") {
                HStack(spacing: 24) {
                    TahananMark(width: 104)
                    VStack(alignment: .leading, spacing: 12) { TahananLockup(); AgentAvatar() }
                }
            }

            group("Buttons") {
                PrimaryButton("Log in") {}
                PrimaryButton("Update password", icon: nil) {}
                GhostButton("Log in with biometrics", icon: .fingerprint, iconSize: 22) {}
                HStack { BackButton {}; IconButton(.bell, label: "Notifications") {}; LinkButton("Forgot password?") {} }
            }

            group("Fields") {
                TahananTextField(label: "Email address", placeholder: "you@email.com", text: $text, keyboard: .emailAddress)
                TahananTextField(label: "Password", placeholder: "Your password", text: $focusText, secure: true)
                PhoneField(label: "Mobile number", text: $text)
                OTPField(code: $code)
                HStack { TahananToggle(isOn: $toggle, label: "Toggle"); Checkbox(isOn: $check) }
            }

            group("Status") {
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    StatusPill(text: "Submitted", tone: .submitted)
                    StatusPill(text: "Reviewed", tone: .reviewed)
                    StatusPill(text: "Accepted", tone: .accepted)
                    StatusPill(text: "To upload", tone: .todo)
                    StatusPill(text: "Read-only", tone: .muted)
                }
                SegmentedPill(options: ["Personal info", "Requirements"], selection: $tab, badge: { $0 == 1 ? 2 : nil })
            }

            group("Surfaces") {
                GlassCard {
                    RowLayout {
                        IconTile(icon: .link, tint: Palette.submittedText, background: Palette.blue.opacity(0.25))
                        RowText(title: "Link an existing account", subtitle: "Bought with Homeful before? See it here.")
                        IconView(.chevronRight).foregroundStyle(Palette.muted)
                    }
                }
                HStack(spacing: 16) {
                    Photo(name: "photoPH", kenBurns: true).frame(width: 120, height: 160).clipShape(ArchShape(bottomRadius: 18))
                    ProgressRing(fraction: 0.6, color: Palette.yellow, size: 70, inner: 56) {
                        Text("60%").font(Typo.outfit(17, .bold)).foregroundStyle(Palette.text)
                    }
                    Spinner(size: 40, lineWidth: 4)
                }
                DecorativeQR().frame(width: 120).padding(10).background(RoundedRectangle(cornerRadius: 16).fill(.white))
            }

            group("Icons") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 14) {
                    ForEach(Icon.allCases, id: \.self) { IconView($0, size: 22).foregroundStyle(Palette.text) }
                }
            }

            group("Tab bar") {
                FloatingTabBar(selected: .home, onSelect: { _ in }, onScan: {}).padding(.horizontal, -14).padding(.top, 30)
            }
        }
    }

    private func group<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).overline()
            content()
        }
        .padding(.top, 28)
    }

    private func swatch(_ name: String, _ c: Color) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 14).fill(c).frame(height: 54)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white(0.1), lineWidth: 1))
            Text(name).font(Typo.manrope(11, .bold)).foregroundStyle(Palette.muted)
        }
    }
}

#Preview {
    ComponentGallery().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
