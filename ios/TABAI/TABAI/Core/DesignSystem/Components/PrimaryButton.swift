import SwiftUI

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(title: String, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    LoadingDotsView()
                }
                Text(title)
                    .font(DS.Typography.button)
                    .foregroundStyle(Color.black.opacity(0.92))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DS.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled || isLoading ? 0.6 : 1)
    }
}
