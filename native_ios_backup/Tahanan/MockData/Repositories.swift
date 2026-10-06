import Foundation

// Repository protocols sit between the UI and data. The demo build ships mock implementations
// that read the JSON in MockData/JSON; swap in API-backed versions in `Repositories.live`.

protocol ProjectRepository {
    func brands() async throws -> [Brand]
}

protocol BuyerRepository {
    func profile() async throws -> BuyerProfile
    func transactions() async throws -> [Transaction]
    func applicationSections() async throws -> [ApplicationSection]
    func linkAccount(homefulId: String, otp: String) async throws
}

protocol RequirementsRepository {
    func requirements() async throws -> [Requirement]
    func upload(requirementId: String, fileData: Data?, filename: String) async throws -> Requirement
}

protocol TicketRepository {
    func load() async throws -> TicketsFile
    func send(_ text: String, to ticketId: String) async throws
    func create(category: String, subject: String, message: String) async throws -> Ticket
}

struct Repositories {
    var projects: ProjectRepository
    var buyer: BuyerRepository
    var requirements: RequirementsRepository
    var tickets: TicketRepository

    static let mock = Repositories(
        projects: MockProjectRepository(),
        buyer: MockBuyerRepository(),
        requirements: MockRequirementsRepository(),
        tickets: MockTicketRepository()
    )

    /// TODO: API — return API-backed repositories when `AppConfig.useMockData` is false.
    static var live: Repositories { mock }
}

enum MockJSON {
    static func load<T: Decodable>(_ name: String, as type: T.Type = T.self) throws -> T {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile, userInfo: [NSFilePathErrorKey: "\(name).json"])
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }

    /// Synchronous load for previews and first render; falls back to an empty value on failure.
    static func loadOrEmpty<T: Decodable>(_ name: String, empty: T) -> T {
        (try? load(name, as: T.self)) ?? empty
    }
}

struct MockProjectRepository: ProjectRepository {
    // TODO: API — GET /api/v1/brands (CMS project knowledge: brand → locations → slides, gallery)
    func brands() async throws -> [Brand] { try MockJSON.load("brands") }
}

struct MockBuyerRepository: BuyerRepository {
    // TODO: API — GET /api/v1/me
    func profile() async throws -> BuyerProfile { try MockJSON.load("profile") }
    // TODO: API — GET /api/v1/me/transactions
    func transactions() async throws -> [Transaction] { try MockJSON.load("transactions") }
    // TODO: API — GET /api/v1/me/application
    func applicationSections() async throws -> [ApplicationSection] { try MockJSON.load("application") }
    // TODO: API — POST /api/v1/me/link-account { homefulId } then POST /verify { otp }
    func linkAccount(homefulId: String, otp: String) async throws {}
}

struct MockRequirementsRepository: RequirementsRepository {
    // TODO: API — GET /api/v1/me/requirements
    func requirements() async throws -> [Requirement] { try MockJSON.load("requirements") }

    // TODO: API — multipart POST /api/v1/me/requirements/{id}/files (Supabase Storage signed upload)
    func upload(requirementId: String, fileData: Data?, filename: String) async throws -> Requirement {
        let all: [Requirement] = try MockJSON.load("requirements")
        guard var r = all.first(where: { $0.id == requirementId }) else { throw CocoaError(.fileNoSuchFile) }
        r.status = .submitted
        r.date = "Today"
        return r
    }
}

struct MockTicketRepository: TicketRepository {
    // TODO: API — GET /api/v1/me/tickets and GET /api/v1/ticket-categories
    func load() async throws -> TicketsFile { try MockJSON.load("tickets") }
    // TODO: API — POST /api/v1/me/tickets/{id}/messages
    func send(_ text: String, to ticketId: String) async throws {}
    // TODO: API — POST /api/v1/me/tickets
    func create(category: String, subject: String, message: String) async throws -> Ticket {
        Ticket(id: "TK-0000", subject: subject, category: category, status: .open, time: "Now", messages: [])
    }
}
