import SwiftUI
import UniformTypeIdentifiers

struct HelpView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var category = "All"
    @State private var query = ""

    private var tickets: [Ticket] {
        state.tickets.filter { t in
            (category == "All" || t.category == category)
                && (query.isEmpty || t.subject.localizedCaseInsensitiveContains(query) || t.id.localizedCaseInsensitiveContains(query)
                    || t.messages.contains { $0.text.localizedCaseInsensitiveContains(query) })
        }
    }

    var body: some View {
        ScreenScroll(bottom: Spacing.tabBarClearance) {
            Text("Tulong · Help").eyebrow().rise()
            Text("How can we help, \(state.profile?.firstName ?? "Maria")?").h1(36).padding(.top, 8).rise(1)

            TahananTextField(label: nil, placeholder: "Search your tickets", text: $query, leadingIcon: .search)
                .padding(.top, 18)
            .rise(2)

            Button { router.go(.newTicket, state: state) } label: {
                HStack(spacing: 14) {
                    Circle().fill(Palette.ink).frame(width: 52, height: 52)
                        .overlay(IconView(.plus, size: 24).foregroundStyle(Palette.yellow))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Start a new ticket").font(Typo.outfit(19, .semibold))
                        Text("A Homeful agent replies right in the chat.").font(Typo.manrope(13, .semibold)).opacity(0.78)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(Palette.ink)
                .padding(18)
                .background(
                    ZStack(alignment: .bottomTrailing) {
                        Palette.yellow
                        ArchShape(bottomRadius: 0).fill(Color.white(0.25)).frame(width: 120, height: 140).offset(x: 24, y: 50)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .pressable()
            .padding(.top, 14)
            .rise(3)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["All"] + state.ticketCategories, id: \.self) { c in
                        FilterChip(title: c, selected: category == c, selectedFill: Palette.text) { category = c }
                    }
                }
            }
            .contentMargins(.horizontal, Spacing.gutter, for: .scrollContent)
            .padding(.horizontal, -Spacing.gutter)
            .padding(.top, 20)
            .rise(4)

            HStack(alignment: .firstTextBaseline) {
                Text("My tickets").sectionTitle()
                Spacer()
                Text("\(tickets.count) \(tickets.count == 1 ? "ticket" : "tickets")").font(Typo.manrope(13, .bold)).foregroundStyle(Palette.subtle)
            }
            .padding(.top, 22)

            VStack(spacing: 10) {
                ForEach(tickets) { t in
                    Button { router.go(.ticket(t.id), state: state) } label: { TicketCard(ticket: t) }
                        .pressable()
                }
            }
            .padding(.top, 12)
            .rise(5)
        }
    }
}

struct TicketCard: View {
    let ticket: Ticket

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(ticket.id) · \(ticket.category)").font(Typo.mono(12)).foregroundStyle(Palette.subtle)
                Spacer()
                StatusPill(text: ticket.status.label, tone: tone(ticket.status))
            }
            Text(ticket.subject).font(Typo.manrope(15, .extrabold)).foregroundStyle(Palette.text).multilineTextAlignment(.leading)
            HStack(spacing: 12) {
                Text(ticket.lastMessage).font(Typo.manrope(13)).foregroundStyle(Palette.muted).lineLimit(1)
                Spacer(minLength: 0)
                Text(ticket.time).font(Typo.manrope(12)).foregroundStyle(Palette.placeholder)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(22)
    }
}

func tone(_ s: TicketStatus) -> PillTone {
    switch s {
    case .open: return .submitted
    case .progress: return .reviewed
    case .resolved: return .accepted
    }
}

// MARK: - Ticket chat

