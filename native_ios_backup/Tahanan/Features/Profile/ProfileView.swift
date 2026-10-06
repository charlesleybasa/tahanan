import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var showCamera = false

    var body: some View {
        let p = state.profile
        ScreenScroll(bottom: Spacing.tabBarClearance) {
            HStack {
                Text("Profile").h1(32).rise()
                Spacer()
                IconButton(.settings, label: "Settings") { router.go(.account, state: state) }
            }

            VStack(spacing: 0) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let img = state.avatar {
                            Image(uiImage: img).resizable().scaledToFill()
                        } else {
                            Circle().fill(LinearGradient(colors: [Color(hex: 0x3D7BF0), Palette.navy], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .overlay(Text(p?.initials ?? "MS").font(Typo.outfit(36, .bold)).foregroundStyle(Palette.text))
                        }
                    }
                    .frame(width: 108, height: 108)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Palette.yellow, lineWidth: 3))
                    .shadow(color: Palette.blue.opacity(0.6), radius: 20, y: 20)

                    Button { selfie() } label: {
                        Circle().fill(Palette.yellow).frame(width: 40, height: 40)
                            .overlay(IconView(.camera, size: 18).foregroundStyle(Palette.ink))
                            .overlay(Circle().strokeBorder(Palette.night, lineWidth: 3))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 4)
                    .accessibilityLabel("Update selfie")
                }
                .background(alignment: .top) {
                    ArchOutline().stroke(Palette.yellow.opacity(0.35), lineWidth: 1.5)
                        .frame(width: 170, height: 150)
                        .offset(y: -10)
                }

                Text(p?.fullName ?? "").font(Typo.outfit(24, .semibold)).tracking(-0.48).foregroundStyle(Palette.text).padding(.top, 14)
                HStack(spacing: 6) {
                    StatusPill(text: p?.role ?? "Buyer", tone: .submitted)
                    StatusPill(text: p?.homefulId ?? "", tone: .custom(bg: .white(0.08), fg: Palette.softer), mono: true)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 18)
            .rise(1)

            GlassCard {
                Button { router.go(.account, state: state) } label: {
                    RowLayout {
                        IconTile(icon: .mail, tint: Palette.submittedText, background: Palette.blue.opacity(0.22))
                        RowText(title: p?.email ?? "", titleSize: 14, overline: "Email")
                        if state.emailVerification == .verified {
                            StatusPill(text: "Verified", tone: .accepted)
                        } else {
                            StatusPill(text: "Verify", tone: .todo)
                        }
                    }
                }
                .buttonStyle(.plain)
                RowDivider()
                Button { router.go(.account, state: state) } label: {
                    RowLayout {
                        IconTile(icon: .phone, tint: Palette.submittedText, background: Palette.blue.opacity(0.22))
                        RowText(title: p?.mobileMasked ?? "", titleSize: 14, overline: "Mobile")
                        StatusPill(text: "Verified", tone: .accepted)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 22)
            .rise(2)

            Text("Settings").overline().padding(.top, 22).padding(.bottom, 8).padding(.horizontal, 4).rise(3)
            GlassCard {
                navRow(.person, "Account details", tint: Palette.yellow, bg: Palette.yellow.opacity(0.16)) { router.go(.account, state: state) }
                RowDivider()
                navRow(.shield, "Security", tint: Palette.acceptedText, bg: Palette.green.opacity(0.18),
                       trailing: state.biometricsEnabled ? "Biometrics on" : "Biometrics off") { router.go(.security, state: state) }
                RowDivider()
                navRow(.help, "Get help", tint: Palette.todoText, bg: Palette.orange.opacity(0.16)) { router.go(.help, state: state) }
            }
            .rise(3)

            Text("About Homeful").overline().padding(.top, 22).padding(.bottom, 8).padding(.horizontal, 4).rise(4)
            GlassCard {
                navRow(.lock, "Privacy Policy", tint: Palette.soft, bg: .white(0.07)) { router.go(.about(.privacy), state: state) }
                RowDivider()
                navRow(.document, "Terms and Conditions", tint: Palette.soft, bg: .white(0.07)) { router.go(.about(.terms), state: state) }
            }
            .rise(4)

            GhostButton("Log out", icon: .logout, iconSize: 20, tint: Palette.todoText) { logOut() }
                .padding(.top, 22)
                .rise(5)

            Text("Tahanan \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0") · by Raemulan Lands")
                .font(Typo.manrope(12)).foregroundStyle(Palette.placeholder)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                #if DEBUG
                .onLongPressGesture { router.go(.componentGallery, state: state) }
                #endif
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCapture(front: true) { img in
                showCamera = false
                // TODO: API — upload the selfie to Supabase Storage and save the URL on the profile.
                if let img { state.avatar = img }
            }
            .ignoresSafeArea()
        }
    }

    private func navRow(_ icon: Icon, _ title: String, tint: Color, bg: Color, trailing: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            RowLayout {
                IconTile(icon: icon, tint: tint, background: bg)
                Text(title).font(Typo.manrope(15, .extrabold)).foregroundStyle(Palette.text).frame(maxWidth: .infinity, alignment: .leading)
                if let trailing { Text(trailing).font(Typo.manrope(12, .bold)).foregroundStyle(Palette.subtle) }
                IconView(.chevronRight).foregroundStyle(Palette.muted)
            }
        }
        .buttonStyle(.plain)
    }

    private func selfie() {
        if CameraCapture.isAvailable { showCamera = true }
        else { state.showToast("Camera isn’t available on this device", icon: .info, tint: Palette.orange) }
    }

    private func logOut() {
        Task {
            await state.auth.signOut()
            state.session.end()
            router.go(.login, state: state)
        }
    }
}

#Preview {
    ProfileView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
