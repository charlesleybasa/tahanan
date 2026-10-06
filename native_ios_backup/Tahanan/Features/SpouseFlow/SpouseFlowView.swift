import SwiftUI

/// Complete spouse details: intro (scan / type / invite) → ID scan → 4 steps → Done, or Invite → Invite sent.
struct SpouseFlowView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var model = SpouseFlowModel()
    @State private var recognized: [String] = []

    var body: some View {
        ZStack {
            CSSRadialGradient(rx: 1.1, ry: 0.5, cx: 0.9, cy: -0.08, stops: [
                .init(color: Palette.blue.opacity(0.3), location: 0),
                .init(color: Palette.blue.opacity(0), location: 0.6),
            ])
            .background(Palette.night)
            .ignoresSafeArea()

            Group {
                switch model.screen {
                case .intro: intro
                case .idScan: idScan
                case let .step(i): stepScreen(i)
                case .done: done
                case .invite: invite
                }
            }
            .id(screenKey)
            .transition(.screen)
        }
        .onAppear {
            if let p = state.profile {
                model = SpouseFlowModel(mine: p.grossMonthlyIncome, required: p.requiredIncome)
            }
        }
    }

    private var screenKey: String {
        switch model.screen {
        case .intro: return "intro"
        case .idScan: return "scan"
        case let .step(i): return "s\(i)"
        case .done: return "done"
        case .invite: return "invite\(model.inviteSent)"
        }
    }

    private func go(_ s: SpouseFlowModel.Screen) {
        withAnimation(Motion.screen) { model.screen = s }
    }

    private func backToApplication() {
        state.applicationTab = .info
        router.go(.application, state: state)
    }

    // MARK: - Intro (S00)

    private var intro: some View {
        ScreenScroll {
            BackButton(label: "Back to my application", action: backToApplication)

            ZStack(alignment: .topLeading) {
                ClosestSideGlow(Palette.yellow, 0.45).frame(width: 150, height: 150).offset(x: 120, y: 10).glowPulse()
                ZStack {
                    ArchShape(bottomRadius: 18).fill(LinearGradient(colors: [Color(hex: 0x4A85F5), Color(hex: 0x2459C9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text(state.profile?.initials ?? "MS").font(Typo.outfit(34, .bold)).foregroundStyle(Palette.text)
                }
                .frame(width: 118, height: 150)
                .shadow(color: .black.opacity(0.6), radius: 24, y: 30)
                .floating(period: 6)
                .offset(x: 70, y: 40)
                ZStack {
                    ArchShape(bottomRadius: 18).fill(.ultraThinMaterial).environment(\.colorScheme, .dark)
                    ArchShape(bottomRadius: 18).fill(Color.white(0.06))
                    ArchShape(bottomRadius: 18).stroke(Palette.yellow.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    IconView(.plus, size: 30).foregroundStyle(Palette.yellow)
                }
                .frame(width: 118, height: 150)
                .floating(period: 7, phase: 2)
                .offset(x: 172, y: 56)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 200, alignment: .topLeading)
            .padding(.top, 18)
            .rise(1)

            Text("Asawa · Spouse").eyebrow().padding(.top, 18).rise(2)
            Text("Add your spouse to your application").h1(34).padding(.top, 10).rise(3)
            Text("You’re married, so your spouse is part of the home loan. Their income can also count toward your household income.")
                .mutedBody().padding(.top, 12).rise(4)

            VStack(spacing: 0) {
                checklistRow(.card, "Their valid government ID")
                Rectangle().fill(Color.white(0.07)).frame(height: 1)
                checklistRow(.document, "TIN and employer details")
                Rectangle().fill(Color.white(0.07)).frame(height: 1)
                checklistRow(.calendar, "About 3 minutes · saves as you go")
            }
            .padding(.vertical, 6).padding(.horizontal, 16)
            .glass(22)
            .padding(.top, 18)
            .rise(5)

            VStack(spacing: 10) {
                PrimaryButton("Scan their ID to autofill", icon: .scan) {
                    model.scan = .idle
                    go(.idScan)
                }
                GhostButton("Type details myself") {
                    model.resetManual()
                    go(.step(0))
                }
                Button {
                    model.inviteSent = false
                    go(.invite)
                } label: {
                    HStack(spacing: 8) {
                        IconView(.send, size: 18)
                        Text("Let my spouse fill it in").font(Typo.manrope(14, .extrabold))
                    }
                    .foregroundStyle(Palette.yellow)
                    .frame(maxWidth: .infinity).frame(height: 48)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 20)
            .rise(6)
        }
    }

    private func checklistRow(_ icon: Icon, _ text: String) -> some View {
        HStack(spacing: 12) {
            IconTile(icon: icon, tint: Palette.submittedText, background: Palette.blue.opacity(0.22), size: 36, radius: 12, iconSize: 18)
            Text(text).font(Typo.manrope(14, .bold)).foregroundStyle(Palette.text)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
    }

    // MARK: - ID scan (S01)

    private var idScan: some View {
        GeometryReader { geo in
            let top = geo.safeAreaInsets.top
            let frame = CGRect(x: 24, y: 230 - 54 + top, width: geo.size.width - 48, height: 216)
            let border: Color = model.scan == .ok ? Palette.green : (model.scan == .reading ? Palette.yellow : .white(0.5))

            ZStack(alignment: .topLeading) {
                Palette.scanGround
                if IDScannerView.hasCamera {
                    IDScannerView(recognized: $recognized)
                } else {
                    Photo(name: "photoInterior").padding(-40).blur(radius: 20).brightness(-0.6)
                }
                DimmedSurround(hole: frame, radius: 22)
                    .fill(Color(hex: 0x02060E, alpha: 0.6), style: FillStyle(eoFill: true))
                    .allowsHitTesting(false)

                ZStack {
                    if !IDScannerView.hasCamera { fakeID.padding(14).fadeIn() }
                    RoundedRectangle(cornerRadius: 22).strokeBorder(border, lineWidth: 3)
                        .animation(.easeInOut(duration: 0.3), value: model.scan)
                    if model.scan != .ok {
                        ScanLine(inset: 14, thickness: 3, glow: 22)
                    } else {
                        Circle().fill(Palette.green).frame(width: 76, height: 76)
                            .overlay(IconView(.check, size: 36).foregroundStyle(.white))
                            .background(Circle().fill(Palette.green.opacity(0.25)).padding(-12))
                            .pop()
                    }
                }
                .frame(width: frame.width, height: frame.height)
                .offset(x: frame.minX, y: frame.minY)

                Text(scanMessage)
                    .font(Typo.manrope(15)).foregroundStyle(Palette.softer).lineSpacing(7)
                    .multilineTextAlignment(.center)
                    .frame(width: geo.size.width - 60)
                    .offset(x: 30, y: 470 - 54 + top)
            }
            .ignoresSafeArea()
            .overlay(alignment: .top) {
                HStack {
                    IconButton(.close, label: "Cancel") { model.scan = .idle; go(.intro) }
                    Spacer()
                    Text("Scan spouse ID").font(Typo.outfit(18, .semibold)).foregroundStyle(Palette.text)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
            }
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Accepted: PhilSys National ID, UMID, Passport, Driver’s license, PRC ID. We only read the name, birthdate and ID number.")
                        .font(Typo.manrope(13)).foregroundStyle(Palette.muted).lineSpacing(4)
                    PrimaryButton("Capture ID", icon: nil, action: capture).padding(.top, 14)
                }
                .padding(18)
                .glass(28, fill: Color(hex: 0x0D1C38, alpha: 0.85), blur: true)
                .padding(.horizontal, 12)
                .padding(.bottom, -10)
                .modifier(SheetUpModifier())
            }
        }
        .background(Palette.scanGround.ignoresSafeArea())
    }

    private var scanMessage: String {
        switch model.scan {
        case .ok: return "Got it — Jose R. Santos"
        case .reading: return "Reading the ID…"
        case .idle: return "Place the front of their ID inside the frame"
        }
    }

    private var fakeID: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 10).fill(Color(hex: 0x9DB0CF)).frame(width: 78, height: 96)
            VStack(alignment: .leading, spacing: 8) {
                Text("REPUBLIKA NG PILIPINAS").font(Typo.manrope(9, .extrabold)).tracking(0.9)
                GeometryReader { g in
                    VStack(alignment: .leading, spacing: 8) {
                        Capsule().fill(Palette.navy.opacity(0.35)).frame(width: g.size.width * 0.8, height: 8)
                        Capsule().fill(Palette.navy.opacity(0.25)).frame(width: g.size.width * 0.6, height: 8)
                        Capsule().fill(Palette.navy.opacity(0.25)).frame(width: g.size.width * 0.7, height: 8)
                    }
                }
                .frame(height: 40)
                Spacer(minLength: 0)
                Text("•••• •••• 2048").font(Typo.mono(10))
            }
        }
        .foregroundStyle(Palette.navy)
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 14).fill(LinearGradient(colors: [Color(hex: 0xE9EEF7), Color(hex: 0xC9D4E8)], startPoint: .topLeading, endPoint: .bottomTrailing)))
        .rotationEffect(.degrees(-2))
    }

    private func capture() {
        guard model.scan == .idle else { return }
        withAnimation { model.scan = .reading }
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation { model.scan = .ok }
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            // TODO: API — run full ID parsing (name, birthdate) server-side; the demo reads only the ID number on device.
            model.applyScannedID(idNumber: IDTextParser.idNumber(from: recognized))
            go(.step(0))
        }
    }

    // MARK: - Form steps (S02–S05)

    private func stepScreen(_ i: Int) -> some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    switch i {
                    case 0: SpousePersonalStep(model: model)
                    case 1: SpouseAddressStep(model: model, address: state.profile?.address ?? "")
                    case 2: SpouseWorkStep(model: model)
                    default: SpouseReviewStep(model: model) { go(.step($0)) }
                    }
                }
                .padding(.horizontal, Spacing.gutter)
                .padding(.top, 150 - 54)
                .padding(.bottom, Spacing.tabBarClearance)
            }
            .scrollDismissesKeyboard(.interactively)

            stepHeader(i)
        }
        .overlay(alignment: .bottom) {
            BottomCTABar {
                PrimaryButton(i == 3 ? "Save spouse details" : "Continue", dimmed: !model.isValid(i)) { next(i) }
            }
        }
    }

    private func stepHeader(_ i: Int) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                BackButton { i == 0 ? go(.intro) : go(.step(i - 1)) }
                VStack(alignment: .leading, spacing: 0) {
                    Text("Spouse information").font(Typo.outfit(19, .semibold)).foregroundStyle(Palette.text)
                    Text("Step \(i + 1) of 4 · \(SpouseFlowModel.steps[i])").font(Typo.manrope(12, .bold)).foregroundStyle(Palette.subtle)
                }
                Spacer()
                HStack(spacing: 6) {
                    IconView(.check, size: 16)
                    Text("Saved").font(Typo.manrope(12, .extrabold))
                }
                .foregroundStyle(Palette.acceptedText)
                .fadeIn(0.6)
            }
            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { j in
                    VStack(alignment: .leading, spacing: 6) {
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white(0.14))
                                Capsule().fill(Palette.yellow).frame(width: g.size.width * (j < i ? 1 : (j == i ? 0.5 : 0)))
                            }
                        }
                        .frame(height: 4)
                        Text(SpouseFlowModel.steps[j]).font(Typo.manrope(10, .extrabold)).tracking(0.4)
                            .foregroundStyle(j <= i ? Palette.text : Palette.dim)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }
                }
            }
            .padding(.top, 14)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(i + 1) of 4")
        }
        .padding(.horizontal, Spacing.gutter)
        .padding(.top, 52 - 54 + 2)
        .padding(.bottom, 12)
        .background(
            LinearGradient(stops: [.init(color: Palette.night, location: 0.78), .init(color: Palette.night.opacity(0), location: 1)],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea(edges: .top)
        )
    }

    private func next(_ i: Int) {
        guard model.isValid(i) else {
            model.touched = true
            state.showToast(i == 3 ? "Please confirm your spouse’s consent" : "Fill in the highlighted fields", icon: .info, tint: Palette.orange)
            return
        }
        if i < 3 {
            go(.step(i + 1))
        } else {
            saveSpouse()
            go(.done)
        }
    }

    private func saveSpouse() {
        // TODO: API — PUT /api/v1/me/application/spouse
        guard let idx = state.sections.firstIndex(where: { $0.id == "spouse" }) else { return }
        let s = state.sections[idx]
        state.sections[idx] = ApplicationSection(
            id: s.id, title: s.title, subtitle: "Complete", percent: 100, cta: "Edit spouse details",
            fields: [
                .init(key: "Full name", value: model.fullName),
                .init(key: "Employer", value: model.employmentType == "none" ? "Not working" : model.employer),
                .init(key: "Monthly income", value: SpouseFlowModel.peso(model.spouseIncome)),
            ]
        )
    }

    // MARK: - Done (S06)

    private var done: some View {
        TimelineView(.animation) { ctx in
            ZStack(alignment: .top) {
                LoopingArchRing(t: ctx.date.timeIntervalSince(doneStart), width: 320, height: 360, color: Palette.green.opacity(0.45), delay: 0)
                    .padding(.top, 80 - 54)
                    .allowsHitTesting(false)
                ScreenScroll(horizontal: 24, top: 140 - 54) {
                    doneContent
                }
            }
        }
    }

    @State private var doneStart = Date()

    private var doneContent: some View {
        VStack(spacing: 0) {
            ProgressRing(fraction: 1, color: Palette.green, size: 120, inner: 100, innerFill: Palette.night) {
                IconView(.check, size: 48).foregroundStyle(Palette.acceptedText)
            }
            .pop()
            Text("Spouse info complete").eyebrow().padding(.top, 36).rise(3)
            Text("\(model.first.isEmpty ? "Jose" : model.first) is on your application").h1(34).multilineTextAlignment(.center).padding(.top, 10).rise(4)
            Text("Your profile is now 84% complete. Next, upload 2 spouse documents.").mutedBody().multilineTextAlignment(.center).padding(.top, 12).rise(5)
            GlassCard {
                RowLayout {
                    IconTile(icon: .card, tint: Palette.todoText, background: Palette.orange.opacity(0.16))
                    Text("Spouse valid government ID").font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text).frame(maxWidth: .infinity, alignment: .leading)
                    StatusPill(text: "To upload", tone: .todo)
                }
                RowDivider()
                RowLayout {
                    IconTile(icon: .document, tint: Palette.todoText, background: Palette.orange.opacity(0.16))
                    Text("Marriage contract (PSA)").font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text).frame(maxWidth: .infinity, alignment: .leading)
                    StatusPill(text: "To upload", tone: .todo)
                }
            }
            .padding(.top, 22).rise(6)
            VStack(spacing: 10) {
                PrimaryButton("Upload documents", icon: .upload) {
                    state.applicationTab = .requirements
                    router.go(.application, state: state)
                }
                GhostButton("Back to my application", action: backToApplication)
            }
            .padding(.top, 18).rise(7)
        }
        .frame(maxWidth: .infinity)
        .onAppear { doneStart = Date() }
    }

    // MARK: - Invite (S07–S08)

    private var invite: some View {
        ScreenScroll {
            BackButton { go(.intro) }
            if !model.inviteSent {
                IconTile(icon: .send, tint: .white, background: Palette.blue, size: 64, radius: 22, iconSize: 28)
                    .padding(.top, 26).rise(1)
                Text("Send your spouse a secure link").h1(32).padding(.top, 20).rise(2)
                Text("They’ll fill in their own details and ID — no account needed. The link expires in 7 days.")
                    .mutedBody().padding(.top, 12).rise(3)
                VStack(spacing: 14) {
                    TahananTextField(label: "Spouse’s first name", placeholder: "Jose", text: $model.inviteName, contentType: .givenName, capitalization: .words)
                    PhoneField(label: "Their mobile number", text: $model.inviteMobile)
                }
                .padding(.top, 22).rise(4)
                PrimaryButton("Send link by SMS", icon: .send, iconSize: 18) {
                    // TODO: API — POST /api/v1/me/application/spouse/invite { name, mobile }
                    withAnimation(Motion.screen) { model.inviteSent = true }
                }
                .padding(.top, 22).rise(5)
            } else {
                let name = model.inviteName.isEmpty ? "Jose" : model.inviteName
                VStack(spacing: 0) {
                    Circle().fill(Palette.blue).frame(width: 104, height: 104)
                        .overlay(IconView(.send, size: 44).foregroundStyle(.white))
                        .background(Circle().fill(Palette.blue.opacity(0.18)).padding(-14))
                        .pop()
                    Text("Link sent to \(name)").h1(32).multilineTextAlignment(.center).padding(.top, 34).rise(3)
                    Text("We’ll notify you when he finishes. You’ll review his details before they’re submitted.")
                        .mutedBody().multilineTextAlignment(.center).padding(.top, 12).rise(4)
                    HStack(spacing: 12) {
                        Spinner(size: 22, lineWidth: 3)
                        Text("Waiting for \(name)").font(Typo.manrope(14, .bold)).foregroundStyle(Palette.text)
                        Spacer()
                        // TODO: API — resend the invite SMS
                        Text("Resend").font(Typo.manrope(13, .extrabold)).foregroundStyle(Palette.yellow).frame(height: 40)
                    }
                    .padding(.vertical, 14 - 8).padding(.horizontal, 16)
                    .glass(20)
                    .padding(.top, 22).rise(5)
                    GhostButton("Back to my application", action: backToApplication).padding(.top, 22).rise(6)
                }
                .padding(.top, 70)
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    SpouseFlowView().environment(AppState.preview).environment(AppRouter())
}
