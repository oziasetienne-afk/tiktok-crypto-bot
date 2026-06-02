import SwiftUI

@MainActor
final class ItemDetailViewModel: ObservableObject {
    @Published var sellOrders: [WFMOrder] = []
    @Published var stats: PriceStats?
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let service = MarketService.shared

    func load(urlName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let orders = try await service.sellOrders(for: urlName)
            sellOrders = orders
            // Price stats use the cheapest handful to avoid skew from outliers.
            let prices = orders.prefix(20).map(\.platinum)
            stats = PriceStats(prices: Array(prices))
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// Live sell orders for a single item, with a price summary on top.
struct ItemDetailView: View {
    let item: WFMItem
    @StateObject private var model = ItemDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                } else if let error = model.errorMessage {
                    ErrorView(message: error) {
                        Task { await model.load(urlName: item.urlName) }
                    }
                    .frame(height: 240)
                } else {
                    if let stats = model.stats {
                        PriceStatsRow(stats: stats)
                    }
                    sellList
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(item.itemName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load(urlName: item.urlName) }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Thumbnail(url: item.thumbURL, size: 64)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.itemName).font(.title3.weight(.bold))
                Text("Live sell orders").font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var sellList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SELLERS")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            if model.sellOrders.isEmpty {
                Text("No sellers online right now.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 20)
            } else {
                ForEach(model.sellOrders.prefix(40)) { order in
                    OrderRow(order: order)
                }
            }
        }
    }
}

/// A single seller line: name, status, quantity and platinum price.
struct OrderRow: View {
    let order: WFMOrder
    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.user?.ingameName ?? "Unknown")
                        .font(.body.weight(.medium))
                    HStack(spacing: 6) {
                        if let status = order.user?.status {
                            Pill(text: status.label, color: color(for: status))
                        }
                        if order.quantity > 1 {
                            Text("×\(order.quantity)").font(.caption).foregroundStyle(.secondary)
                        }
                        if let rank = order.modRank {
                            Text("rank \(rank)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                HStack(spacing: 4) {
                    Text("\(order.platinum)")
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(Theme.platinum)
                    Image(systemName: "p.circle.fill").foregroundStyle(Theme.platinum)
                }
            }
        }
    }

    private func color(for status: UserStatus) -> Color {
        switch status {
        case .ingame: return Theme.positive
        case .online: return Theme.accent
        case .offline: return .gray
        }
    }
}
