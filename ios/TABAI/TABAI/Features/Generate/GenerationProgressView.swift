import SwiftUI

struct GenerationProgressView: View {
    let text: String
    let queuePosition: Int?
    let onCancel: () -> Void
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        VStack(spacing: 16) {
            // Shimmer placeholder
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DS.Colors.fieldBackground)
                .frame(height: 180)
                .overlay {
                    LinearGradient(
                        colors: [
                            DS.Colors.accent.opacity(0.0),
                            DS.Colors.accent.opacity(0.15),
                            DS.Colors.accent.opacity(0.0),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: shimmerPhase * 300)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(DS.Colors.glassStroke, lineWidth: 0.5)
                )
                .overlay {
                    VStack(spacing: 8) {
                        ProgressView()
                            .tint(DS.Colors.accent)

                        Text(text)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                }

            Button {
                Haptics.impact(.light)
                onCancel()
            } label: {
                Text("Cancel")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(DS.Colors.fieldBackground)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: true)) {
                shimmerPhase = 1
            }
        }
    }
}
