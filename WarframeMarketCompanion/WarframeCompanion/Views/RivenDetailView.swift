import SwiftUI

@MainActor
final class RivenDetailViewModel: ObservableObject {
    @Published var auctions: [RivenAuction] = []
    @Published var stats: PriceStats?
    @Published var attributeLabels: [String: String] = [:]
    @Published var isLoading = true
    @Published var errorMessage: String?

    private let service = RivenService.shared

    func load(weapon urlName: String) async {
        isLoading = true
        errorMessage = nil
        do {
            async let attrs = service.attributes()
            let (stats, auctions) = try await service.priceStats(forWeapon: urlName)
            self.stats = stats
            self.auctions = auctions
            // Map attribute url-names to readable effects ("crit_chance" → "Critical Chance").
            attributeLabels = Dictionary(
                uniqueKeysWithValues: try await attrs.map { ($0.urlName, $0.effect) }
            )
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func label(for urlName: String) -> String {
        attributeLabels[urlName] ?? urlName.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

/// Price summary + individual Riven listings for one weapon.
struct RivenDetailView: View {
    let weapon: RivenWeapon
    @StateObject private var model = RivenDetailViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if model.isLoading {
                    ProgressView().frame(maxWidth: .infinity).padding(.top, 40)
                } else if let error = model.errorMessage {
                    ErrorView(message: error) {
                        Task { await model.load(weapon: weapon.urlName) }
                    }
                    .frame(height: 240)
                } else if model.auctions.isEmpty {
                    EmptyStateView(
                        systemImage: "die.face.5",
                        title: "No live auctions",
                        subtitle: "No \(weapon.itemName) rivens are listed for direct sale right now."
                    )
                    .frame(height: 300)
                } else {
                    if let stats = model.stats {
                        Text("BUYOUT PRICE (\(stats.count) listings)")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                        PriceStatsRow(stats: stats)
                    }
                    Text("LISTINGS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                    ForEach(model.auctions.prefix(40)) { auction in
                        RivenAuctionRow(auction: auction) { model.label(for: $0) }
                    }
                }
            }
            .padding()
        }
        .background(Theme.background)
        .navigationTitle(weapon.itemName)
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load(weapon: weapon.urlName) }
    }
}

/// A single Riven listing: name, re-rolls, stat lines and price.
struct RivenAuctionRow: View {
    let auction: RivenAuction
    let labelProvider: (String) -> String

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(auction.item.name.capitalized)
                        .font(.headline)
                    Spacer()
                    if let price = auction.effectivePrice {
                        HStack(spacing: 4) {
                            Text("\(price)")
                                .font(.title3.weight(.bold).monospacedDigit())
                                .foregroundStyle(Theme.platinum)
                            Image(systemName: "p.circle.fill").foregroundStyle(Theme.platinum)
                        }
                    }
                }

                HStack(spacing: 6) {
                    if let status = auction.owner?.status {
                        Pill(text: status.label,
                             color: status == .ingame ? Theme.positive : Theme.accent)
                    }
                    if let rolls = auction.item.reRolls {
                        Pill(text: "\(rolls) rolls", color: .gray)
                    }
                    if let mr = auction.item.masteryLevel {
                        Pill(text: "MR \(mr)", color: .gray)
                    }
                }

                ForEach(auction.item.attributes) { attr in
                    HStack {
                        Image(systemName: attr.positive ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)
                            .foregroundStyle(attr.positive ? Theme.positive : Theme.negative)
                        Text(labelProvider(attr.urlName))
                            .font(.caption)
                        Spacer()
                        Text(formatted(attr.value))
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(attr.positive ? Theme.positive : Theme.negative)
                    }
                }

                if let seller = auction.owner?.ingameName {
                    Text("Seller: \(seller)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        let sign = value > 0 ? "+" : ""
        if value == value.rounded() {
            return "\(sign)\(Int(value))"
        }
        return "\(sign)\(String(format: "%.1f", value))"
    }
}
