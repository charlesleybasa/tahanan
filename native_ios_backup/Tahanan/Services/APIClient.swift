import Foundation

/// Thin client for the CMS REST API (`/api/v1`). Not called in the demo build (mock repositories),
/// but ready for the live repositories: it attaches the bearer token and refreshes once on 401.
@MainActor
final class APIClient {
    private let baseURL: URL
    private let session: SessionManager
    private let urlSession: URLSession

    init?(session: SessionManager, urlSession: URLSession = .shared) {
        guard let base = AppConfig.apiBaseURL else { return nil }
        baseURL = base
        self.session = session
        self.urlSession = urlSession
    }

    func get<T: Decodable>(_ path: String, as type: T.Type = T.self) async throws -> T {
        try await send(request(path, method: "GET"))
    }

    func post<T: Decodable, B: Encodable>(_ path: String, body: B, as type: T.Type = T.self) async throws -> T {
        var req = request(path, method: "POST")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(body)
        return try await send(req)
    }

    private func request(_ path: String, method: String) -> URLRequest {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        if let token = session.session?.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    private func send<T: Decodable>(_ req: URLRequest, retried: Bool = false) async throws -> T {
        let (data, response) = try await urlSession.data(for: req)
        if (response as? HTTPURLResponse)?.statusCode == 401, !retried {
            await session.refresh()
            var again = req
            if let token = session.session?.accessToken {
                again.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            return try await send(again, retried: true)
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AuthError.network
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
