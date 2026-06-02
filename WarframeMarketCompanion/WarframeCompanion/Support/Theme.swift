import SwiftUI

/// Centralised colours so the app keeps the dark, "console UI" feel that
/// Warframe tools tend to use.
enum Theme {
    static let background = Color(red: 0.07, green: 0.08, blue: 0.11)
    static let card = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let accent = Color(red: 0.20, green: 0.78, blue: 0.92)
    static let positive = Color(red: 0.30, green: 0.82, blue: 0.50)
    static let negative = Color(red: 0.92, green: 0.36, blue: 0.40)
    static let platinum = Color(red: 0.66, green: 0.78, blue: 0.95)
}

/// A reusable dark card container.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Small coloured pill used for statuses and tags.
struct Pill: View {
    let text: String
    var color: Color = Theme.accent
    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.18))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
