import SwiftUI
import UIKit

struct ChatBubbleView: View {
    let message: ChatViewModel.ChatMessage
    let streamingPhase: ChatViewModel.StreamingPhase
    let stopPulseTrigger: Int
    let isPrimaryStreamingBubble: Bool
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onRegenerate: () -> Void
    let onStop: () -> Void
    let onRetry: () -> Void
    @State private var cursorVisible: Bool = true
    @State private var thinkingDotsPulse: Bool = false
    @State private var stabilizationOpacity: Double = 1

    private var isAssistantStreamingBubble: Bool {
        message.role == .assistant && isPrimaryStreamingBubble
    }

    var body: some View {
        if message.role == .user {
            userMessage
        } else {
            answerCard
        }
    }

    // MARK: - User Message (compact, right-aligned)

    private var userMessage: some View {
        VStack(alignment: .trailing, spacing: 6) {
            VStack(alignment: .trailing, spacing: 8) {
                // Inline attachment thumbnails
                if !message.attachments.isEmpty {
                    let imageAttachments = message.attachments.filter { $0.thumbnail != nil }
                    let fileAttachments = message.attachments.filter { $0.thumbnail == nil }

                    if !imageAttachments.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(imageAttachments.prefix(3)) { att in
                                if let thumb = att.thumbnail {
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 72, height: 72)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }
                            }
                            if imageAttachments.count > 3 {
                                Text("+\(imageAttachments.count - 3)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(DS.Colors.textSecondary)
                                    .frame(width: 36, height: 72)
                                    .background(DS.Colors.fieldBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }
                    }

                    if !fileAttachments.isEmpty {
                        ForEach(fileAttachments) { att in
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.Colors.textSecondary)
                                Text(att.name)
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.Colors.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }

                if !message.text.isEmpty {
                    Text(message.text)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(DS.Colors.textPrimary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(userBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .frame(maxWidth: .infinity, alignment: .trailing)

            MessageActionMenu(
                isUser: true,
                isStreaming: false,
                isFailed: message.isFailed,
                onCopy: onCopy,
                onEdit: onEdit,
                onRegenerate: onRegenerate,
                onStop: onStop,
                onRetry: onRetry
            )
        }
        .padding(.vertical, 2)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    private var userBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.05)
        })
    }

    // MARK: - Answer Card (Perplexity-style, full-width)

    private var answerCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Answer content
            VStack(alignment: .leading, spacing: 12) {
                answerContent
            }
            .padding(.top, 16)
            .padding(.horizontal, 0)
            .padding(.bottom, 12)

            // Powered by (TABAI composite model)
            if let poweredBy = message.poweredBy, !message.isStreaming {
                Text("Powered by \(poweredBy)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
                    .padding(.bottom, 6)
            }

            // Divider
            Rectangle()
                .fill(dividerColor)
                .frame(height: 0.5)

            // Action bar
            HStack(spacing: 0) {
                answerActionBar
            }
            .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.opacity.combined(with: .move(edge: .leading)))
        .onChange(of: stopPulseTrigger) { _, _ in
            guard isAssistantStreamingBubble else { return }
        }
        .onChange(of: streamingPhase) { _, newValue in
            guard isAssistantStreamingBubble else { return }
            if newValue == .finishing {
                stabilizationOpacity = 0.9
                withAnimation(.easeOut(duration: 0.25)) {
                    stabilizationOpacity = 1
                }
            }
        }
    }

    private var dividerColor: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.06)
                : UIColor.black.withAlphaComponent(0.06)
        })
    }

    @ViewBuilder
    private var answerContent: some View {
        if isAssistantStreamingBubble && streamingPhase == .thinking && message.text.isEmpty {
            thinkingIndicator
        } else {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                MarkdownMessageText(text: message.text)
                    .foregroundStyle(DS.Colors.textPrimary)

                if isAssistantStreamingBubble && streamingPhase == .generating {
                    Text("▌")
                        .font(.system(size: 15))
                        .foregroundStyle(DS.Colors.accent.opacity(cursorVisible ? 0.95 : 0.22))
                        .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true), value: cursorVisible)
                        .onAppear {
                            cursorVisible = false
                        }
                }
            }
            .opacity(isAssistantStreamingBubble && streamingPhase == .finishing ? stabilizationOpacity : 1)

            if message.isFailed {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Response failed")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    private var thinkingIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(DS.Colors.textSecondary.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .opacity(thinkingDotsPulse ? 0.3 : 1)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: thinkingDotsPulse
                    )
            }

            Text("Thinking...")
                .font(.system(size: 14))
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .onAppear {
            thinkingDotsPulse = true
        }
    }

    private var answerActionBar: some View {
        HStack(spacing: 16) {
            if message.isStreaming {
                answerActionButton(icon: "stop.fill", label: "Stop", tint: .orange) {
                    onStop()
                }
            } else if message.isFailed {
                answerActionButton(icon: "arrow.clockwise", label: "Retry", tint: .orange) {
                    onRetry()
                }
            } else {
                answerActionButton(icon: "doc.on.doc", label: "Copy") {
                    onCopy()
                }
                answerActionButton(icon: "arrow.clockwise", label: "Regenerate") {
                    onRegenerate()
                }
            }

            Spacer()
        }
    }

    private func answerActionButton(icon: String, label: String, tint: Color = DS.Colors.textSecondary, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundStyle(tint)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Markdown Rendering

private struct MarkdownMessageText: View {
    let text: String

    private static let segmentCache = NSCache<NSString, SegmentCacheBox>()

    private var segments: [Segment] {
        let key = text as NSString
        if let cached = Self.segmentCache.object(forKey: key) {
            return cached.value
        }
        let parsed = parseSegments(from: text)
        Self.segmentCache.setObject(SegmentCacheBox(parsed), forKey: key)
        return parsed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .markdown(let markdown):
                    MarkdownBlockText(text: markdown)
                case .code(let code, let language):
                    CodeBlockView(code: code, language: language)
                }
            }
        }
        .textSelection(.enabled)
    }

    fileprivate enum Segment {
        case markdown(String)
        case code(String, String?)
    }

    private func parseSegments(from raw: String) -> [Segment] {
        var segments: [Segment] = []
        var inCodeBlock = false
        var buffer: [String] = []
        var currentCodeLanguage: String?

        for line in raw.components(separatedBy: "\n") {
            if line.hasPrefix("```") {
                if inCodeBlock {
                    segments.append(.code(buffer.joined(separator: "\n"), currentCodeLanguage))
                    currentCodeLanguage = nil
                } else if !buffer.isEmpty {
                    segments.append(.markdown(buffer.joined(separator: "\n")))
                    let lang = line.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)
                    currentCodeLanguage = lang.isEmpty ? nil : lang
                }
                buffer.removeAll()
                inCodeBlock.toggle()
            } else {
                buffer.append(line)
            }
        }

        if !buffer.isEmpty {
            segments.append(inCodeBlock ? .code(buffer.joined(separator: "\n"), currentCodeLanguage) : .markdown(buffer.joined(separator: "\n")))
        }

        return segments.isEmpty ? [.markdown(raw)] : segments
    }
}

