import SwiftUI

@main
struct WarframeCompanionApp: App {
    @StateObject private var auth = AuthService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

/// Top-level tab navigation for the four MVP areas.
struct RootView: View {
    var body: some View {
        TabView {
            ItemSearchView()
                .tabItem { Label("Prices", systemImage: "magnifyingglass") }

            RivenSearchView()
                .tabItem { Label("Rivens", systemImage: "die.face.5") }

            MyOrdersView()
                .tabItem { Label("My Orders", systemImage: "tray.full") }

            AboutView()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
    }
}
