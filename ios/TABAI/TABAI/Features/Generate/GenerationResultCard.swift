import SwiftUI
import UIKit

struct GenerationResultCard: View {
    let resultUrl: String
    let prompt: String
    @State private var showShareSheet = false
    @State private var showFullScreen = false
    @State private var loadedImage: UIImage?

    var body: some View {
        VStack(spacing: 12) {
            if let url = URL(string: resultUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .onTapGesture { showFullScreen = true }
                            .onAppear { cacheImage(from: url) }
                    case .failure:
                        failedPlaceholder
                    default:
                        SkeletonBlock(height: 240, width: nil, cornerRadius: 16)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                actionButton(icon: "square.and.arrow.up", label: "Share") {
                    showShareSheet = true
                }
                actionButton(icon: "square.and.arrow.down", label: "Save") {
                    saveToPhotos()
                }
            }

            // Prompt caption
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
            if let image = loadedImage {
                ShareSheet(items: [image])
            }
        }
        .fullScreenCover(isPresented: $showFullScreen) {
            GenerationFullScreenView(resultUrl: resultUrl, prompt: prompt)
        }
    }

    private var failedPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(DS.Colors.fieldBackground)
            .frame(height: 200)
            .overlay {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(DS.Colors.textSecondary)
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

    private func cacheImage(from url: URL) {
        Task {
            if let (data, _) = try? await URLSession.shared.data(from: url),
               let image = UIImage(data: data) {
                loadedImage = image
            }
        }
    }

    private func saveToPhotos() {
        guard let image = loadedImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        Haptics.impact(.light)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Full Screen Viewer

struct GenerationFullScreenView: View {
    let resultUrl: String
    let prompt: String
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                if let url = URL(string: resultUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .scaleEffect(scale)
                                .gesture(
                                    MagnifyGesture()
                                        .onChanged { value in
                                            scale = value.magnification
                                        }
                                        .onEnded { _ in
                                            withAnimation(DS.Motion.spring) {
                                                scale = max(1, min(scale, 4))
                                            }
                                        }
                                )
                                .frame(width: geo.size.width, height: geo.size.height)
                        default:
                            ProgressView()
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                }
            }
            .background(Color.black)
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
