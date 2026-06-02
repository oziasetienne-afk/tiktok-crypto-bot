import Foundation

// MARK: - Item (short form, returned by GET /items)

/// A tradeable item as listed in the global Warframe Market catalogue.
struct WFMItem: Codable, Identifiable, Hashable {
    let id: String
    let urlName: String
    let itemName: String
    let thumb: String?

    enum CodingKeys: String, CodingKey {
        case id
        case urlName = "url_name"
        case itemName = "item_name"
        case thumb
    }

    /// Full URL of the small thumbnail hosted by Warframe Market.
    var thumbURL: URL? {
        guard let thumb else { return nil }
        return URL(string: "https://warframe.market/static/assets/\(thumb)")
    }
}

// MARK: - Item detail (GET /items/{url_name})

/// Detailed item info, including every part that belongs to the same set.
struct WFMItemDetail: Codable, Hashable {
    let id: String
    let itemsInSet: [WFMItemInSet]

    enum CodingKeys: String, CodingKey {
        case id
        case itemsInSet = "items_in_set"
    }

    /// The "main" entry whose `url_name` matches the requested item.
    func entry(for urlName: String) -> WFMItemInSet? {
        itemsInSet.first { $0.urlName == urlName }
    }
}

struct WFMItemInSet: Codable, Hashable {
    let id: String
    let urlName: String
    let thumb: String?
    let tags: [String]?
    let tradingTax: Int?
    let ducats: Int?
    let setRoot: Bool?
    let en: WFMItemLanguage?

    enum CodingKeys: String, CodingKey {
        case id
        case urlName = "url_name"
        case thumb
        case tags
        case tradingTax = "trading_tax"
        case ducats
        case setRoot = "set_root"
        case en
    }

    var displayName: String { en?.itemName ?? urlName }
}

struct WFMItemLanguage: Codable, Hashable {
    let itemName: String?
    let description: String?
    let wikiLink: String?

    enum CodingKeys: String, CodingKey {
        case itemName = "item_name"
        case description
        case wikiLink = "wiki_link"
    }
}
