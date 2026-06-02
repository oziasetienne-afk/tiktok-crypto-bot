import SwiftUI

@MainActor
final class RivenSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var weapons: [RivenWeapon] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = RivenService.shared

    func loadWeapons() async {
        guard weapons.isEmpty else { return }
        isLoading = true
        do {
            weapons = try await service.weapons()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var filtered: [RivenWeapon] {
        let term = query.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return weapons }
        return weapons.filter { $0.itemName.range(of: term, options: .caseInsensitive) != nil }
    }
}

/// Tab 2 — pick a weapon, then analyse its Riven auction prices.
struct RivenSearchView: View {
    @StateObject private var model = RivenSearchViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if let error = model.errorMessage {
                    ErrorView(message: error) { Task { await model.loadWeapons() } }
                } else if model.isLoading && model.weapons.isEmpty {
                    LoadingView(message: "Loading weapons…")
                } else {
                    List(model.filtered) { weapon in
                        NavigationLink(value: weapon) {
                            Text(weapon.itemName)
                        }
                        .listRowBackground(Theme.card)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.background)
            .navigationTitle("Riven Prices")
            .navigationDestination(for: RivenWeapon.self) { RivenDetailView(weapon: $0) }
            .searchable(text: $model.query, prompt: "Weapon name, e.g. Kuva Bramma")
            .task { await model.loadWeapons() }
        }
    }
}
