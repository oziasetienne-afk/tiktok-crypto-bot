import Foundation

/// The signed-in Warframe Market account.
struct WFMAccount: Codable, Hashable {
    let id: String
    let ingameName: String
    let checkCode: String?
    let avatar: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ingameName = "ingame_name"
        case checkCode = "check_code"
        case avatar
    }
}

/// Handles sign-in, session persistence, and reading the user's own orders.
///
/// `@MainActor` so SwiftUI views can observe `account` / `isAuthenticated`
/// directly without dispatching.
@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var account: WFMAccount?
    private let client = APIClient.shared

    private let tokenKey = "jwt"
    private let nameKey = "ingame_name"

    var isAuthenticated: Bool { account != nil }

    private init() {
        restoreSession()
    }

    // MARK: - Request/response shapes

    private struct SignInBody: Encodable {
        let email: String
        let password: String
        let authType = "header"
        enum CodingKeys: String, CodingKey {
            case email, password
            case authType = "auth_type"
        }
    }
    private struct SignInPayload: Decodable { let user: WFMAccount }
    private struct ProfileOrdersPayload: Decodable {
        let sellOrders: [WFMOrder]
        let buyOrders: [WFMOrder]
        enum CodingKeys: String, CodingKey {
            case sellOrders = "sell_orders"
            case buyOrders = "buy_orders"
        }
    }

    // MARK: - Session lifecycle

    private func restoreSession() {
        guard let token = Keychain.get(tokenKey),
              let name = Keychain.get(nameKey) else { return }
        client.authToken = token
        // We trust the stored identity; a failing call will prompt re-login.
        account = WFMAccount(id: "", ingameName: name, checkCode: nil, avatar: nil)
    }

    func signIn(email: String, password: String) async throws {
        let body = SignInBody(email: email, password: password)
        let payload: SignInPayload = try await client.post("auth/signin", body: body)
        account = payload.user
        if let token = client.authToken {
            Keychain.set(token, for: tokenKey)
        }
        Keychain.set(payload.user.ingameName, for: nameKey)
    }

    func signOut() {
        account = nil
        client.authToken = nil
        Keychain.delete(tokenKey)
        Keychain.delete(nameKey)
    }

    // MARK: - The user's own listings

    /// Sell + buy orders for the signed-in account (public profile endpoint).
    func myOrders() async throws -> (sell: [WFMOrder], buy: [WFMOrder]) {
        guard let name = account?.ingameName else { throw APIError.notAuthenticated }
        let payload: ProfileOrdersPayload = try await client.get("profile/\(name)/orders")
        return (payload.sellOrders, payload.buyOrders)
    }
}
