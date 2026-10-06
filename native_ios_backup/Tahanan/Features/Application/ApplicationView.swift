import SwiftUI

struct ApplicationView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var openSection: String? = "personal"

    var body: some View {
        @Bindable var state = state
        ScreenScroll(bottom: Spacing.tabBarClearance) {
            Text("Aking aplikasyon").eyebrow().rise()
            Text("My application").h1(36).padding(.top, 8).rise(1)
            (Text("\(state.profile?.unit.brandName ?? "") · ").font(Typo.manrope(13))
                + Text(state.profile?.unit.code ?? "").font(Typo.mono(13)))
                .foregroundStyle(Palette.muted)
                .padding(.top, 6)
                .rise(1)

            SegmentedPill(
                options: ["Personal info", "Requirements"],
                selection: Binding(get: { state.applicationTab.rawValue }, set: { state.applicationTab = ApplicationTab(rawValue: $0) ?? .info }),
                badge: { i in i == 1 && state.todoCount > 0 ? state.todoCount : nil }
            )
            .padding(.top, 20)
            .rise(2)

            if state.applicationTab == .info {
                infoTab
            } else {
                RequirementsTab()
            }
        }
    }

    // MARK: Personal info

    private var infoTab: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                ProgressRing(fraction: 245.0 / 360, color: Palette.yellow, track: .white(0.12), size: 70, inner: 56, innerFill: Palette.navy) {
                    Text("68%").font(Typo.outfit(17, .bold)).foregroundStyle(Palette.text)
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("Almost pre-qualified").font(Typo.outfit(18, .semibold)).foregroundStyle(Palette.text)
                    Text("Finish spouse details so Homeful can review your loan faster.")
                        .font(Typo.manrope(13)).foregroundStyle(Palette.muted).lineSpacing(3)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(
                LinearGradient(colors: [Palette.navyLight, Palette.navy], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).strokeBorder(Color.white(0.1), lineWidth: 1))
            .padding(.top, 16)
            .rise(3)

            VStack(spacing: 10) {
                ForEach(state.sections) { s in section(s) }
            }
            .padding(.top, 14)
            .rise(4)
        }
    }

    private func ringColor(_ pct: Int) -> Color { pct == 100 ? Palette.green : (pct > 0 ? Palette.yellow : Palette.ringIdle) }

    private func section(_ s: ApplicationSection) -> some View {
        let open = openSection == s.id
        return VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { openSection = open ? nil : s.id }
            } label: {
                RowLayout {
                    ProgressRing(fraction: Double(s.percent) / 100, color: ringColor(s.percent), size: 44, inner: 34) {
                        if s.percent == 100 {
                            IconView(.check, size: 18).foregroundStyle(ringColor(s.percent))
                        } else {
                            Text("\(s.percent)%").font(Typo.manrope(10, .extrabold)).foregroundStyle(ringColor(s.percent))
                        }
                    }
                    RowText(title: s.title, subtitle: s.subtitle, subtitleSize: 12, subtitleColor: Palette.subtle)
                    IconView(.chevronDown).foregroundStyle(Palette.muted)
                        .rotationEffect(.degrees(open ? 180 : 0))
                }
            }
            .buttonStyle(.plain)
            .accessibilityValue(open ? "Expanded" : "Collapsed")

            if open {
                VStack(spacing: 0) {
                    if !s.fields.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(s.fields, id: \.key) { f in
                                HStack(alignment: .top, spacing: 12) {
                                    Text(f.key).font(Typo.manrope(14)).foregroundStyle(Palette.subtle)
                                    Spacer()
                                    Text(f.value).font(Typo.manrope(14, .bold)).foregroundStyle(Palette.text).multilineTextAlignment(.trailing)
                                }
                                .padding(.vertical, 10)
                            }
                        }
                        .padding(.top, 6)
                        .overlay(alignment: .top) { Rectangle().fill(Color.white(0.08)).frame(height: 1) }
                    }
                    if s.id == "spouse" {
                        PrimaryButton(s.cta, height: 52, chipSize: 40) { router.go(.spouse, state: state) }
                            .padding(.top, 8)
                    } else {
                        // TODO: API — personal details, co-borrower and AIF forms are not in the design yet.
                        GhostButton(s.cta, height: 48) {}
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity)
            }
        }
        .glass(22)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

