import SwiftUI
import SafariServices

struct InAppSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(DS.Colors.accent)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

struct LegalLinkDestination: Identifiable {
    let key: LegalLinkKey

    var id: String { key.rawValue }
    var title: String { key.title }
    var url: URL { LegalLinks.url(for: key) }
}

struct LegalLinksFooter: View {
    let keys: [LegalLinkKey]
    let onOpen: (LegalLinkKey) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Divider()
                .overlay(DS.Colors.glassStroke)

            FlowRow(spacing: 8) {
                ForEach(keys, id: \.rawValue) { key in
                    Button(key.title) {
                        onOpen(key)
                    }
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 2)
    }
}

private struct FlowRow<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
