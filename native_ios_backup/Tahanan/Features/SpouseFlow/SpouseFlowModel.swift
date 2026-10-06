import Foundation
import Observation

/// State and validation for "Complete spouse details" (design/buyer/S00–S08).
@MainActor
@Observable
final class SpouseFlowModel {
    enum Screen: Equatable { case intro, idScan, step(Int), done, invite }
    enum ScanState { case idle, reading, ok }

    struct IDType: Identifiable { let id: String, label: String, placeholder: String }
    struct Employment: Identifiable { let id: String, label: String, sub: String }

    static let steps = ["Personal", "Address & ID", "Work & income", "Review"]
    static let idTypes = [
        IDType(id: "philsys", label: "PhilSys ID", placeholder: "0000-0000-0000-0000"),
        IDType(id: "umid", label: "UMID", placeholder: "0000-0000000-0"),
        IDType(id: "passport", label: "Passport", placeholder: "P0000000A"),
        IDType(id: "dl", label: "Driver’s license", placeholder: "N00-00-000000"),
        IDType(id: "prc", label: "PRC ID", placeholder: "0000000"),
    ]
    static let employment = [
        Employment(id: "emp", label: "Employed", sub: "Private or government"),
        Employment(id: "self", label: "Self-employed", sub: "Business or freelance"),
        Employment(id: "ofw", label: "OFW", sub: "Working abroad"),
        Employment(id: "none", label: "Not working", sub: "No regular income"),
    ]

    var screen: Screen = .intro
    var scan: ScanState = .idle
    var fromId = false
    var touched = false

    // Personal
    var first = ""
    var middle = ""
    var suffix = ""
    var last = ""
    var noMiddleName = false
    var birthdate: Date?
    var sex = "Male"
    var citizenship = "Filipino"
    var mobile = ""
    var email = ""

    // Address & ID
    var sameAddress = true
    var street = ""
    var barangay = ""
    var city = ""
    var province = ""
    var zip = ""
    var idType = "philsys"
    var idNumber = ""
    var tin = ""

    // Work & income
    var employmentType = "emp"
    var employer = ""
    var position = ""
    var years = 4
    var incomeDigits = ""

    // Review
    var consent = true

    // Invite
    var inviteName = ""
    var inviteMobile = ""
    var inviteSent = false

    /// Buyer's own income and the location's required GMI.
    let mine: Int
    let required: Int

    init(mine: Int = 22000, required: Int = 14000) {
        self.mine = mine
        self.required = required
    }

    var stepIndex: Int? { if case let .step(i) = screen { return i }; return nil }

    var mobileDigits: String { mobile.filter(\.isNumber) }

    /// "Enter 10 digits, starting with 9" once the user has typed.
    var mobileError: Bool {
        touched && !mobileDigits.isEmpty && !(mobileDigits.count == 10 && mobileDigits.first == "9")
    }

    func isValid(_ step: Int) -> Bool {
        switch step {
        case 0: return !first.isEmpty && !last.isEmpty && birthdate != nil && !mobileError && mobileDigits.count == 10
        case 1: return !idNumber.isEmpty
        case 2: return employmentType == "none" || (!employer.isEmpty && !incomeDigits.isEmpty)
        default: return consent
        }
    }

    var spouseIncome: Int { employmentType == "none" ? 0 : Int(incomeDigits) ?? 0 }
    var total: Int { mine + spouseIncome }
    var scale: Double { Double(max(total, Int(Double(required) * 1.2), 40000)) }

    var idTypeInfo: IDType { Self.idTypes.first { $0.id == idType } ?? Self.idTypes[0] }

    var employerLabel: String {
        switch employmentType {
        case "self": return "Business name"
        case "ofw": return "Employer abroad"
        case "none": return ""
        default: return "Employer"
        }
    }

    var fullName: String {
        [first, middle, last, suffix].filter { !$0.isEmpty }.joined(separator: " ")
    }

    var birthdateText: String {
        guard let birthdate else { return "—" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: birthdate)
    }

    static func peso(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US")
        return "₱" + (f.string(from: NSNumber(value: n)) ?? "\(n)")
    }

    var incomeDisplay: String {
        guard let n = Int(incomeDigits) else { return "" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: n)) ?? incomeDigits
    }

    var gmiMessage: String {
        spouseIncome > 0
            ? "Combined, you’re at \(String(format: "%.1f", Double(total) / Double(required)))× the required income — a stronger loan application."
            : "Your income already meets the required \(Self.peso(required))."
    }

    /// Prototype autofill after reading the ID (name, birthdate and ID number).
    func applyScannedID(idNumber scanned: String?) {
        first = "Jose"; middle = "Reyes"; last = "Santos"
        var c = DateComponents(); c.year = 1990; c.month = 3; c.day = 14
        birthdate = Calendar(identifier: .gregorian).date(from: c)
        idNumber = scanned ?? "1234-5678-9012-2048"
        fromId = true
    }

    func resetManual() {
        first = ""; middle = ""; suffix = ""; last = ""; birthdate = nil; mobile = ""; email = ""; idNumber = ""
        fromId = false
        touched = false
    }
}
