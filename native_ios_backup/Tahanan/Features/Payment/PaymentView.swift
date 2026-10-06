import SwiftUI

/// Payment (step 2 of 2): method list → processing overlay → Paid.
struct PaymentView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var method = "ew"
    @State private var paying = false

    private struct Method: Identifiable {
        let id: String, name: String, sub: String, icon: Icon
    }

    private let methods = [
        Method(id: "ew", name: "E-wallet", sub: "Pay from your mobile wallet", icon: .wallet),
        Method(id: "cc", name: "Debit or credit card", sub: "Visa, Mastercard, JCB", icon: .card),
        Method(id: "ob", name: "Online banking", sub: "Transfer from your bank app", icon: .bank),
        Method(id: "otc", name: "Over the counter", sub: "Pay at partner outlets", icon: .store),
    ]

    var body: some View {
        let u = state.profile?.unit
        ZStack(alignment: .bottom) {
            ScreenScroll(bottom: Spacing.tabBarClearance) {
                HStack(spacing: 12) {
                    BackButton { router.go(.booking, state: state) }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Payment").font(Typo.outfit(19, .semibold)).foregroundStyle(Palette.text)
                        Text("Step 2 of 2").font(Typo.manrope(12, .bold)).foregroundStyle(Palette.subtle)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        IconView(.lock, size: 15)
                        Text("Secure").font(Typo.manrope(12, .extrabold))
                    }
                    .foregroundStyle(Palette.acceptedText)
                }

                VStack(spacing: 0) {
                    Text("Amount due").font(Typo.manrope(13, .bold)).foregroundStyle(Palette.muted)
                    (Text("₱10,000").foregroundColor(Palette.text) + Text(".00").foregroundColor(Palette.subtle))
                        .font(Typo.outfit(52, .bold)).tracking(-0.035 * 52)
                        .padding(.top, 4)
                    Text("Consultation fee · \(u?.code ?? "")").font(Typo.mono(12)).foregroundStyle(Palette.muted).padding(.top, 6)
                }
                .frame(maxWidth: .infinity)
                .background(alignment: .top) {
                    ClosestSideGlow(Palette.yellow, 0.25).frame(width: 260, height: 160).offset(y: -30).glowPulse()
                }
                .padding(.top, 34)
                .rise(1)

                Text("Pay with").sectionTitle(17).padding(.top, 32).rise(2)

                VStack(spacing: 10) {
                    ForEach(methods) { m in methodRow(m) }
                }
                .padding(.top, 12)
                .rise(3)
            }

            BottomCTABar {
                PrimaryButton("Pay \(u?.consultationFee ?? "₱10,000.00")", icon: .lock, iconSize: 18) { pay() }
            }

            if paying {
                ZStack {
                    Rectangle().fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                    Palette.deep.opacity(0.82)
                    VStack(spacing: 18) {
                        Spinner(size: 56, lineWidth: 4)
                        Text("Processing payment…").font(Typo.manrope(16, .extrabold)).foregroundStyle(Palette.text)
                    }
                }
                .ignoresSafeArea()
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }

    private func methodRow(_ m: Method) -> some View {
        let on = method == m.id
        return Button { method = m.id } label: {
            RowLayout {
                IconTile(icon: m.icon, tint: Palette.yellow, background: .white(0.08))
                RowText(title: m.name, subtitle: m.sub, subtitleSize: 12, subtitleColor: Palette.subtle)
                Circle()
                    .strokeBorder(on ? Palette.yellow : .white(0.3), lineWidth: 2)
                    .frame(width: 24, height: 24)
                    .overlay {
                        if on { Circle().fill(Palette.yellow).frame(width: 12, height: 12).pop() }
                    }
            }
            .background(RoundedRectangle(cornerRadius: 20).fill(on ? Palette.yellow.opacity(0.08) : .white(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(on ? Palette.yellow : .white(0.1), lineWidth: 1.5))
        }
        .pressable()
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }

    private func pay() {
        // TODO: API — create a payment intent for the consultation fee and hand off to the selected provider.
        withAnimation(.easeInOut(duration: 0.4)) { paying = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            router.go(.paid, state: state)
        }
    }
}

struct PaidView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var start = Date()

    var body: some View {
        let u = state.profile?.unit
        ZStack(alignment: .top) {
            TimelineView(.animation) { ctx in
                let t = ctx.date.timeIntervalSince(start)
                ZStack(alignment: .top) {
                    LoopingArchRing(t: t, width: 320, height: 360, color: Palette.green.opacity(0.45), delay: 0).padding(.top, 90 - 54)
                    LoopingArchRing(t: t, width: 460, height: 480, color: Palette.yellow.opacity(0.3), delay: 1).padding(.top, 40 - 54)
                }
                .frame(maxWidth: .infinity)
            }
            .allowsHitTesting(false)

            ScreenScroll(horizontal: 24, top: 150 - 54) {
                VStack(spacing: 0) {
                    Circle().fill(Palette.green).frame(width: 116, height: 116)
                        .overlay(IconView(.check, size: 54).foregroundStyle(.white))
                        .background(Circle().fill(Palette.green.opacity(0.16)).padding(-16))
                        .shadow(color: Palette.green.opacity(0.35), radius: 40)
                        .pop()
                    Text("Salamat!").eyebrow().padding(.top, 44).rise(3)
                    Text("Payment received").h1(38).padding(.top, 10).rise(4)
                    Text("Your unit at \(u?.brandName ?? "Pasinaya Homes") \(u?.location.components(separatedBy: ",").first ?? "Ternate") is reserved. We emailed your receipt.")
                        .mutedBody().multilineTextAlignment(.center).padding(.top, 12).rise(5)

                    VStack(spacing: 0) {
                        SummaryLine(key: "Amount", value: u?.consultationFee ?? "")
                        SummaryLine(key: "Reference no.", value: u?.referenceNo ?? "", divider: false, mono: true)
                    }
                    .padding(.vertical, 6).padding(.horizontal, 18)
                    .glass(22)
                    .padding(.top, 24).rise(6)

                    VStack(spacing: 10) {
                        PrimaryButton("Back to home", icon: .home) { router.go(.home, state: state) }
                        GhostButton("Upload my requirements") { router.go(.application, state: state) }
                    }
                    .padding(.top, 18).rise(7)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            start = Date()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

#Preview {
    PaymentView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
