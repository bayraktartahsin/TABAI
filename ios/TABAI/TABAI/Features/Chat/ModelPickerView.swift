import SwiftUI

struct ModelPickerView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @State private var showPicker: Bool = false
    @State private var showImageGenerator: Bool = false
    @State private var showVideoGenerator: Bool = false

    var body: some View {
        Button {
            Haptics.impact(.light)
            showPicker = true
        } label: {
            HStack(spacing: 5) {
                Text(currentModelName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.Colors.textPrimary.opacity(0.9))
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.7))
            }
            .frame(maxWidth: 140)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(chipBackground)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(chipBorder, lineWidth: 0.5))
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            ModelPickerSheet(
                models: appEnvironment.availableModels,
                selectedModelId: appEnvironment.selectedModelId,
                currentPlanTier: appEnvironment.effectiveCurrentPlanTier,
                onSelect: { modelId in
                    appEnvironment.selectedModelId = modelId
                    showPicker = false
                },
                onOpenPlans: {
                    appEnvironment.selectedTab = .subscriptions
                    showPicker = false
                },
                onGenerateImage: {
                    showPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showImageGenerator = true
                    }
                },
                onGenerateVideo: {
                    showPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showVideoGenerator = true
                    }
                }
            )
            .presentationDetents([.large])
            .taiSheetChrome()
        }
        .sheet(isPresented: $showImageGenerator) {
            ImageGeneratorView(service: appEnvironment.generationService)
                .environmentObject(appEnvironment)
        }
        .sheet(isPresented: $showVideoGenerator) {
            VideoGeneratorView(service: appEnvironment.generationService)
                .environmentObject(appEnvironment)
        }
    }

    private var currentModel: ModelCatalog.Model? {
        if let selected = appEnvironment.selectedModelId {
            return appEnvironment.availableModels.first(where: { $0.id == selected }) ?? appEnvironment.availableModels.first
        }
        return appEnvironment.availableModels.first
    }

    private var currentModelName: String {
        currentModel?.displayName ?? currentModel?.id ?? "TABAI"
    }

    private var chipBackground: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.06) : UIColor.black.withAlphaComponent(0.04)
        })
    }

    private var chipBorder: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.1) : UIColor.black.withAlphaComponent(0.08)
        })
    }
}

// MARK: - Model Picker Sheet

private struct ModelPickerSheet: View {
    let models: [ModelCatalog.Model]
    let selectedModelId: String?
    let currentPlanTier: PlanTier
    let onSelect: (String) -> Void
    let onOpenPlans: () -> Void
    var onGenerateImage: (() -> Void)? = nil
    var onGenerateVideo: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    // No .free tier — TABAI is shown as featured card instead
    private let tierOrder: [PlanTier] = [.starter, .pro, .power]

    private var tabaiModel: ModelCatalog.Model? {
        models.first(where: { ($0.providerModelId ?? $0.id) == "tabai" })
    }

    private var nonTabaiModels: [ModelCatalog.Model] {
        models.filter { ($0.providerModelId ?? $0.id) != "tabai" }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Search
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
                        TextField("Search models...", text: $query)
                            .font(.system(size: 15))
                            .foregroundStyle(DS.Colors.textPrimary)
                            .textInputAutocapitalization(.never)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(searchBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    // TABAI Featured Card (always at top, outside search filter)
                    if query.isEmpty, let tabai = tabaiModel {
                        tabaiCard(tabai)
                    }

                    // Create section (fal.ai generation)
                    if query.isEmpty {
                        createSection
                    }

                    // Recommended label
                    if query.isEmpty {
                        Text("Recommended")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                            .textCase(.uppercase)
                    }

                    // Grouped by tier (Starter, Pro, Power)
                    ForEach(tierOrder, id: \.self) { tier in
                        let tierModels = modelsForTier(tier)
                        if !tierModels.isEmpty {
                            tierSection(tier: tier, models: tierModels)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
            .background(
                LinearGradient(
                    colors: [Color(red: 0.07, green: 0.09, blue: 0.12), Color(red: 0.04, green: 0.05, blue: 0.07)],
                    startPoint: .top, endPoint: .bottom
                ).ignoresSafeArea()
            )
            .navigationTitle(L("Choose Model"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .medium))
                }
            }
        }
    }

    // MARK: - TABAI Featured Card

