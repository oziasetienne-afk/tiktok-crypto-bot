import Foundation

// MARK: - Riven catalogue (GET /riven/items, GET /riven/attributes)

/// A weapon that can roll a Riven mod.
struct RivenWeapon: Codable, Identifiable, Hashable {
    let id: String
    let urlName: String
    let itemName: String
    let group: String?
    let rivenType: String?
    let thumb: String?

    enum CodingKeys: String, CodingKey {
        case id
        case urlName = "url_name"
        case itemName = "item_name"
        case group
        case rivenType = "riven_type"
        case thumb
    }
}

/// A possible Riven stat (e.g. "Critical Chance").
struct RivenAttributeInfo: Codable, Identifiable, Hashable {
    let id: String
    let urlName: String
    let effect: String
    let units: String?
    let positiveIsNegative: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case urlName = "url_name"
        case effect
        case units
        case positiveIsNegative = "positive_is_negative"
    }
}

// MARK: - Auctions (GET /auctions/search?type=riven)

/// One stat line on a specific Riven mod instance.
struct RivenAuctionAttribute: Codable, Hashable, Identifiable {
    var id: String { urlName + "\(value)" }
    let positive: Bool
    let value: Double
    let urlName: String

    enum CodingKeys: String, CodingKey {
        case positive
        case value
        case urlName = "url_name"
    }
}

struct RivenAuctionItem: Codable, Hashable {
    let type: String
    let weaponUrlName: String
    let name: String          // the randomly generated riven name, e.g. "Crita-critacan"
    let modRank: Int?
    let reRolls: Int?
    let polarity: String?
    let masteryLevel: Int?
    let attributes: [RivenAuctionAttribute]

    enum CodingKeys: String, CodingKey {
        case type
        case weaponUrlName = "weapon_url_name"
        case name
        case modRank = "mod_rank"
        case reRolls = "re_rolls"
        case polarity
        case masteryLevel = "mastery_level"
        case attributes
    }
}

/// A Riven listing on Warframe Market's auction house.
struct RivenAuction: Codable, Identifiable, Hashable {
    let id: String
    let startingPrice: Int?
    let buyoutPrice: Int?
    let topBid: Int?
    let visible: Bool
    let owner: WFMUser?
    let item: RivenAuctionItem

    enum CodingKeys: String, CodingKey {
        case id
        case startingPrice = "starting_price"
        case buyoutPrice = "buyout_price"
        case topBid = "top_bid"
        case visible
        case owner
        case item
    }

    /// The most relevant "asking" price for sorting/statistics.
    var effectivePrice: Int? {
        buyoutPrice ?? startingPrice ?? topBid
    }
}
