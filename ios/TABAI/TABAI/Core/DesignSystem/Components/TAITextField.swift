import SwiftUI

struct TAITextField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(DS.Typography.subtitle)
                .foregroundStyle(DS.Colors.textSecondary)
            field
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(DS.Colors.fieldBackground)
                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Layout.fieldCornerRadius, style: .continuous)
                        .stroke(DS.Colors.glassStroke, lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var field: some View {
        if isSecure {
            SecureField("", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .submitLabel(.go)
                .foregroundStyle(DS.Colors.textPrimary)
        } else {
            TextField("", text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .keyboardType(.emailAddress)
                .submitLabel(.next)
                .foregroundStyle(DS.Colors.textPrimary)
        }
    }
}
