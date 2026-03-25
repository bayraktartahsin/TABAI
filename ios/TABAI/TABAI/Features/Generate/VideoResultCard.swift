import SwiftUI
import AVKit

struct VideoResultCard: View {
    let resultUrl: String
    let prompt: String
    @State private var player: AVPlayer?
    @State private var isLooping = true
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 12) {
            if let url = URL(string: resultUrl) {
                VideoPlayer(player: player)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onAppear {
                        let avPlayer = AVPlayer(url: url)
                        player = avPlayer
                        avPlayer.play()
                        setupLooping()
                    }
                    .onDisappear {
                        player?.pause()
                        player = nil
                    }
            }

            HStack(spacing: 12) {
                actionButton(icon: "square.and.arrow.up", label: "Share") {
                    showShareSheet = true
                }
                actionButton(icon: "arrow.2.squarepath", label: isLooping ? "Loop On" : "Loop Off") {
                    isLooping.toggle()
                }
            }

            Text(prompt)
                .font(.system(size: 12))
                .foregroundStyle(DS.Colors.textSecondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(DS.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(DS.Colors.glassStroke, lineWidth: 0.5)
        )
        .sheet(isPresented: $showShareSheet) {
            if let url = URL(string: resultUrl) {
                ShareSheet(items: [url])
            }
        }
    }

    private func actionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Label(label, systemImage: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(DS.Colors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func setupLooping() {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            if isLooping {
                player?.seek(to: .zero)
                player?.play()
            }
        }
    }
}
