import Foundation

/// Reads the Riven catalogue and searches the Riven auction house.
final class RivenService {
    static let shared = RivenService()
    private let client = APIClient.shared

    private struct WeaponsPayload: Decodable { let items: [RivenWeapon] }
    private struct AttributesPayload: Decodable { let attributes: [RivenAttributeInfo] }
    private struct AuctionsPayload: Decodable { let auctions: [RivenAuction] }

    private var cachedWeapons: [RivenWeapon]?
    private var cachedAttributes: [RivenAttributeInfo]?

    /// Weapons that can carry a Riven, downloaded once and cached.
    func weapons() async throws -> [RivenWeapon] {
        if let cachedWeapons { return cachedWeapons }
        let payload: WeaponsPayload = try await client.get("riven/items")
        let sorted = payload.items.sorted { $0.itemName < $1.itemName }
        cachedWeapons = sorted
        return sorted
    }

    func searchWeapons(_ query: String) async throws -> [RivenWeapon] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let weapons = try await weapons()
        guard !trimmed.isEmpty else { return weapons }
        return weapons.filter { $0.itemName.range(of: trimmed, options: .caseInsensitive) != nil }
    }

    /// All possible Riven stats, for translating attribute url-names to labels.
    func attributes() async throws -> [RivenAttributeInfo] {
        if let cachedAttributes { return cachedAttributes }
        let payload: AttributesPayload = try await client.get("riven/attributes")
        cachedAttributes = payload.attributes
        return payload.attributes
    }

    /// Searches Riven auctions for a weapon, cheapest buyout first.
    func auctions(forWeapon urlName: String) async throws -> [RivenAuction] {
        let query = [
            URLQueryItem(name: "type", value: "riven"),
            URLQueryItem(name: "weapon_url_name", value: urlName),
            URLQueryItem(name: "sort_by", value: "price_asc"),
            URLQueryItem(name: "buyout_policy", value: "direct")
        ]
        let payload: AuctionsPayload = try await client.get("auctions/search", query: query)
        return payload.auctions
            .filter { $0.visible }
            .sorted { ($0.effectivePrice ?? .max) < ($1.effectivePrice ?? .max) }
    }

    /// Price statistics across the visible auctions for a weapon.
    func priceStats(forWeapon urlName: String) async throws -> (stats: PriceStats?, auctions: [RivenAuction]) {
        let auctions = try await auctions(forWeapon: urlName)
        let prices = auctions.compactMap { $0.effectivePrice }
        return (PriceStats(prices: prices), auctions)
    }
}
