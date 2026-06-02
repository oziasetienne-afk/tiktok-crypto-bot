import SwiftUI

@MainActor
final class ItemSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [WFMItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = MarketService.shared

    /// Runs a search; called from `.task(id:)` so it cancels on each keystroke.
    func search() async {
        let term = query
        guard term.trimmingCharacters(in: .whitespaces).count >= 2 else {
            results = []
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            // Small debounce so we don't filter on every single character.
            try await Task.sleep(nanoseconds: 250_000_000)
            let items = try await service.searchItems(term)
            guard !Task.isCancelled else { return }
            results = Array(items.prefix(60))
        } catch is CancellationError {
            // Superseded by a newer keystroke — ignore.
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// Tab 1 — search any tradeable item and drill into its live orders.
struct ItemSearchView: View {
    @StateObject private var model = ItemSearchViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let error = model.errorMessage {
                    ErrorView(message: error)
                } else if model.query.count < 2 {
                    EmptyStateView(
                        systemImage: "magnifyingglass",
                        title: "Search the market",
                        subtitle: "Type at least 2 letters to look up any item and see live buy/sell prices."
                    )
                } else if model.results.isEmpty && !model.isLoading {
                    EmptyStateView(
                        systemImage: "questionmark.circle",
                        title: "No matches",
                        subtitle: "Nothing in the catalogue matches \"\(model.query)\"."
                    )
                } else {
                    List(model.results) { item in
                        NavigationLink(value: item) {
                            HStack(spacing: 12) {
                                Thumbnail(url: item.thumbURL)
                                Text(item.itemName).font(.body)
                            }
                        }
                        .listRowBackground(Theme.card)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background)
            .navigationTitle("Prices")
            .navigationDestination(for: WFMItem.self) { ItemDetailView(item: $0) }
            .searchable(text: $model.query, prompt: "e.g. Mirage Prime Set")
            .task(id: model.query) { await model.search() }
            .overlay { if model.isLoading { ProgressView() } }
        }
    }
}
