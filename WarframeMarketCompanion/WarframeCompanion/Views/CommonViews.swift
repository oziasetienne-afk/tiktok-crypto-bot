import SwiftUI

/// Standard "spinner + message" placeholder.
struct LoadingView: View {
    var message: String = "Loading…"
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(message).foregroundStyle(.secondary).font(.callout)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Standard error placeholder with a retry button.
struct ErrorView: View {
    let message: String
    var retry: (() -> Void)?
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(Theme.negative)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            if let retry {
                Button("Try again", action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Empty-state placeholder.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var subtitle: String?
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 42))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// One statistic in a row of price stats.
struct StatCard: View {
    let title: String
    let value: String
    var color: Color = Theme.platinum
    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(color)
            }
        }
    }
}

/// Horizontal strip of min / median / avg / max stats.
struct PriceStatsRow: View {
    let stats: PriceStats
    var body: some View {
        HStack(spacing: 10) {
            StatCard(title: "Low", value: "\(stats.min)", color: Theme.positive)
            StatCard(title: "Median", value: "\(stats.median)")
            StatCard(title: "Avg", value: "\(stats.average)")
            StatCard(title: "High", value: "\(stats.max)", color: Theme.negative)
        }
    }
}

/// Thumbnail loader with a placeholder, shared by item rows.
struct Thumbnail: View {
    let url: URL?
    var size: CGFloat = 44
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case let .success(image):
                image.resizable().scaledToFit()
            default:
                Image(systemName: "shippingbox")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .background(Theme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