/// Requirements tab: summary bar, items grouped by Principal buyer and Spouse with 3-step status dots.
struct RequirementsTab: View {
    @Environment(AppState.self) private var state

    var body: some View {
        let reqs = state.requirements
        let count = { (s: RequirementStatus) in reqs.filter { $0.status == s }.count }
        let order: [RequirementStatus] = [.accepted, .reviewed, .submitted, .todo]

        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(count(.accepted)) of \(reqs.count) accepted").font(Typo.outfit(22, .semibold)).foregroundStyle(Palette.text)
                    Spacer()
                    Text("\(count(.todo)) to upload").font(Typo.manrope(12, .extrabold)).foregroundStyle(Palette.todoText)
                }
                HStack(spacing: 4) {
                    ForEach(Array(order.flatMap { s in Array(repeating: s, count: count(s)) }.enumerated()), id: \.offset) { _, s in
                        Capsule().fill(color(s))
                    }
                }
                .frame(height: 10)
                .padding(.top, 14)
                .animation(.easeInOut(duration: 0.5), value: reqs)
                HStack(spacing: 14) {
                    LegendDot(color: Palette.green, label: "Accepted")
                    LegendDot(color: Palette.yellow, label: "Reviewed")
                    LegendDot(color: Palette.blue, label: "Submitted")
                    LegendDot(color: Palette.orange, label: "To upload")
                }
                .font(Typo.manrope(12, .bold))
                .foregroundStyle(Palette.muted)
                .padding(.top, 12)
            }
            .padding(18)
            .glass(24)
            .padding(.top, 16)
            .rise(3)

            ForEach(["Principal buyer", "Spouse"], id: \.self) { owner in
                VStack(alignment: .leading, spacing: 0) {
                    Text(owner).sectionTitle(16).padding(.top, 22).padding(.bottom, 10)
                    GlassCard {
                        ForEach(reqs.filter { $0.owner == owner }) { r in
                            row(r)
                            Rectangle().fill(Color.white(0.06)).frame(height: 1)
                        }
                    }
                }
                .rise(4)
            }
        }
    }

    private func color(_ s: RequirementStatus) -> Color {
        switch s {
        case .accepted: return Palette.green
        case .reviewed: return Palette.yellow
        case .submitted: return Palette.blue
        case .todo: return Palette.orange
        }
    }

    private func row(_ r: Requirement) -> some View {
        let n = r.status.step
        let dim = Color.white(0.14)
        return RowLayout {
            IconTile(icon: .document, tint: Palette.soft, background: .white(0.07))
            VStack(alignment: .leading, spacing: 0) {
                Text(r.name).font(Typo.manrope(14, .extrabold)).foregroundStyle(Palette.text).lineSpacing(2)
                HStack(spacing: 4) {
                    Capsule().fill(n >= 1 ? Palette.blue : dim).frame(width: 18, height: 4)
                    Capsule().fill(n >= 2 ? Palette.yellow : dim).frame(width: 18, height: 4)
                    Capsule().fill(n >= 3 ? Palette.green : dim).frame(width: 18, height: 4)
                    Text(r.status == .todo ? "Required" : r.status.label + (r.date.map { " · \($0)" } ?? ""))
                        .font(Typo.manrope(11, .bold)).foregroundStyle(Palette.subtle).padding(.leading, 6)
                }
                .padding(.top, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(r.status.label)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if r.status == .todo {
                Button { state.sheet = .upload(requirementId: r.id) } label: {
                    HStack(spacing: 6) {
                        IconView(.upload, size: 16)
                        Text("Upload").font(Typo.manrope(13, .extrabold))
                    }
                    .foregroundStyle(Palette.ink)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(Capsule().fill(Palette.yellow))
                }
                .pressable()
                .accessibilityLabel("Upload \(r.name)")
            } else {
                StatusPill(text: r.status.label, tone: r.status.tone)
            }
        }
    }
}

#Preview {
    ApplicationView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
