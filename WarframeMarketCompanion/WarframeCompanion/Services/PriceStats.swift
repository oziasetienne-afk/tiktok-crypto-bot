import Foundation

/// Summary statistics computed from a set of prices (orders or auctions).
struct PriceStats {
    let count: Int
    let min: Int
    let max: Int
    let average: Int
    let median: Int

    /// Builds stats from a list of platinum prices. Returns `nil` when empty.
    init?(prices: [Int]) {
        guard !prices.isEmpty else { return nil }
        let sorted = prices.sorted()
        self.count = sorted.count
        self.min = sorted.first!
        self.max = sorted.last!
        self.average = Int((Double(sorted.reduce(0, +)) / Double(sorted.count)).rounded())
        if sorted.count.isMultiple(of: 2) {
            let lo = sorted[sorted.count / 2 - 1]
            let hi = sorted[sorted.count / 2]
            self.median = (lo + hi) / 2
        } else {
            self.median = sorted[sorted.count / 2]
        }
    }
}
