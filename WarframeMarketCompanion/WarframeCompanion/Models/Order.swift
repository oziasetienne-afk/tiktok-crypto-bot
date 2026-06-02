import Foundation

enum OrderType: String, Codable {
    case sell
    case buy
}

/// Online presence of the trader, as reported by Warframe Market.
enum UserStatus: String, Codable {
    case ingame
    case online
    case offline

    var label: String {
        switch self {
        case .ingame: return "In game"
        case .online: return "Online"
        case .offline: return "Offline"
        }
    }

    /// In-game traders are the most likely to answer right now.
    var sortRank: Int {
        switch self {
        case .ingame: return 0
        case .online: return 1
        case .offline: return 2
        }
    }
}

struct WFMUser: Codable, Hashable {
    let id: String
    let ingameName: String
    let status: UserStatus
    let reputation: Int?
    let region: String?

    enum CodingKeys: String, CodingKey {
        case id
        case ingameName = "ingame_name"
        case status
        case reputation
        case region
    }
}

/// A single buy or sell order for an item.
struct WFMOrder: Codable, Identifiable, Hashable {
    let id: String
    let platinum: Int
    let quantity: Int
    let orderType: OrderType
    let modRank: Int?
    let visible: Bool
    let user: WFMUser?

    enum CodingKeys: String, CodingKey {
        case id
        case platinum
        case quantity
        case orderType = "order_type"
        case modRank = "mod_rank"
        case visible
        case user
    }
}
