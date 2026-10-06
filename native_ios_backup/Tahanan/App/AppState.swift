import Observation
import SwiftUI

enum ApplicationTab: Int { case info = 0, requirements = 1 }
enum AboutDoc: Int { case privacy = 0, terms = 1 }

/// Bottom sheets layered over the current screen.
enum SheetKind: Equatable {
    case link, changeEmail, changeMobile, upload(requirementId: String)
}

/// Email verification card states on Account details (prototype `ev` 0–3).
enum EmailVerificationState: Int { case idle = 0, enterCode, openingLink, verified }

/// App-wide data and UI state shared across screens. Screen-local state lives in each view.
@MainActor
@Observable
final class AppState {
    // Data (from repositories)
    var brands: [Brand]
    var requirements: [Requirement]
    var tickets: [Ticket]
    var ticketCategories: [String]
    var profile: BuyerProfile?
    var transactions: [Transaction]
    var sections: [ApplicationSection]

    // Shared UI state
    var sheet: SheetKind?
    var toast: ToastData?
    var applicationTab: ApplicationTab = .info
    var biometricsEnabled = true
    var emailVerification: EmailVerificationState = .idle
    /// Set by the tahanan://auth/reset deep link so Forgot password opens on the new-password step.
    var forgotStartStep = 0
    var avatar: UIImage?
    /// "Typing…" indicator for the support agent, per ticket.
    var agentTyping: Set<String> = []

    let repos: Repositories
    let auth: AuthService
    let session: SessionManager

    init(repos: Repositories = .live, auth: AuthService = MockAuthService()) {
        self.repos = repos
        self.auth = auth
        session = SessionManager(auth: auth)
        // Bundled mock JSON is read synchronously so first render has data; `refresh()` reloads through the repositories.
        brands = MockJSON.loadOrEmpty("brands", empty: [])
        requirements = MockJSON.loadOrEmpty("requirements", empty: [])
        let t = MockJSON.loadOrEmpty("tickets", empty: TicketsFile(categories: [], tickets: []))
        tickets = t.tickets
        ticketCategories = t.categories
        profile = try? MockJSON.load("profile")
        transactions = MockJSON.loadOrEmpty("transactions", empty: [])
        sections = MockJSON.loadOrEmpty("application", empty: [])
        if let p = profile { emailVerification = p.emailVerified ? .verified : .idle }
    }

    func refresh() async {
        if let b = try? await repos.projects.brands() { brands = b }
        if let r = try? await repos.requirements.requirements() { requirements = r }
        if let t = try? await repos.tickets.load() { tickets = t.tickets; ticketCategories = t.categories }
        if let p = try? await repos.buyer.profile() { profile = p }
        if let x = try? await repos.buyer.transactions() { transactions = x }
        if let s = try? await repos.buyer.applicationSections() { sections = s }
    }

    // MARK: Toast

    func showToast(_ message: String, icon: Icon = .check, tint: Color = Palette.green) {
        toast = ToastData(message: message, icon: icon, tint: tint)
        let id = toast?.id
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_500_000_000)
            if self?.toast?.id == id { self?.toast = nil }
        }
    }

    // MARK: Requirements

    var todoCount: Int { requirements.filter { $0.status == .todo }.count }

    func requirement(_ id: String) -> Requirement? { requirements.first { $0.id == id } }

    func markSubmitted(_ id: String) {
        guard let i = requirements.firstIndex(where: { $0.id == id }) else { return }
        requirements[i].status = .submitted
        requirements[i].date = "Today"
    }

    // MARK: Tickets

    private let agent = "Homeful Support · Carla"

    func ticket(_ id: String) -> Ticket? { tickets.first { $0.id == id } }

    func send(_ text: String, to id: String) {
        guard let i = tickets.firstIndex(where: { $0.id == id }) else { return }
        tickets[i].messages.append(TicketMessage(kind: .me, text: text, time: "Now"))
        agentTyping.insert(id)
        Task { try? await repos.tickets.send(text, to: id) }
        // Demo: the agent replies after 1.8s, as in the prototype.
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard let self, let j = self.tickets.firstIndex(where: { $0.id == id }) else { return }
            self.agentTyping.remove(id)
            self.tickets[j].messages.append(TicketMessage(kind: .them, text: "Thanks, Maria! I’ve noted that on your ticket. We’ll update you here as soon as it’s reviewed.", who: self.agent, time: "Now"))
        }
    }

    /// Creates a ticket and returns its id (TK-1052, TK-1053, …).
    func createTicket(category: String, subject: String, message: String) -> String {
        let id = "TK-\(1052 + tickets.count - 3)"
        let subj = subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Question about my \(category.lowercased())" : subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let msg = message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Hi! I need help with my \(category.lowercased())." : message.trimmingCharacters(in: .whitespacesAndNewlines)
        let t = Ticket(id: id, subject: subj, category: category, status: .open, time: "Now", messages: [
            TicketMessage(kind: .sys, text: "Ticket opened · Today"),
            TicketMessage(kind: .me, text: msg, time: "Now"),
        ])
        tickets.insert(t, at: 0)
        agentTyping.insert(id)
        Task { _ = try? await repos.tickets.create(category: category, subject: subj, message: msg) }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            guard let self, let j = self.tickets.firstIndex(where: { $0.id == id }) else { return }
            self.agentTyping.remove(id)
            self.tickets[j].messages.append(TicketMessage(kind: .them, text: "Hi Maria! Thanks for reaching out — I’m looking into this now.", who: self.agent, time: "Now"))
        }
        return id
    }
}

extension AppState {
    /// Preview/demo instance.
    static var preview: AppState { AppState(repos: .mock) }
}
