import SwiftUI

/// Confirm booking (step 1 of 2), opened from a seller's booking QR.
struct BookingView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var confirmed = false

    var body: some View {
        let u = state.profile?.unit
        ZStack(alignment: .bottom) {
            ScreenScroll(bottom: Spacing.tabBarClearance) {
                HStack(spacing: 12) {
                    BackButton { router.go(.home, state: state) }
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Confirm booking").font(Typo.outfit(19, .semibold)).foregroundStyle(Palette.text)
                        Text("Step 1 of 2").font(Typo.manrope(12, .bold)).foregroundStyle(Palette.subtle)
                    }
                    Spacer()
                    StatusPill(text: "From seller QR", tone: .accepted, icon: .scan)
                }

                ZStack(alignment: .bottomLeading) {
                    Photo(name: "photoPH", kenBurns: true)
                    LinearGradient(stops: [.init(color: Palette.night.opacity(0), location: 0.5), .init(color: Palette.night.opacity(0.85), location: 1)],
                                   startPoint: .top, endPoint: .bottom)
                    Text(u?.code ?? "")
                        .font(Typo.mono(12, .semibold)).foregroundStyle(Palette.ink)
                        .padding(.vertical, 6).padding(.horizontal, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Palette.yellow))
                        .padding(.leading, 16).padding(.bottom, 14)
                }
                .frame(height: 230)
                .clipShape(ArchShape(bottomRadius: 28))
                .overlay(ArchShape(bottomRadius: 28).stroke(Color.white(0.12), lineWidth: 1))
                .padding(.top, 20)
                .rise(1)

                Text(u?.brandName ?? "").h1(32).padding(.top, 18).rise(2)
                HStack(spacing: 6) {
                    IconView(.pin, size: 15)
                    Text("\(u?.barangay ?? ""), \(u?.location ?? "")").font(Typo.manrope(14))
                }
                .foregroundStyle(Palette.muted)
                .padding(.top, 6).rise(2)

                FlowLayout(spacing: 6, lineSpacing: 6) {
                    StatusPill(text: u?.product ?? "", tone: .muted)
                    StatusPill(text: u?.block ?? "", tone: .muted)
                    StatusPill(text: "\(u?.floorArea ?? "") sqm floor", tone: .muted)
                    StatusPill(text: "\(u?.lotArea ?? "") sqm lot", tone: .muted)
                }
                .padding(.top, 12).rise(3)

                VStack(spacing: 0) {
                    SummaryLine(key: "Total contract price", value: u?.tcp ?? "", verticalPadding: 13)
                    SummaryLine(key: "Downpayment", value: "None", valueColor: Palette.acceptedText, verticalPadding: 13)
                    VStack(spacing: 0) {
                        HStack {
                            Text("Monthly amortization").font(Typo.manrope(14)).foregroundStyle(Palette.muted)
                            Spacer()
                            (Text(u?.monthly ?? "").font(Typo.manrope(14, .extrabold)).foregroundColor(Palette.text)
                             + Text(" · \(u?.term ?? "")").font(Typo.manrope(14, .semibold)).foregroundColor(Palette.subtle))
                        }
                        .padding(.vertical, 13)
                        Rectangle().fill(Color.white(0.08)).frame(height: 1)
                    }
                    HStack {
                        Text("Due today · Consultation fee").font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text)
                        Spacer()
                        Text(u?.consultationFee ?? "").font(Typo.outfit(20, .bold)).foregroundStyle(Palette.yellow)
                    }
                    .padding(.vertical, 14)
                }
                .padding(.vertical, 6).padding(.horizontal, 18)
                .glass(24)
                .padding(.top, 18).rise(4)

                GlassCard(radius: 24) {
                    RowLayout {
                        InitialsAvatar(initials: state.profile?.initials ?? "MS", size: 42, fontSize: 16)
                        RowText(title: state.profile?.fullName ?? "", overline: "Buyer")
                        // TODO: API — edit buyer details on the booking (no edit screen in the design yet)
                        Text("Edit").font(Typo.manrope(13, .extrabold)).foregroundStyle(Palette.yellow).frame(height: 44)
                    }
                    RowDivider()
                    RowLayout {
                        InitialsAvatar(initials: u?.seller.initials ?? "JD", size: 42, fontSize: 16,
                                       fill: AnyShapeStyle(Palette.yellow), textColor: Palette.ink)
                        RowText(title: "\(u?.seller.name ?? "") · Homeful seller", overline: "Assisted by")
                    }
                }
                .padding(.top, 12).rise(5)

                CheckboxRow(isOn: $confirmed) {
                    Text("I confirm the unit details above and agree to the reservation terms.")
                        .font(Typo.manrope(13)).foregroundStyle(Palette.muted).lineSpacing(4)
                }
                .padding(.top, 16).rise(6)
            }

            BottomCTABar {
                PrimaryButton("Continue to payment") { router.go(.payment, state: state) }
            }
        }
    }
}

#Preview {
    BookingView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