struct TicketChatView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    let ticketId: String
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        let ticket = state.ticket(ticketId)
        ZStack(alignment: .top) {
            Palette.night.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(ticket?.messages ?? []) { m in message(m).id(m.id) }
                        if state.agentTyping.contains(ticketId) { typing.id("typing") }
                        Color.clear.frame(height: 1).id("bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 136 - 54)
                    .padding(.bottom, 12)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: ticket?.messages.count) { _, _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
                .onChange(of: state.agentTyping.contains(ticketId)) { _, _ in withAnimation { proxy.scrollTo("bottom", anchor: .bottom) } }
                .onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
            }
            .safeAreaInset(edge: .bottom) { composer }

            header(ticket)
        }
    }

    private func header(_ t: Ticket?) -> some View {
        HStack(spacing: 12) {
            BackButton { router.go(.help, state: state) }
            VStack(alignment: .leading, spacing: 2) {
                Text(t?.subject ?? "").font(Typo.manrope(15, .extrabold)).foregroundStyle(Palette.text).lineLimit(1)
                Text("\(t?.id ?? "") · \(t?.category ?? "")").font(Typo.mono(11)).foregroundStyle(Palette.subtle)
            }
            Spacer(minLength: 0)
            if let t { StatusPill(text: t.status.label, tone: tone(t.status)) }
        }
        .padding(.horizontal, 16)
        .padding(.top, 52 - 54 + 6)
        .padding(.bottom, 14)
        .background(
            CornerBox(0, 0, 26, 26)
                .fill(Color(hex: 0x0D1C38, alpha: 0.92))
                .background(CornerBox(0, 0, 26, 26).fill(.ultraThinMaterial).environment(\.colorScheme, .dark))
                .overlay(CornerBox(0, 0, 26, 26).stroke(Color.white(0.09), lineWidth: 1))
                .ignoresSafeArea(edges: .top)
        )
    }

    @ViewBuilder
    private func message(_ m: TicketMessage) -> some View {
        switch m.kind {
        case .sys:
            Text(m.text).font(Typo.manrope(11, .extrabold)).foregroundStyle(Palette.subtle)
                .padding(.vertical, 6).padding(.horizontal, 12)
                .background(Capsule().fill(Color.white(0.06)))
                .padding(.vertical, 6)
                .fadeIn()
        case .them:
            HStack(alignment: .bottom, spacing: 8) {
                AgentAvatar()
                VStack(alignment: .leading, spacing: 0) {
                    Text(m.who ?? "").font(Typo.manrope(11, .bold)).foregroundStyle(Palette.subtle).padding(.leading, 4).padding(.bottom, 4)
                    Text(m.text).font(Typo.manrope(14)).foregroundStyle(Palette.text).lineSpacing(5)
                        .padding(.vertical, 12).padding(.horizontal, 14)
                        .background(CornerBox(20, 20, 20, 6).fill(Color.white(0.055)))
                        .overlay(CornerBox(20, 20, 20, 6).stroke(Color.white(0.09), lineWidth: 1))
                    if m.attachment { attachment }
                    Text(m.time ?? "").font(Typo.manrope(10)).foregroundStyle(Palette.placeholder).padding(.leading, 4).padding(.top, 4)
                }
                Spacer(minLength: 40)
            }
            .rise()
        case .me:
            HStack {
                Spacer(minLength: 60)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(m.text).font(Typo.manrope(14)).foregroundStyle(.white).lineSpacing(5)
                        .padding(.vertical, 12).padding(.horizontal, 14)
                        .background(CornerBox(20, 20, 6, 20).fill(Palette.blue))
                    Text(m.time ?? "").font(Typo.manrope(10)).foregroundStyle(Palette.placeholder).padding(.trailing, 4)
                }
            }
            .rise()
        }
    }

    private var attachment: some View {
        Button {
            state.applicationTab = .requirements
            router.go(.application, state: state)
        } label: {
            HStack(spacing: 10) {
                IconTile(icon: .document, tint: Palette.yellow, background: Palette.yellow.opacity(0.16), size: 34, radius: 10, iconSize: 18)
                Text("Latest payslips (3 months)").font(Typo.manrope(13, .extrabold)).foregroundStyle(Palette.text)
                Spacer(minLength: 0)
                IconView(.arrowRight, size: 18).foregroundStyle(Palette.yellow)
            }
            .padding(.vertical, 10).padding(.horizontal, 12)
            .glass(16)
        }
        .pressable()
        .padding(.top, 6)
    }

    private var typing: some View {
        HStack(spacing: 8) {
            AgentAvatar()
            TypingDots()
                .padding(.vertical, 14).padding(.horizontal, 16)
                .background(CornerBox(20, 20, 20, 6).fill(Color.white(0.055)))
                .overlay(CornerBox(20, 20, 20, 6).stroke(Color.white(0.09), lineWidth: 1))
            Spacer()
        }
        .fadeIn()
        .accessibilityLabel("Support is typing")
    }

    private var composer: some View {
        HStack(spacing: 8) {
            HStack(spacing: 0) {
                // TODO: API — chat attachments (upload to ticket)
                IconButton(.paperclip, label: "Attach file", background: .clear, border: nil) {}
                TextField("", text: $draft, prompt: Text("Write a message…").foregroundStyle(Palette.placeholder))
                    .font(Typo.manrope(15))
                    .foregroundStyle(Palette.text)
                    .tint(Palette.yellow)
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit(send)
                    .accessibilityLabel("Message")
            }
            .padding(.horizontal, 6)
            .frame(height: 58)
            .glass(29, fill: Color(hex: 0x0D1C38, alpha: 0.92), blur: true)

            Button(action: send) {
                Circle().fill(Palette.yellow).frame(width: 58, height: 58)
                    .overlay(IconView(.send, size: 22).foregroundStyle(Palette.ink))
                    .shadow(color: Palette.yellow.opacity(0.45), radius: 12, y: 12)
            }
            .pressable()
            .accessibilityLabel("Send")
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .padding(.top, 8)
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        state.send(text, to: ticketId)
    }
}

