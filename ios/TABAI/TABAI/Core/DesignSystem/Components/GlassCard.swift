import SwiftUI

struct GlassCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DS.Layout.cardPadding)
            .background(DS.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                    .stroke(DS.Colors.glassStroke, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 6)
    }
}
