import SwiftUI

struct GenerationOptionsSheet: View {
    let generationType: GenerationType
    @Binding var imageSize: String
    @Binding var imageStyle: String
    @Binding var videoDuration: String
    @Binding var videoResolution: String
    @Environment(\.dismiss) private var dismiss

    private let imageSizes = [
        ("Square HD", "square_hd"),
        ("Portrait", "portrait_4_3"),
        ("Landscape", "landscape_4_3"),
        ("Wide", "landscape_16_9")
    ]

    private let imageStyles = ["Photo", "Art", "Illustration", "3D", "Anime"]
    private let videoDurations = ["3", "5", "10"]
    private let videoResolutions = ["720p", "1080p"]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                if generationType == .image || generationType == .imageToVideo {
                    imageOptions
                } else {
                    videoOptions
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.07, green: 0.09, blue: 0.12), Color(red: 0.04, green: 0.05, blue: 0.07)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()
            )
            .navigationTitle("Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
    }

    private var imageOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Style")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Colors.textSecondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(imageStyles, id: \.self) { style in
                        chipButton(label: style, isSelected: imageStyle.lowercased() == style.lowercased()) {
                            imageStyle = style.lowercased()
                        }
                    }
                }
            }

            Text("Size")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Colors.textSecondary)
                .textCase(.uppercase)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(imageSizes, id: \.1) { label, value in
                        chipButton(label: label, isSelected: imageSize == value) {
                            imageSize = value
                        }
                    }
                }
            }
        }
    }

    private var videoOptions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Duration")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Colors.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(videoDurations, id: \.self) { dur in
                    chipButton(label: "\(dur)s", isSelected: videoDuration == dur) {
                        videoDuration = dur
                    }
                }
            }

            Text("Resolution")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Colors.textSecondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach(videoResolutions, id: \.self) { res in
                    chipButton(label: res, isSelected: videoResolution == res) {
                        videoResolution = res
                    }
                }
            }
        }
    }

    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isSelected ? .black : DS.Colors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isSelected ? DS.Colors.accent : DS.Colors.fieldBackground)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