/// Three dots bouncing in sequence (tdotA 1.2s, .15s stagger).
struct TypingDots: View {
    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { i in
                    let p = ((t - Double(i) * 0.15).truncatingRemainder(dividingBy: 1.2) + 1.2).truncatingRemainder(dividingBy: 1.2) / 1.2
                    // 0%,80%,100%: .3 opacity, rest; 40%: 1 opacity, -3pt
                    let k = p < 0.4 ? CubicBezier.easeInOut(p / 0.4) : (p < 0.8 ? 1 - CubicBezier.easeInOut((p - 0.4) / 0.4) : 0)
                    Circle().fill(Palette.label).frame(width: 7, height: 7)
                        .opacity(mix(0.3, 1, k))
                        .offset(y: -3 * k)
                }
            }
        }
    }
}

// MARK: - New ticket

struct NewTicketView: View {
    @Environment(AppState.self) private var state
    @Environment(AppRouter.self) private var router
    @State private var category = "Documents"
    @State private var subject = ""
    @State private var message = ""
    @State private var attachment: String?
    @State private var picking = false
    @FocusState private var messageFocused: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            Palette.night.ignoresSafeArea()
            ScreenScroll(bottom: Spacing.tabBarClearance) {
                ScreenHeader(title: "New ticket") { router.go(.help, state: state) }

                Text("Category").fieldLabel().padding(.top, 26).padding(.bottom, 8).rise(1)
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(state.ticketCategories, id: \.self) { c in
                        FilterChip(title: c, selected: category == c) { category = c }
                    }
                }
                .rise(1)

                TahananTextField(label: "Subject", placeholder: "e.g. Payslip upload keeps failing", text: $subject)
                    .padding(.top, 20).rise(2)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Describe the issue").fieldLabel()
                    TextField("", text: $message, prompt: Text("Tell us what happened. Include your unit code if it’s about a booking.").foregroundStyle(Palette.placeholder), axis: .vertical)
                        .font(Typo.manrope(16))
                        .foregroundStyle(Palette.text)
                        .tint(Palette.yellow)
                        .lineSpacing(8)
                        .lineLimit(4...)
                        .focused($messageFocused)
                        .padding(.vertical, 14).padding(.horizontal, 16)
                        .frame(minHeight: 120, alignment: .topLeading)
                        .modifier(FieldChrome(focused: messageFocused, height: nil))
                }
                .padding(.top, 16).rise(3)

                Button { picking = true } label: {
                    HStack(spacing: 10) {
                        IconView(.paperclip)
                        Text(attachment ?? "Attach a photo or file").font(Typo.manrope(14, .extrabold)).lineLimit(1)
                    }
                    .foregroundStyle(Palette.soft)
                    .frame(maxWidth: .infinity).frame(height: 76)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.white(0.03)))
                    .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white(0.22), style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
                }
                .pressable()
                .padding(.top, 14).rise(4)
            }
            BottomCTABar {
                PrimaryButton("Submit ticket", icon: .send, iconSize: 18) {
                    let id = state.createTicket(category: category, subject: subject, message: message)
                    router.go(.ticket(id), state: state)
                }
            }
        }
        .fileImporter(isPresented: $picking, allowedContentTypes: [.image, .pdf]) { result in
            // TODO: API — upload the attachment with the ticket
            if case let .success(url) = result { attachment = url.lastPathComponent }
        }
    }
}

#Preview {
    HelpView().environment(AppState.preview).environment(AppRouter()).background(AppBackground())
}
