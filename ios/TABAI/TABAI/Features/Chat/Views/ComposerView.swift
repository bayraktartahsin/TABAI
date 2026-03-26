import SwiftUI
import UIKit

struct ComposerView: View {
    @Binding var text: String
    let isStreaming: Bool
    let attachments: [ChatViewModel.Attachment]
    let ambientPlanLine: String?
    let isVoiceSessionEnabled: Bool
    let isVoiceListening: Bool
    let isLocked: Bool
    let onAttach: () -> Void
    let onMic: () -> Void
    let onSend: () -> Void
    let onStop: () -> Void
    let onRemoveAttachment: (ChatViewModel.Attachment) -> Void
    let onOpenPlans: () -> Void
    let onDismissKeyboard: () -> Void
    @State private var composerHeight: CGFloat = 32
    @FocusState private var isInputFocused: Bool
    @State private var voicePulse: Bool = false

    private let maxComposerHeight: CGFloat = 180

    private var canSend: Bool {
        guard !isLocked else { return false }
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty
    }

    var body: some View {
        VStack(spacing: 6) {
            // Attachments row
            if !attachments.isEmpty {
                attachmentsRow
            }

            // Main composer pill
            VStack(spacing: 0) {
                // Text input area
                GrowingTextEditor(
                    text: $text,
                    placeholder: "Ask anything...",
                    measuredHeight: $composerHeight,
                    isFocused: _isInputFocused,
                    isEditable: !isLocked
                )
                .frame(maxWidth: .infinity)
                .frame(height: min(max(composerHeight + 16, 42), maxComposerHeight))
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 4)

                // Bottom toolbar
                HStack(spacing: 0) {
                    // Left: attach + model picker
                    HStack(spacing: 12) {
                        Button {
                            isInputFocused = false
                            onDismissKeyboard()
                            onAttach()
                        } label: {
                            Image(systemName: "plus.circle")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                        .buttonStyle(.plain)

                        ModelPickerView()
                            .fixedSize(horizontal: true, vertical: false)
                            .allowsHitTesting(!isLocked)
                            .opacity(isLocked ? 0.6 : 1)
                    }

                    Spacer()

                    // Right: mic + send/stop
                    HStack(spacing: 10) {
                        micButton

                        if isStreaming {
                            sendStopButton(icon: "stop.fill", background: .orange) {
                                isInputFocused = false
                                onDismissKeyboard()
                                onStop()
                            }
                        } else {
                            sendStopButton(icon: "arrow.up", background: canSend ? DS.Colors.accent : DS.Colors.textSecondary.opacity(0.3)) {
                                guard canSend else { return }
                                isInputFocused = false
                                onDismissKeyboard()
                                onSend()
                            }
                            .disabled(!canSend)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .background(composerBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(composerBorder, lineWidth: 0.5)
            )
            .animation(.easeOut(duration: 0.15), value: composerHeight)

            // Ambient plan line
            if let ambientPlanLine, !ambientPlanLine.isEmpty {
                Button {
                    Haptics.impact(.light)
                    onOpenPlans()
                } label: {
                    Text(ambientPlanLine)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                voicePulse = true
            }
        }
        .animation(DS.Motion.quickSpring, value: attachments)
        .animation(DS.Motion.quickSpring, value: isStreaming)
    }

    // MARK: - Subviews

    private var attachmentsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { attachment in
                    AttachmentChip(attachment: attachment) {
                        onRemoveAttachment(attachment)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    private func sendStopButton(icon: String, background: Color, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact(.light)
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(background)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var micButton: some View {
        Button {
            isInputFocused = false
            onDismissKeyboard()
            onMic()
        } label: {
            Image(systemName: isVoiceSessionEnabled ? (isVoiceListening ? "waveform" : "mic.fill") : "mic.slash")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isVoiceListening ? DS.Colors.accent : DS.Colors.textSecondary)
                .frame(width: 32, height: 32)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
    }

    private var composerBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.06)
                : UIColor.white
        })
    }

    private var composerBorder: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.1)
                : UIColor.black.withAlphaComponent(0.1)
        })
    }
}

// MARK: - Growing Text Editor

private struct GrowingTextEditor: View {
    @Binding var text: String
    let placeholder: String
    @Binding var measuredHeight: CGFloat
    @FocusState var isFocused: Bool
    let isEditable: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(placeholder)
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                    .padding(.top, 8)
                    .padding(.leading, 4)
            }

            TextEditor(text: $text)
                .font(.system(size: 15))
                .foregroundStyle(DS.Colors.textPrimary)
                .textInputAutocapitalization(.sentences)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 0)
                .padding(.vertical, 0)
                .focused($isFocused)
                .disabled(!isEditable)
                .opacity(isEditable ? 1 : 0.6)

            // Hidden measurement text
            Text(text.isEmpty ? " " : text)
                .font(.system(size: 15))
                .lineSpacing(2)
                .foregroundStyle(.clear)
                .padding(.leading, 4)
                .padding(.trailing, 4)
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                updateHeight(proxy.size.height)
                            }
                            .onChange(of: text) { _, _ in
                                updateHeight(proxy.size.height)
                            }
                    }
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func updateHeight(_ value: CGFloat) {
        let rounded = ceil(value)
        guard abs(rounded - measuredHeight) > 0.5 else { return }
        measuredHeight = rounded
    }
}

// MARK: - Attachment Chip

private struct AttachmentChip: View {
    let attachment: ChatViewModel.Attachment
    let onRemove: () -> Void

    var body: some View {
        if let thumbnail = attachment.thumbnail {
            // Image thumbnail chip
            ZStack(alignment: .topTrailing) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DS.Colors.glassStroke, lineWidth: 0.5)
                    )

                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white, .black.opacity(0.6))
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
            }
        } else {
            // Text file chip
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)

                Text(attachment.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .lineLimit(1)

                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(DS.Colors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(DS.Colors.fieldBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(DS.Colors.textSecondary.opacity(0.1), lineWidth: 0.5)
            )
        }
    }

    private var iconName: String {
        switch attachment.kind {
        case .photo: return "photo"
        case .camera: return "camera"
        case .file: return "doc.text"
        }
    }
}