    @ViewBuilder
    private func tabaiCard(_ model: ModelCatalog.Model) -> some View {
        let isSelected = selectedModelId == model.id

        Button {
            onSelect(model.id)
        } label: {
            HStack(spacing: 12) {
                // Sparkle icon
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.blue, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("TABAI")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text("Smart AI \u{2014} picks the best model for you")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                } else {
                    Text("Free")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.08) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.5), Color.blue.opacity(0.3), Color.cyan.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Create Section (fal.ai)

    @ViewBuilder
    private var createSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                Text("Create")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                    .textCase(.uppercase)
            }

            VStack(spacing: 2) {
                createRow(
                    icon: "photo.badge.plus",
                    title: "Generate Image",
                    subtitle: "Create images with AI",
                    isLocked: planOrder(currentPlanTier) < planOrder(.starter),
                    action: { onGenerateImage?() }
                )
                createRow(
                    icon: "film.stack",
                    title: "Generate Video",
                    subtitle: "Create videos with AI",
                    isLocked: planOrder(currentPlanTier) < planOrder(.starter),
                    action: { onGenerateVideo?() }
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func createRow(icon: String, title: String, subtitle: String, isLocked: Bool, action: @escaping () -> Void) -> some View {
        Button {
            if isLocked {
                Haptics.impact(.light)
                onOpenPlans()
            } else {
                action()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isLocked ? DS.Colors.textSecondary.opacity(0.4) : DS.Colors.accent)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(isLocked ? DS.Colors.textSecondary.opacity(0.5) : DS.Colors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
                }

                Spacer()

                if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Starter")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(rowBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tier Section

    @ViewBuilder
    private func tierSection(tier: PlanTier, models: [ModelCatalog.Model]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(tierLabel(tier))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                    .textCase(.uppercase)

                if tier != currentPlanTier && planOrder(tier) > planOrder(currentPlanTier) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
                }

                Spacer()

                Text("\(models.count) models")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
            }

            VStack(spacing: 2) {
                ForEach(models) { model in
                    modelRow(model)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    // MARK: - Model Row

    private func modelRow(_ model: ModelCatalog.Model) -> some View {
        let isSelected = selectedModelId == model.id
        let isLocked = !model.canAccess

        return Button {
            if isLocked {
                Haptics.impact(.light)
                onOpenPlans()
            } else {
                onSelect(model.id)
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(model.displayName ?? model.id)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isLocked ? DS.Colors.textSecondary.opacity(0.5) : DS.Colors.textPrimary)
                        .lineLimit(1)

                    if let vendor = model.vendor, !vendor.isEmpty {
                        Text(vendor)
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Colors.textSecondary.opacity(0.5))
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(DS.Colors.accent)
                } else if isLocked {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text(SubscriptionPlanCatalog.displayName(for: model.requiredPlanTier))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? selectedBackground : rowBackground)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private func modelsForTier(_ tier: PlanTier) -> [ModelCatalog.Model] {
        filteredNonTabaiModels.filter { $0.requiredPlanTier == tier }
            .sorted { ($0.displayName ?? $0.id) < ($1.displayName ?? $1.id) }
    }

    private var filteredNonTabaiModels: [ModelCatalog.Model] {
        let base = nonTabaiModels
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !term.isEmpty else { return base }
        return base.filter {
            ($0.displayName ?? "").lowercased().contains(term) ||
            ($0.vendor ?? "").lowercased().contains(term) ||
            ($0.providerModelId ?? "").lowercased().contains(term)
        }
    }

    private func tierLabel(_ tier: PlanTier) -> String {
        switch tier {
        case .free: return "Free"
        case .starter: return "Starter"
        case .pro: return "Pro"
        case .power: return "Power"
        }
    }

    private func planOrder(_ tier: PlanTier) -> Int {
        switch tier {
        case .free: return 0
        case .starter: return 1
        case .pro: return 2
        case .power: return 3
        }
    }

    // MARK: - Colors

    private var searchBackground: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.05) : UIColor.black.withAlphaComponent(0.04)
        })
    }

    private var rowBackground: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.03) : UIColor.white
        })
    }

    private var selectedBackground: Color {
        Color(uiColor: UIColor { t in
            t.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.07) : UIColor.black.withAlphaComponent(0.04)
        })
    }
}
