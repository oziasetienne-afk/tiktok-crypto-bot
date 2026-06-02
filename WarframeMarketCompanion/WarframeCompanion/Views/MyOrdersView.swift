import SwiftUI

@MainActor
final class MyOrdersViewModel: ObservableObject {
    @Published var sell: [WFMOrder] = []
    @Published var buy: [WFMOrder] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await AuthService.shared.myOrders()
            sell = result.sell
            buy = result.buy
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// Tab 3 — sign in and review your own Warframe Market listings.
struct MyOrdersView: View {
    @EnvironmentObject private var auth: AuthService
    @StateObject private var model = MyOrdersViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if auth.isAuthenticated {
                    ordersContent
                } else {
                    LoginView()
                }
            }
            .background(Theme.background)
            .navigationTitle("My Orders")
            .toolbar {
                if auth.isAuthenticated {
                    Button("Sign out") { auth.signOut() }
                }
            }
        }
    }

    @ViewBuilder
    private var ordersContent: some View {
        if model.isLoading {
            LoadingView()
        } else if let error = model.errorMessage {
            ErrorView(message: error) { Task { await model.load() } }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let name = auth.account?.ingameName {
                        Text("Signed in as \(name)")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    section(title: "SELLING (\(model.sell.count))", orders: model.sell)
                    section(title: "BUYING (\(model.buy.count))", orders: model.buy)
                }
                .padding()
            }
            .refreshable { await model.load() }
            .task { await model.load() }
        }
    }

    @ViewBuilder
    private func section(title: String, orders: [WFMOrder]) -> some View {
        Text(title).font(.caption2.weight(.bold)).foregroundStyle(.secondary)
        if orders.isEmpty {
            Text("Nothing here yet.").font(.callout).foregroundStyle(.secondary)
        } else {
            ForEach(orders) { OrderRow(order: $0) }
        }
    }
}

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signIn() async {
        isLoading = true
        errorMessage = nil
        do {
            try await AuthService.shared.signIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

/// Email/password form for signing into Warframe Market.
struct LoginView: View {
    @StateObject private var model = LoginViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.accent)
                Text("Connect to Warframe Market")
                    .font(.title3.weight(.bold))
                Text("Sign in with your warframe.market account to see your own buy and sell orders.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Card {
                    VStack(spacing: 12) {
                        TextField("Email", text: $model.email)
                            .textContentType(.username)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Divider()
                        SecureField("Password", text: $model.password)
                            .textContentType(.password)
                    }
                }

                if let error = model.errorMessage {
                    Text(error)
                        .font(.callout)
                        .foregroundStyle(Theme.negative)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await model.signIn() }
                } label: {
                    if model.isLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Sign in").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.email.isEmpty || model.password.isEmpty || model.isLoading)

                Text("Your credentials are sent only to warframe.market. The session token is stored in the iOS Keychain.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}
