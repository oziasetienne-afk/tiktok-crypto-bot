import SwiftUI

/// Tab 4 — what the app does, and an honest note on its limits vs. PC tools.
struct AboutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Warframe Market Companion")
                                .font(.title3.weight(.bold))
                            Text("Check item and Riven prices, and manage your own listings — straight from your iPhone.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }

                    featureCard(
                        icon: "magnifyingglass",
                        title: "Item prices",
                        text: "Search any tradeable item and see live sell orders, with in-game sellers shown first."
                    )
                    featureCard(
                        icon: "die.face.5",
                        title: "Riven price analysis",
                        text: "Pick a weapon to get low / median / average / high buyout prices across current Riven auctions."
                    )
                    featureCard(
                        icon: "tray.full",
                        title: "Your listings",
                        text: "Sign in to warframe.market to review your own buy and sell orders."
                    )

                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Why no live in-game inventory?", systemImage: "info.circle")
                                .font(.headline)
                            Text("PC tools like AlecaFrame read the game's log files on the same machine. iOS sandboxes every app, so a phone cannot read the game's live inventory. This app uses the public Warframe Market API instead.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("Not affiliated with Digital Extremes or warframe.market. Data © their respective owners.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(Theme.background)
            .navigationTitle("About")
        }
    }

    private func featureCard(icon: String, title: String, text: String) -> some View {
        Card {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Theme.accent)
                    .frame(width: 30)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(text).font(.callout).foregroundStyle(.secondary)
                }
            }
        }
    }
}
