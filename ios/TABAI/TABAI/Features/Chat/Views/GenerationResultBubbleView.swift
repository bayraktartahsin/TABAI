import SwiftUI
import AVKit
import Photos

struct GenerationResultBubbleView: View {
    let resultUrl: String
    let generationType: GenerationType
    let onRegenerate: () -> Void
    let onFullScreen: () -> Void

    @State private var appeared = false
    @State private var saveSuccess = false

    var body: some View {
        VStack(spacing: 0) {
            // Media content
            if generationType == .video || generationType == .imageToVideo {
                videoContent
            } else {
                imageContent
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5)

            // Action row
            HStack(spacing: 0) {
                actionButton(icon: saveSuccess ? "checkmark" : "arrow.down.to.line", label: "Save") {
                    saveMedia()
                }
                Spacer()
                actionButton(icon: "square.and.arrow.up", label: "Share") {
                    shareMedia()
                }
                Spacer()
                actionButton(icon: "arrow.clockwise", label: "Redo") {
                    onRegenerate()
                }
                Spacer()
                actionButton(icon: "arrow.up.left.and.arrow.down.right", label: "Full") {
                    onFullScreen()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(DS.Colors.fieldBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 2)
        .scaleEffect(appeared ? 1.0 : 0.95)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appeared = true
            }
            Haptics.impact(.soft)
        }
        .frame(maxWidth: .infinity)
    }

    private var imageContent: some View {
        Button { onFullScreen() } label: {
            AsyncImage(url: URL(string: resultUrl)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .transition(.opacity)
                case .failure:
                    placeholder(icon: "exclamationmark.triangle", text: "Failed to load")
                case .empty:
                    placeholder(icon: "photo", text: "Loading...")
                        .modifier(SkeletonShimmer())
                @unknown default:
                    placeholder(icon: "photo", text: "Loading...")
                }
            }
            .clipShape(
                UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16)
            )
        }
        .buttonStyle(.plain)
    }

    private var videoContent: some View {
        ZStack {
            if let url = URL(string: resultUrl) {
                VideoPlayer(player: AVPlayer(url: url))
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
            } else {
                placeholder(icon: "film", text: "Video unavailable")
            }
        }
        .clipShape(
            UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16)
        )
    }

    private func placeholder(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(DS.Colors.fieldBackground)
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundStyle(DS.Colors.textSecondary)
            .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
    }

    private func saveMedia() {
        guard let url = URL(string: resultUrl) else { return }
        saveSuccess = false
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if generationType == .video || generationType == .imageToVideo {
                    let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("tabai_video_\(UUID().uuidString).mp4")
                    try data.write(to: tmpURL)
                    try await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tmpURL)
                    }
                    try? FileManager.default.removeItem(at: tmpURL)
                } else {
                    guard let image = UIImage(data: data) else { return }
                    try await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAsset(from: image)
                    }
                }
                await MainActor.run {
                    saveSuccess = true
                    Haptics.impact(.soft)
                }
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run { saveSuccess = false }
            } catch {
                await MainActor.run {
                    Haptics.impact(.light)
                }
            }
        }
    }

    private func shareMedia() {
        guard let url = URL(string: resultUrl) else { return }
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        root.present(activityVC, animated: true)
    }
}

private struct SkeletonShimmer: ViewModifier {
    @State private var phase: CGFloat = -0.9

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.white.opacity(0), .white.opacity(0.08), .white.opacity(0)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .rotationEffect(.degrees(18))
                    .offset(x: phase * max(proxy.size.width, 1) * 1.7)
                }
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.05).repeatForever(autoreverses: false)) {
                    phase = 0.95
                }
            }
    }
}
