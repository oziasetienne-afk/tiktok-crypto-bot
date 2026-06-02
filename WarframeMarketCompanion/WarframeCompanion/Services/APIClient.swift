import Foundation

/// Errors surfaced by the networking layer.
enum APIError: LocalizedError {
    case invalidURL
    case http(status: Int, message: String?)
    case decoding(Error)
    case transport(Error)
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL."
        case let .http(status, message):
            return message ?? "Server returned HTTP \(status)."
        case let .decoding(error):
            return "Could not read the server response (\(error.localizedDescription))."
        case let .transport(error):
            return error.localizedDescription
        case .notAuthenticated:
            return "You need to sign in to Warframe Market first."
        }
    }
}

/// Every Warframe Market response wraps its data in a `payload` object.
private struct Payload<T: Decodable>: Decodable {
    let payload: T
}

/// Some endpoints (auth, errors) return `{ "error": { "_form": ["..."] } }`.
private struct WFMErrorBody: Decodable {
    let error: [String: [String]]?

    var firstMessage: String? {
        error?.values.first?.first
    }
}

/// Thin async wrapper around `URLSession` that knows Warframe Market's
/// conventions: the `/v1` base path, the required platform/language headers,
/// and the `payload` envelope.
final class APIClient {
    static let shared = APIClient()

    private let baseURL = URL(string: "https://api.warframe.market/v1")!
    private let session: URLSession
    private let decoder: JSONDecoder

    /// JWT returned after a successful sign-in. Sent as `Authorization`.
    var authToken: String?

    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }

    // MARK: - Request building

    private func makeRequest(
        path: String,
        method: String = "GET",
        query: [URLQueryItem] = [],
        body: Data? = nil
    ) throws -> URLRequest {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )
        if !query.isEmpty { components?.queryItems = query }
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Warframe Market requires these to scope catalogue + prices.
        request.setValue("pc", forHTTPHeaderField: "platform")
        request.setValue("en", forHTTPHeaderField: "language")
        if let authToken {
            request.setValue(authToken, forHTTPHeaderField: "Authorization")
        }
        return request
    }

    // MARK: - Core call

    /// Performs a request and decodes the `payload` into `T`.
    func get<T: Decodable>(
        _ path: String,
        query: [URLQueryItem] = [],
        as type: T.Type = T.self
    ) async throws -> T {
        let request = try makeRequest(path: path, query: query)
        return try await send(request)
    }

    func post<T: Decodable>(
        _ path: String,
        body: Encodable,
        as type: T.Type = T.self
    ) async throws -> T {
        let data = try JSONEncoder().encode(AnyEncodable(body))
        let request = try makeRequest(path: path, method: "POST", body: data)
        return try await send(request)
    }

    /// Sends a request, captures the auth header on the way out, and decodes.
    func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(status: -1, message: "No HTTP response.")
        }

        // Sign-in returns a fresh JWT in the Authorization header — keep it.
        if let token = http.value(forHTTPHeaderField: "Authorization") {
            authToken = token
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = (try? decoder.decode(WFMErrorBody.self, from: data))?.firstMessage
            throw APIError.http(status: http.statusCode, message: message)
        }

        do {
            return try decoder.decode(Payload<T>.self, from: data).payload
        } catch {
            throw APIError.decoding(error)
        }
    }
}

/// Type-erased `Encodable` so we can pass heterogeneous request bodies.
struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init(_ wrapped: Encodable) {
        self.encodeFunc = wrapped.encode
    }
    func encode(to encoder: Encoder) throws {
        try encodeFunc(encoder)
    }
}
