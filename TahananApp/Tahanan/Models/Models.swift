import Foundation

// MARK: - Project knowledge

struct Brand: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    /// Asset catalog name of the facade photo.
    let image: String
    let from: String
    let gmi: String
    let monthly: String
    let product: String
    let description: String
    let locations: [Location]

    /// Home carousel pill: "5 locations" or the single location's name.
    var carouselLocationLabel: String {
        locations.count > 1 ? "\(locations.count) locations" : locations[0].name
    }

    /// Brand hero: "5 locations" or "Brgy. Dolores, Magalang, Pampanga".
    var heroLocationLabel: String {
        locations.count > 1 ? "\(locations.count) locations" : "\(locations[0].barangay), \(locations[0].name)"
    }

    /// The streetscape photo: Pasinaya Homes has its own row shot, the others reuse the facade.
    var streetImage: String { id == "ph" ? "photoRow" : image }
}

struct Location: Codable, Hashable {
    let name: String
    let barangay: String
    let tcp: String
    let floorArea: String
    let lotArea: String
    let monthlyAmortization: String
    let gmi: String
}

// MARK: - Requirements

enum RequirementStatus: String, Codable {
    case accepted = "acc", reviewed = "rev", submitted = "sub", todo

    var label: String {
        switch self {
        case .accepted: return "Accepted"
        case .reviewed: return "Reviewed"
        case .submitted: return "Submitted"
        case .todo: return "To upload"
        }
    }

    /// How many of the three status steps are lit.
    var step: Int {
        switch self {
        case .accepted: return 3
        case .reviewed: return 2
        case .submitted: return 1
        case .todo: return 0
        }
    }
}

struct Requirement: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    /// "Principal buyer" or "Spouse".
    let owner: String
    var status: RequirementStatus
    var date: String?
}

// MARK: - Tickets

enum TicketStatus: String, Codable {
    case open, progress, resolved

    var label: String {
        switch self {
        case .open: return "Open"
        case .progress: return "In progress"
        case .resolved: return "Resolved"
        }
    }
}

struct TicketMessage: Codable, Identifiable, Hashable {
    enum Kind: String, Codable { case sys, me, them }

    var id = UUID()
    let kind: Kind
    let text: String
    var who: String?
    var time: String?
    var attachment: Bool

    enum CodingKeys: String, CodingKey { case kind, text, who, time, attachment }

    init(kind: Kind, text: String, who: String? = nil, time: String? = nil, attachment: Bool = false) {
        self.kind = kind
        self.text = text
        self.who = who
        self.time = time
        self.attachment = attachment
    }
}

struct Ticket: Codable, Identifiable, Hashable {
    let id: String
    var subject: String
    var category: String
    var status: TicketStatus
    var time: String
    var messages: [TicketMessage]

    var lastMessage: String {
        messages.last(where: { $0.kind != .sys })?.text ?? ""
    }
}

struct TicketsFile: Codable {
    let categories: [String]
    let tickets: [Ticket]
}

// MARK: - Buyer

struct BuyerProfile: Codable, Hashable {
    struct Seller: Codable, Hashable { let name: String; let initials: String }

    struct Unit: Codable, Hashable {
        let code: String
        let brandId: String
        let brandName: String
        let location: String
        let barangay: String
        let block: String
        let product: String
        let floorArea: String
        let lotArea: String
        let tcp: String
        let monthly: String
        let term: String
        let consultationFee: String
        let seller: Seller
        let referenceNo: String
    }

    var firstName: String
    var fullName: String
    var initials: String
    var homefulId: String
    var email: String
    var emailMasked: String
    var mobileMasked: String
    var emailVerified: Bool
    var mobileVerified: Bool
    var role: String
    var unit: Unit
    var address: String
    var grossMonthlyIncome: Int
    var requiredIncome: Int
}

struct Transaction: Codable, Identifiable, Hashable {
    enum Tone: String, Codable { case acc, sub, mut }
    enum Kind: String, Codable { case wallet, home, calendar }

    let id: String
    let title: String
    let subtitle: String
    let mono: Bool
    let amount: String?
    let status: String
    let tone: Tone
    let icon: Kind
}

struct ApplicationSection: Codable, Identifiable, Hashable {
    struct Field: Codable, Hashable { let key: String; let value: String }

    let id: String
    let title: String
    let subtitle: String
    let percent: Int
    let cta: String
    let fields: [Field]
}

// MARK: - Auth

struct AuthSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var userId: String
    var email: String
}
