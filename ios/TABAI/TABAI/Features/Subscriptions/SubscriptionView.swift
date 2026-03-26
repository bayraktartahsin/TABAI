import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = StoreKitSubscriptionManager()
    @State private var selectedBillingCycle: BillingCycle = .yearly
    @State private var selectedPlanTier: PlanTier = .pro
    @State private var legalDestination: LegalLinkDestination?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                topBar

                // Hero
                VStack(spacing: 12) {
                    Text("Get the most\naccurate answers")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(DS.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    // Scrolling AI model names (changes per tier)
                    ModelMarqueeRow(models: displayedMarqueeModels)
                        .id(selectedPlanTier) // force re-render on tier change
                        .padding(.top, 4)
                }

                // Tier picker
                tierPicker

                // Feature comparison table
                featureComparisonTable

                // Pricing cards (yearly / monthly)
                pricingCards

                // CTA button
                purchaseButton

                // Legal links + subscription terms
                VStack(spacing: 10) {
                    subscriptionLegalText

                    Button(manager.isRestoring ? "Restoring..." : "Restore Purchases") {
                        Task { await manager.restorePurchases() }
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .disabled(manager.isRestoring)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, DS.Layout.horizontalPadding)
            .padding(.top, 10)
            .padding(.bottom, 30)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.12, blue: 0.16),
                    Color(red: 0.06, green: 0.09, blue: 0.13),
                    Color(red: 0.04, green: 0.06, blue: 0.09),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .task {
            manager.configure(syncService: appEnvironment.storeSyncService) { syncResult in
                appEnvironment.reconcileStoreEntitlement(syncResult)
                await appEnvironment.refreshBootstrapState()
                await appEnvironment.refreshModels()
            }
            selectedPlanTier = initialSelectedPlanTier
            await manager.loadProducts()
        }
        .onChange(of: manager.state) { _, state in
            switch state {
            case .success: Haptics.impact(.soft)
            case .failed, .pending: Haptics.impact(.rigid)
            case .purchasing, .restoring: Haptics.impact(.light)
            default: break
            }
        }
        .animation(DS.Motion.quickSpring, value: selectedPlanTier)
        .animation(DS.Motion.quickSpring, value: selectedBillingCycle)
        .sheet(item: $legalDestination) { destination in
            InAppSafariView(url: destination.url)
                .ignoresSafeArea()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .frame(width: 34, height: 34)
                    .background(DS.Colors.fieldBackground.opacity(0.84))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Restore") {
                Task { await manager.restorePurchases() }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(DS.Colors.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(DS.Colors.fieldBackground.opacity(0.5))
            .clipShape(Capsule())
            .buttonStyle(.plain)
            .disabled(manager.isRestoring)
        }
    }

    // MARK: - Tier Picker

    private var tierPicker: some View {
        HStack(spacing: 3) {
            ForEach(SubscriptionPlanCatalog.orderedTiers, id: \.self) { tier in
                let isSelected = selectedPlanTier == tier
                Button {
                    Haptics.impact(.light)
                    selectedPlanTier = tier
                } label: {
                    Text(SubscriptionPlanCatalog.displayName(for: tier))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isSelected ? DS.Colors.textPrimary : DS.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(isSelected ? DS.Colors.fieldBackground.opacity(0.9) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(isSelected ? DS.Colors.accent.opacity(0.4) : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(DS.Colors.fieldBackground.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(cardBorder, lineWidth: 0.5)
        )
    }

    // MARK: - Feature Comparison Table

    private var featureComparisonTable: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack {
                Text("Features")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                Spacer()
                Text("Free")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 50)
                Text(SubscriptionPlanCatalog.displayName(for: selectedPlanTier))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.Colors.accent)
                    .frame(width: 60)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider().foregroundStyle(cardBorder)

            // Feature rows
            ForEach(comparisonFeatures, id: \.label) { feature in
                HStack {
                    Text(feature.label)
                        .font(.system(size: 14))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Spacer()
                    featureCheckmark(feature.freeHas)
                        .frame(width: 50)
                    featureCheckmark(feature.paidHas)
                        .frame(width: 60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(cardBorder, lineWidth: 0.5)
        )
    }

    private func featureCheckmark(_ has: Bool) -> some View {
        Group {
            if has {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.Colors.accent)
            } else {
                Text("—")
                    .font(.system(size: 13))
                    .foregroundStyle(DS.Colors.textSecondary.opacity(0.4))
            }
        }
    }

    // MARK: - Pricing Cards

    private var pricingCards: some View {
        HStack(spacing: 10) {
            // Yearly card
            pricingCard(cycle: .yearly, discount: yearlyDiscountPercent)

            // Monthly card
            pricingCard(cycle: .monthly, discount: nil)
        }
    }

    private func pricingCard(cycle: BillingCycle, discount: Int?) -> some View {
        let isSelected = selectedBillingCycle == cycle
        let plan = plan(for: selectedPlanTier, cycle: cycle)
        let price = plan.flatMap { manager.productsById[$0.productId] }

        return Button {
            Haptics.impact(.light)
            selectedBillingCycle = cycle
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(cycle == .yearly ? "Yearly" : "Monthly")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Colors.textPrimary)

                    if let discount, discount > 0 {
                        Text("-\(discount)%")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DS.Colors.accent)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(DS.Colors.accent)
                    }
                }

                if let price {
                    let monthlyEquivValue = NSDecimalNumber(decimal: price.price).doubleValue / 12
                    let currencyCode = price.priceFormatStyle.currencyCode ?? "USD"
                    let monthlyEquivFormatted: String = {
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .currency
                        formatter.currencyCode = currencyCode
                        formatter.maximumFractionDigits = 2
                        formatter.minimumFractionDigits = 2
                        return formatter.string(from: NSNumber(value: monthlyEquivValue)) ?? "$\(String(format: "%.2f", monthlyEquivValue))"
                    }()
                    Text(cycle == .yearly ? "\(monthlyEquivFormatted) /mo" : "\(price.displayPrice) /mo")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DS.Colors.textPrimary)

                    Text(cycle == .yearly ? "\(price.displayPrice)/yr" : "")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.textSecondary)
                } else {
                    Text(manager.isLoadingProducts ? "Loading..." : "—")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? DS.Colors.accent.opacity(0.6) : cardBorder, lineWidth: isSelected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task { await manager.purchase(plan: selectedPlan) }
        } label: {
            HStack {
                if manager.isPurchasing(selectedPlan.planTier) {
                    ProgressView().tint(.black)
                }
                Text("Get \(SubscriptionPlanCatalog.displayName(for: selectedPlanTier))")
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.black)
            .background(DS.Colors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(planButtonDisabled(for: selectedPlan))
    }

    // MARK: - Legal Text

    private var subscriptionLegalText: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text("By subscribing, you agree to our")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textSecondary)
                Button("Terms of Service") {
                    legalDestination = LegalLinkDestination(key: .terms)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DS.Colors.accent)
                .buttonStyle(.plain)
                Text("and")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textSecondary)
                Button("Privacy Policy") {
                    legalDestination = LegalLinkDestination(key: .privacy)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DS.Colors.accent)
                .buttonStyle(.plain)
            }

            VStack(spacing: 2) {
                Text("Payment will be charged to your Apple ID account at confirmation of purchase.")
                Text("Subscription automatically renews unless canceled at least 24 hours before the end of the current period.")
                Text("Manage subscriptions in Settings > Apple ID > Subscriptions.")
            }
            .font(.system(size: 11))
            .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
            .multilineTextAlignment(.center)
        }
    }

    // MARK: - Data

    private var comparisonFeatures: [(label: String, freeHas: Bool, paidHas: Bool)] {
        switch selectedPlanTier {
        case .starter:
            return [
                ("Free AI models", true, true),
                ("Top AI models", false, true),
                ("100+ messages/day", false, true),
                ("5 AI images/month", false, true),
                ("Vision models", false, true),
            ]
        case .pro:
            return [
                ("Free AI models", true, true),
                ("Reasoning models", false, true),
                ("200+ messages/day", false, true),
                ("15 images + 1 video/mo", false, true),
                ("Image understanding", false, true),
            ]
        case .power:
            return [
                ("Free AI models", true, true),
                ("All models unlocked", false, true),
                ("500+ messages/day", false, true),
                ("60 images + 3 videos/mo", false, true),
                ("Premium reasoning (O1, O3)", false, true),
                ("Priority access", false, true),
            ]
        case .free:
            return [
                ("8 free AI models", true, true),
                ("30 messages/day", true, true),
                ("1 concurrent chat", true, true),
            ]
        }
    }

    private var displayedMarqueeModels: [String] {
        switch selectedPlanTier {
        case .starter: return ["GPT-4o Mini", "Claude Haiku 4.5", "Gemini 2.5 Flash", "Llama 3.3 70B", "DeepSeek V3"]
        case .pro: return ["GPT-4.1", "Claude Sonnet 4.5", "Gemini 2.5 Pro", "DeepSeek R1", "O3 Mini", "Mistral Large"]
        case .power: return ["Claude Opus 4.5", "GPT-5", "O1", "O3", "Grok 4"]
        case .free: return ["Gemma 3", "Llama 3.3 70B", "Gemma 3 27B", "Mistral Small"]
        }
    }

    private var selectedPlan: SubscriptionPlan {
        manager.plans.first(where: { $0.planTier == selectedPlanTier && $0.billingCycle == selectedBillingCycle })
        ?? SubscriptionPlanCatalog.plans.first(where: { $0.planTier == selectedPlanTier && $0.billingCycle == selectedBillingCycle })
        ?? SubscriptionPlanCatalog.plans.first(where: { $0.planTier == selectedPlanTier })
        ?? SubscriptionPlanCatalog.plans.first
        ?? SubscriptionPlan(planTier: .starter, billingCycle: .monthly, productId: "com.tai.starter.monthly", title: "Starter", subtitle: "Starter plan")
    }

    private var initialSelectedPlanTier: PlanTier {
        // Suggest the next tier up
        switch appEnvironment.effectiveCurrentPlanTier {
        case .free: return .starter
        case .starter: return .pro
        case .pro: return .power
        case .power: return .power
        }
    }

    private func plan(for tier: PlanTier, cycle: BillingCycle) -> SubscriptionPlan? {
        manager.plans.first(where: { $0.planTier == tier && $0.billingCycle == cycle })
        ?? SubscriptionPlanCatalog.plans.first(where: { $0.planTier == tier && $0.billingCycle == cycle })
    }

    private var yearlyDiscountPercent: Int? {
        guard let yearly = plan(for: selectedPlanTier, cycle: .yearly),
              let yearlyProduct = manager.productsById[yearly.productId],
              let monthly = plan(for: selectedPlanTier, cycle: .monthly),
              let monthlyProduct = manager.productsById[monthly.productId] else { return nil }
        let yearlyPrice = NSDecimalNumber(decimal: yearlyProduct.price).doubleValue
        let monthlyPrice = NSDecimalNumber(decimal: monthlyProduct.price).doubleValue
        guard monthlyPrice > 0, yearlyPrice > 0 else { return nil }
        let savings = max(0, (monthlyPrice * 12) - yearlyPrice)
        guard savings > 0 else { return nil }
        return Int((savings / (monthlyPrice * 12) * 100).rounded())
    }

    private func planButtonDisabled(for plan: SubscriptionPlan) -> Bool {
        manager.localActiveProductIds.contains(plan.productId)
        || manager.isPurchasing(plan.planTier)
        || manager.isRestoring
    }

    private var cardBackground: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.05)
                : UIColor.white
        })
    }

    private var cardBorder: Color {
        Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.black.withAlphaComponent(0.08)
        })
    }
}

