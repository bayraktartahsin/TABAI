import SwiftUI
import AVKit
import Photos

struct GenerationFullScreenViewer: View {
    let resultUrl: String
    let generationType: GenerationType
    let prompt: String
    @Environment(\.dismiss) private var dismiss

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var dragOffset: CGFloat = 0
    @State private var showControls = true
    @State private var saveSuccess = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .opacity(max(0.4, 1.0 - abs(dragOffset) / CGFloat(400)))

            if generationType == .video || generationType == .imageToVideo {
                videoViewer
            } else {
                imageViewer
            }

            // Top bar
            if showControls {
                VStack {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            shareMedia()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    Spacer()

                    // Bottom bar
                    VStack(spacing: 12) {
                        if !prompt.isEmpty {
                            Text(prompt)
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button {
                            saveMedia()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: saveSuccess ? "checkmark" : "arrow.down.to.line")
                                    .font(.system(size: 15, weight: .semibold))
                                Text(saveSuccess ? "Saved" : "Save to Photos")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DS.Colors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    .background(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.6)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                }
                .transition(.opacity)
            }
        }
        .statusBarHidden(true)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                showControls.toggle()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    if abs(value.translation.height) > 100 {
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }

    private var imageViewer: some View {
        AsyncImage(url: URL(string: resultUrl)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(y: dragOffset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = min(max(value, 1.0), 5.0)
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    if scale < 1.2 { scale = 1.0 }
                                }
                            }
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            scale = scale > 1.5 ? 1.0 : 2.0
                        }
                    }
            default:
                ProgressView()
                    .tint(.white)
            }
        }
    }

    private var videoViewer: some View {
        Group {
            if let url = URL(string: resultUrl) {
                VideoPlayer(player: AVPlayer(url: url))
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .offset(y: dragOffset)
            }
        }
    }

    private func saveMedia() {
        guard let url = URL(string: resultUrl) else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if generationType == .video || generationType == .imageToVideo {
                    let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("tabai_video.mp4")
                    try data.write(to: tmpURL)
                    try await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tmpURL)
                    }
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
            } catch {}
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
