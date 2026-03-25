import SwiftUI
import UIKit

struct VoiceSessionView: View {
    @StateObject private var viewModel = VoiceSessionViewModel()
    @AppStorage("tai.voiceSessionEnabled") private var voiceSessionEnabled = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 20) {
            header

            GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(t("voice.transcript", fallback: "Dictation Transcript"))
                        .font(DS.Typography.subtitle)
                        .foregroundStyle(DS.Colors.textSecondary)

                    if viewModel.transcript.isEmpty {
                        Text(
                            voiceSessionEnabled
                                ? "Start dictation to speak your prompt. You can review text before sending."
                                : "Turn on Voice Input in Settings to use dictation in Chat."
                        )
                            .font(DS.Typography.body)
                            .foregroundStyle(DS.Colors.textSecondary)
                    } else {
                        ForEach(viewModel.transcript) { line in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(line.role)
                                    .font(DS.Typography.subtitle)
                                    .foregroundStyle(DS.Colors.textPrimary)
                                Text(line.text)
                                    .font(DS.Typography.body)
                                    .foregroundStyle(DS.Colors.textSecondary)
                            }
                        }
                    }

                    if !viewModel.statusMessage.isEmpty {
                        Text(viewModel.statusMessage)
                            .font(.caption)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    if viewModel.permissionState == .denied {
                        Button("Open Settings") {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            openURL(url)
                        }
                        .font(DS.Typography.subtitle)
                        .foregroundStyle(DS.Colors.accent)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 16) {
                PrimaryButton(
                    title: viewModel.isListening
                        ? t("voice.stop_listening", fallback: "Stop Dictation")
                        : t("voice.start_listening", fallback: "Start Dictation"),
                    isDisabled: !voiceSessionEnabled || !viewModel.canStartListening
                ) {
                    if viewModel.isListening {
                        viewModel.stopListening()
                    } else {
                        Task { await viewModel.startListening() }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, DS.Layout.horizontalPadding)
        .taiFullscreen {
            GradientBackground()
        }
        .onChange(of: voiceSessionEnabled) { _, enabled in
            if !enabled, viewModel.isListening {
                viewModel.stopListening()
            }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(t("voice.title", fallback: "Voice Input"))
                    .font(DS.Typography.title)
                    .foregroundStyle(DS.Colors.textPrimary)
                Text("Use dictation to speak your prompt, review the transcript, then return to chat.")
                    .font(DS.Typography.subtitle)
                    .foregroundStyle(DS.Colors.textSecondary)
            }
            Spacer()
        }
    }
}
