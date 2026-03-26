import SwiftUI

struct GenerationStatusView: View {
    let generationType: GenerationType
    let progress: String?
    let onCancel: () -> Void

    @State private var shimmerPhase: CGFloat = -1.0
    @State private var iconRotation: Double = 0

    private var aspectRatio: CGFloat {
        switch generationType {
        case .image: return 1.0
        case .video, .imageToVideo: return 16.0 / 9.0
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            GeometryReader { geo in
                let width = geo.size.width
                let height = width / aspectRatio

                ZStack {
                    // Shimmer background
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(DS.Colors.fieldBackground)
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .white.opacity(0),
                                    .white.opacity(0.06),
                                    .white.opacity(0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .rotationEffect(.degrees(25))
                            .offset(x: shimmerPhase * width * 1.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Center content
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundStyle(DS.Colors.accent)
                            .rotationEffect(.degrees(iconRotation))

                        Text(progress ?? "Creating...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DS.Colors.textPrimary.opacity(0.7))
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(width: width, height: height)
            }
            .aspectRatio(aspectRatio, contentMode: .fit)

            Button {
                Haptics.impact(.light)
                onCancel()
            } label: {
                Text("Cancel")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                shimmerPhase = 1.0
            }
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                iconRotation = 360
            }
        }
        .transition(.scale(scale: 0.96).combined(with: .opacity))
    }
}
