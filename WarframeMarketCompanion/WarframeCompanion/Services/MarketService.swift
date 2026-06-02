import Foundation

/// Reads the global item catalogue and live buy/sell orders.
final class MarketService {
    static let shared = MarketService()
    private let client = APIClient.shared

    private struct ItemsPayload: Decodable { let items: [WFMItem] }
    private struct OrdersPayload: Decodable { let orders: [WFMOrder] }
    private struct ItemDetailPayload: Decodable { let item: WFMItemDetail }

    /// In-memory cache of the (large) catalogue so we only download it once.
    private var cachedItems: [WFMItem]?

    /// Returns the full catalogue, downloading it on first use.
    func allItems() async throws -> [WFMItem] {
        if let cachedItems { return cachedItems }
        let payload: ItemsPayload = try await client.get("items")
        cachedItems = payload.items
        return payload.items
    }

    /// Case-insensitive substring search over the catalogue.
    func searchItems(_ query: String) async throws -> [WFMItem] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let items = try await allItems()
        guard !trimmed.isEmpty else { return [] }
        return items
            .filter { $0.itemName.range(of: trimmed, options: .caseInsensitive) != nil }
            .sorted { lhs, rhs in
                // Prefix matches first, then alphabetical.
                let lp = lhs.itemName.range(of: trimmed, options: [.caseInsensitive, .anchored]) != nil
                let rp = rhs.itemName.range(of: trimmed, options: [.caseInsensitive, .anchored]) != nil
                if lp != rp { return lp }
                return lhs.itemName < rhs.itemName
            }
    }

    /// All live orders for an item.
    func orders(for urlName: String) async throws -> [WFMOrder] {
        let payload: OrdersPayload = try await client.get("items/\(urlName)/orders")
        return payload.orders
    }

    /// Detailed info (set members, ducats, tax) for an item.
    func detail(for urlName: String) async throws -> WFMItemDetail {
        let payload: ItemDetailPayload = try await client.get("items/\(urlName)")
        return payload.item
    }

    /// Visible sell orders, cheapest first, in-game sellers prioritised.
    func sellOrders(for urlName: String) async throws -> [WFMOrder] {
        try await orders(for: urlName)
            .filter { $0.orderType == .sell && $0.visible }
            .sorted { lhs, rhs in
                let l = lhs.user?.status.sortRank ?? 99
                let r = rhs.user?.status.sortRank ?? 99
                if l != r { return l < r }
                return lhs.platinum < rhs.platinum
            }
    }
}
