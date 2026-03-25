import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = SettingsViewModel(settingsService: MockSettingsService())

    @State private var showPasswordSheet: Bool = false
    @State private var showSignOutConfirm: Bool = false
    @State private var legalDestination: LegalLinkDestination?

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var securityError: String?
    @State private var isUpdatingPassword = false
    @State private var isRefreshingAccount = false
    @State private var showUsage = false

    @AppStorage("tai.voiceSessionEnabled") private var voiceSessionEnabled = false
    @AppStorage("tai.notifications.enabled") private var notificationsEnabled = true
    @AppStorage("tai.hapticsEnabled") private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile card
                    profileSection

                    // Quick actions
                    quickActionsSection

                    // Preferences
                    preferencesSection

                    // About & Legal
                    aboutSection

                    // Sign Out
                    signOutButton

                    // Version
                    Text("TAI v\(appVersion) (\(buildNumber))")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
                        .padding(.top, 4)
                }
                .padding(.horizontal, DS.Layout.horizontalPadding)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .safeAreaPadding(.top)
            .taiFullscreen {
                GradientBackground()
            }
            .refreshable {
                await refreshAll()
            }
            .sheet(item: $legalDestination) { destination in
                NavigationStack {
                    InAppSafariView(url: destination.url)
                        .ignoresSafeArea()
                        .navigationTitle(destination.title)
                        .navigationBarTitleDisplayMode(.inline)
                }
                .taiSheetChrome()
            }
            .sheet(isPresented: $showPasswordSheet) {
                passwordSheet
            }
            .confirmationDialog("Sign out of this account?", isPresented: $showSignOutConfirm) {
                Button(L("Sign Out"), role: .destructive) {
                    appEnvironment.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will need to sign in again to access your chats and plan.")
            }
            .task {
                viewModel.configure(settingsService: appEnvironment.settingsService)
                await refreshAll()
            }
            .onReceive(appEnvironment.$availableModels) { newValue in
                viewModel.updateModels(newValue)
            }
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(spacing: 16) {
            // Logo + Settings title
            HStack {
                BrandLogoMark(size: 20)
                Text(L("Settings"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
            }

            // Profile card
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(avatarGradient)
                        .frame(width: 48, height: 48)
                    Text(avatarInitials)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(appEnvironment.currentUserProfile?.email ?? "Not signed in")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.Colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Text(SubscriptionPlanCatalog.displayName(for: appEnvironment.effectiveCurrentPlanTier))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DS.Colors.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(DS.Colors.accent.opacity(0.1))
                            .clipShape(Capsule())

                        if appEnvironment.effectiveCurrentEntitlement?.status.grantsAccess == true {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.Colors.accent)
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
            .background(settingsCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(settingsCardBorder, lineWidth: 0.5)
            )
        }
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(spacing: 2) {
            settingsRow(icon: "creditcard", title: L("Subscription"), subtitle: SubscriptionPlanCatalog.displayName(for: appEnvironment.effectiveCurrentPlanTier)) {
                appEnvironment.selectedTab = .subscriptions
            }

            NavigationLink(destination: UsageView()) {
                HStack(spacing: 12) {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.Colors.textSecondary)
                        .frame(width: 22)
                    Text(L("Usage"))
                        .font(.system(size: 15))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Spacer()
                    Text(usageSummary)
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .background(settingsCardBackground)
            }
            .buttonStyle(.plain)

            settingsRow(icon: "key", title: L("Change Password")) {
                showPasswordSheet = true
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Preferences

    private var preferencesSection: some View {
        VStack(spacing: 0) {
            sectionHeader(L("Preferences"))

            VStack(spacing: 2) {
                // Theme
                settingsPickerRow(icon: "moon.circle", title: L("Theme"), value: viewModel.selectedTheme, options: viewModel.themes) { theme in
                    viewModel.selectTheme(theme)
                }

                // Speech Language
                languagePickerRow(icon: "waveform", title: L("Speech Language"), selected: viewModel.selectedSpeechLanguage, languages: viewModel.speechLanguages) { lang in
                    viewModel.selectSpeechLanguage(lang)
                }

                // Toggles
                settingsToggleRow(icon: "bell", title: L("Notifications"), isOn: $notificationsEnabled)
                settingsToggleRow(icon: "mic", title: L("Voice Input"), isOn: $voiceSessionEnabled)
                settingsToggleRow(icon: "hand.tap", title: L("Haptics"), isOn: $hapticsEnabled)

                // Biometrics
                if appEnvironment.biometricAvailable {
                    settingsToggleRow(
                        icon: "faceid",
                        title: appEnvironment.biometricLabel,
                        isOn: Binding(
                            get: { appEnvironment.biometricEnabled },
                            set: { enabled in
                                Task { await appEnvironment.setBiometricPreference(enabled: enabled) }
                            }
                        )
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - About & Legal

    private var aboutSection: some View {
        VStack(spacing: 0) {
            sectionHeader(L("About"))

            VStack(spacing: 2) {
                ForEach(LegalLinkKey.allCases, id: \.rawValue) { key in
                    settingsRow(icon: legalIcon(for: key), title: key.title) {
                        legalDestination = LegalLinkDestination(key: key)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button {
            showSignOutConfirm = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .medium))
                Text(L("Sign Out"))
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(.red.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.red.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Password Sheet

    private var passwordSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TAITextField(title: "Current Password", text: $currentPassword, isSecure: true)
                TAITextField(title: "New Password", text: $newPassword, isSecure: true)

                if let securityError {
                    Text(securityError)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                PrimaryButton(
                    title: "Update Password",
                    isLoading: isUpdatingPassword,
                    isDisabled: currentPassword.isEmpty || newPassword.count < 8 || isUpdatingPassword
                ) {
                    Task {
                        isUpdatingPassword = true
                        defer { isUpdatingPassword = false }
                        do {
                            _ = try await appEnvironment.settingsService.updateAccount(
                                currentPassword: currentPassword, email: nil, password: newPassword
                            )
                            securityError = nil
                            currentPassword = ""
                            newPassword = ""
                            showPasswordSheet = false
                        } catch {
                            securityError = "Password update failed. Check your current password."
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, DS.Layout.horizontalPadding)
            .padding(.top, 24)
            .navigationTitle("Change Password")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showPasswordSheet = false }
                }
            }
        }
        .presentationDetents([.medium])
        .interactiveDismissDisabled(isUpdatingPassword)
        .taiSheetChrome()
    }

    // MARK: - Row Builders

    private func settingsRow(icon: String, title: String, subtitle: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 22)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textPrimary)

                Spacer()

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.textSecondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(settingsCardBackground)
        }
        .buttonStyle(.plain)
    }

    private func settingsToggleRow(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)
                .frame(width: 22)

            Text(title)
                .font(.system(size: 15))
                .foregroundStyle(DS.Colors.textPrimary)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DS.Colors.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(settingsCardBackground)
    }

    private func settingsPickerRow(icon: String, title: String, value: String, options: [String], onSelect: @escaping (String) -> Void) -> some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    onSelect(option)
                } label: {
                    HStack {
                        Text(option)
                        if option == value {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 22)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textPrimary)

                Spacer()

                Text(value)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.textSecondary)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(settingsCardBackground)
        }
    }

    private func languagePickerRow(icon: String, title: String, selected: String, languages: [AppLanguage], onSelect: @escaping (AppLanguage) -> Void) -> some View {
        Menu {
            ForEach(languages) { lang in
                Button {
                    onSelect(lang)
                } label: {
                    HStack {
                        Text(lang.displayLabel)
                        if lang.label == selected || lang.id == selected {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 22)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textPrimary)

                Spacer()

                Text(selected)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.textSecondary)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(settingsCardBackground)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
    }

    // MARK: - Helpers

    private func refreshAll() async {
        isRefreshingAccount = true
        async let s: Void = viewModel.refresh()
        async let b: Void = appEnvironment.refreshBootstrapState()
        async let m: Void = appEnvironment.refreshModels()
        await s; await b; await m
        viewModel.updateModels(appEnvironment.availableModels)
        isRefreshingAccount = false
    }

    private var usageSummary: String {
        let total = appEnvironment.availableModels.count
        let locked = appEnvironment.availableModels.filter { !$0.canAccess }.count
        return "\(total - locked) models available"
    }

    private var avatarInitials: String {
        guard let email = appEnvironment.currentUserProfile?.email, !email.isEmpty else { return "?" }
        return String(email.prefix(1)).uppercased()
    }

    private var avatarGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.30, green: 0.45, blue: 1.0),
                Color(red: 0.65, green: 0.35, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func legalIcon(for key: LegalLinkKey) -> String {
        switch key {
        case .privacy: return "lock.shield"
        case .terms: return "doc.text"
        case .acceptableUse: return "checkmark.shield"
        case .subscription: return "creditcard"
        case .support: return "questionmark.circle"
        }
    }

    private var settingsCardBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.05)
                : UIColor.white
        })
    }

    private var settingsCardBorder: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.06)
        })
    }
}

private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
}

private var buildNumber: String {
    Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
