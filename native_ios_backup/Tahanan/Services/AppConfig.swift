import Foundation

/// Values injected from Config.xcconfig through Info.plist. Never hardcode secrets here.
enum AppConfig {
    private static func value(_ key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    static var useMockData: Bool { value("TahananUseMockData").uppercased() != "NO" }
    static var supabaseURL: URL? { URL(string: value("TahananSupabaseURL")) }
    static var supabaseAnonKey: String { value("TahananSupabaseAnonKey") }
    static var apiBaseURL: URL? { URL(string: value("TahananAPIBaseURL")) }

    /// API tokens expire every 3 hours.
    static let tokenLifetime: TimeInterval = 3 * 60 * 60
    /// Refresh this long before expiry.
    static let refreshLeeway: TimeInterval = 5 * 60
}
