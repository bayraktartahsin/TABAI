import SwiftUI

struct GenerationWelcomeCard: View {
    let generationType: GenerationType
    let onSuggestionTap: (String) -> Void

    @State private var pulseScale: CGFloat = 1.0

    private var icon: String {
        generationType == .image ? "sparkles" : "film"
    }

    private var title: String {
        generationType == .image ? "Create with TABAI Image" : "Create with TABAI Video"
    }

    private var suggestions: [String] {
        if generationType == .image {
            return [
                "A serene mountain lake at sunset",
                "Futuristic Tokyo neon cityscape",
                "Watercolor portrait of a cat",
                "Minimalist geometric logo"
            ]
        } else {
            return [
                "Ocean waves on a tropical beach",
                "Northern lights dancing in the sky",
                "Rain falling on a city street at night"
            ]
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DS.Colors.accent, DS.Colors.accent.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                            pulseScale = 1.03
                        }
                    }

                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(DS.Colors.textPrimary)

                Text("Describe anything you can imagine")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textSecondary)
            }

            Spacer().frame(height: 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            Haptics.impact(.light)
                            onSuggestionTap(suggestion)
                        } label: {
                            Text(suggestion)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(DS.Colors.textPrimary.opacity(0.8))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(DS.Colors.fieldBackground)
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(DS.Colors.accent.opacity(0.15), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }
}