// MARK: - Model Marquee (polished with vendor icons)

private struct ModelMarqueeRow: View {
    let models: [String]
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let contentWidth = CGFloat(models.count) * 160
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    ForEach(models, id: \.self) { name in
                        modelChip(name)
                    }
                }
            }
            .offset(x: offset)
            .onAppear {
                offset = 0
                withAnimation(.linear(duration: Double(models.count) * 3.5).repeatForever(autoreverses: false)) {
                    offset = -contentWidth
                }
            }
        }
        .frame(height: 32)
        .clipped()
        .mask(
            LinearGradient(
                colors: [.clear, .black, .black, .black, .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }

    private func modelChip(_ name: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: vendorIcon(for: name))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DS.Colors.accent.opacity(0.7))
            Text(name)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textPrimary.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DS.Colors.accent.opacity(0.08))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(DS.Colors.accent.opacity(0.15), lineWidth: 0.5)
        )
        .fixedSize()
    }

    private func vendorIcon(for name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("gpt") || lower.contains("o1") || lower.contains("o3") { return "sparkles" }
        if lower.contains("claude") || lower.contains("opus") || lower.contains("sonnet") || lower.contains("haiku") { return "text.quote" }
        if lower.contains("gemini") || lower.contains("gemma") { return "globe" }
        if lower.contains("llama") { return "network" }
        if lower.contains("mistral") { return "wind" }
        if lower.contains("deepseek") { return "bolt.horizontal" }
        if lower.contains("qwen") || lower.contains("qwq") { return "chevron.left.forwardslash.chevron.right" }
        if lower.contains("grok") { return "xmark" }
        if lower.contains("sonar") { return "safari" }
        return "cpu"
    }
}