fileprivate final class SegmentCacheBox: NSObject {
    let value: [MarkdownMessageText.Segment]

    init(_ value: [MarkdownMessageText.Segment]) {
        self.value = value
    }
}

private struct MarkdownBlockText: View {
    let text: String

    private static let blockCache = NSCache<NSString, MarkdownBlockCacheBox>()

    private var blocks: [MarkdownBlock] {
        let key = text as NSString
        if let cached = Self.blockCache.object(forKey: key) {
            return cached.value
        }
        let parsed = parseBlocks(text)
        Self.blockCache.setObject(MarkdownBlockCacheBox(parsed), forKey: key)
        return parsed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let level, let value):
                    MarkdownInlineText(text: value, style: .heading(level: level))
                case .bullet(let items):
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(DS.Colors.textSecondary)
                                    .frame(width: 4, height: 4)
                                    .padding(.top, 8)
                                MarkdownInlineText(text: item, style: .body)
                            }
                        }
                    }
                case .numbered(let items):
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(item.number).")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(DS.Colors.textSecondary)
                                    .padding(.top, 1)
                                MarkdownInlineText(text: item.value, style: .body)
                            }
                        }
                    }
                case .blockquote(let value):
                    HStack(alignment: .top, spacing: 10) {
                        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                            .fill(DS.Colors.textSecondary.opacity(0.3))
                            .frame(width: 2.5)
                        MarkdownInlineText(text: value, style: .quote)
                    }
                    .padding(.vertical, 2)
                case .paragraph(let value):
                    MarkdownInlineText(text: value, style: .body)
                case .divider:
                    Rectangle()
                        .fill(DS.Colors.textSecondary.opacity(0.15))
                        .frame(height: 0.5)
                        .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    fileprivate enum MarkdownBlock {
        case heading(level: Int, value: String)
        case bullet([String])
        case numbered([(number: Int, value: String)])
        case blockquote(String)
        case paragraph(String)
        case divider
    }

    private func parseBlocks(_ source: String) -> [MarkdownBlock] {
        let lines = source.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var bulletItems: [String] = []
        var numberedItems: [(number: Int, value: String)] = []
        var quoteLines: [String] = []

        func flushParagraph() {
            guard paragraph.isEmpty == false else { return }
            blocks.append(.paragraph(paragraph.joined(separator: "\n")))
            paragraph.removeAll()
        }

        func flushBullet() {
            guard bulletItems.isEmpty == false else { return }
            blocks.append(.bullet(bulletItems))
            bulletItems.removeAll()
        }

        func flushNumbered() {
            guard numberedItems.isEmpty == false else { return }
            blocks.append(.numbered(numberedItems))
            numberedItems.removeAll()
        }

        func flushQuote() {
            guard quoteLines.isEmpty == false else { return }
            blocks.append(.blockquote(quoteLines.joined(separator: "\n")))
            quoteLines.removeAll()
        }

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.isEmpty {
                flushParagraph()
                flushBullet()
                flushNumbered()
                flushQuote()
                continue
            }

            if let heading = parseHeading(line) {
                flushParagraph()
                flushBullet()
                flushNumbered()
                flushQuote()
                blocks.append(.heading(level: heading.level, value: heading.value))
                continue
            }

            if isDivider(line) {
                flushParagraph()
                flushBullet()
                flushNumbered()
                flushQuote()
                blocks.append(.divider)
                continue
            }

            if let quote = parseQuote(line) {
                flushParagraph()
                flushBullet()
                flushNumbered()
                quoteLines.append(quote)
                continue
            }

            if let bullet = parseBullet(line) {
                flushParagraph()
                flushNumbered()
                flushQuote()
                bulletItems.append(bullet)
                continue
            }

            if let numbered = parseNumbered(line) {
                flushParagraph()
                flushBullet()
                flushQuote()
                numberedItems.append(numbered)
                continue
            }

            flushBullet()
            flushNumbered()
            flushQuote()
            paragraph.append(rawLine)
        }

        flushParagraph()
        flushBullet()
        flushNumbered()
        flushQuote()

        return blocks
    }

    private func parseHeading(_ line: String) -> (level: Int, value: String)? {
        guard line.hasPrefix("#") else { return nil }
        let prefix = line.prefix { $0 == "#" }
        let level = min(prefix.count, 6)
        let value = line.dropFirst(level).trimmingCharacters(in: .whitespaces)
        guard value.isEmpty == false else { return nil }
        return (level, value)
    }

    private func parseBullet(_ line: String) -> String? {
        guard let first = line.first, first == "-" || first == "*" || first == "+" else {
            return nil
        }
        let value = line.dropFirst().trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    private func parseNumbered(_ line: String) -> (number: Int, value: String)? {
        let parts = line.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard parts.count == 2,
              let number = Int(parts[0]),
              number > 0 else {
            return nil
        }
        let value = parts[1].trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : (number, value)
    }

    private func parseQuote(_ line: String) -> String? {
        guard line.hasPrefix(">") else { return nil }
        let value = line.dropFirst().trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    private func isDivider(_ line: String) -> Bool {
        let compact = line.replacingOccurrences(of: " ", with: "")
        guard compact.count >= 3 else { return false }
        let chars = Set(compact)
        return chars == ["-"] || chars == ["*"] || chars == ["_"]
    }
}

fileprivate final class MarkdownBlockCacheBox: NSObject {
    let value: [MarkdownBlockText.MarkdownBlock]

    init(_ value: [MarkdownBlockText.MarkdownBlock]) {
        self.value = value
    }
}

private struct MarkdownInlineText: View {
    enum Style {
        case body
        case quote
        case heading(level: Int)
    }

    let text: String
    let style: Style

    var body: some View {
        Group {
            if let attributed = styledAttributedText() {
                Text(attributed)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text(text)
                    .font(fontForStyle)
                    .foregroundStyle(colorForStyle)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .lineSpacing(3)
    }

    private var fontForStyle: Font {
        switch style {
        case .body:
            return .system(size: 15, weight: .regular)
        case .quote:
            return .system(size: 14).italic()
        case .heading(let level):
            switch level {
            case 1:
                return .system(size: 22, weight: .semibold)
            case 2:
                return .system(size: 19, weight: .semibold)
            case 3:
                return .system(size: 17, weight: .semibold)
            default:
                return .system(size: 16, weight: .semibold)
            }
        }
    }

    private var colorForStyle: Color {
        switch style {
        case .heading:
            return DS.Colors.textPrimary
        case .quote:
            return DS.Colors.textSecondary
        case .body:
            return DS.Colors.textPrimary
        }
    }

    private func styledAttributedText() -> AttributedString? {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard var attributed = try? AttributedString(markdown: text, options: options) else {
            return nil
        }

        attributed.font = fontForStyle
        attributed.foregroundColor = colorForStyle

        for run in attributed.runs {
            if let link = run.link {
                attributed[run.range].foregroundColor = DS.Colors.accent
                attributed[run.range].underlineStyle = .single
                attributed[run.range].link = link
            }
            if let intent = run.inlinePresentationIntent, intent.contains(.code) {
                attributed[run.range].font = .system(size: 13, weight: .medium, design: .monospaced)
                attributed[run.range].backgroundColor = DS.Colors.fieldBackground
            }
        }
        return attributed
    }
}

private struct CodeBlockView: View {
    let code: String
    let language: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(language?.uppercased() ?? "CODE")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(DS.Colors.textSecondary)
                Spacer()
                Button {
                    UIPasteboard.general.string = code
                    Haptics.impact(.light)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DS.Colors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)

            Rectangle()
                .fill(DS.Colors.textSecondary.opacity(0.1))
                .frame(height: 0.5)

            ScrollView(.horizontal, showsIndicators: true) {
                Text(code)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
        .background(codeBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(DS.Colors.textSecondary.opacity(0.1), lineWidth: 0.5)
        )
        .padding(.vertical, 2)
    }

    private var codeBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.04)
                : UIColor.black.withAlphaComponent(0.03)
        })
    }
}
