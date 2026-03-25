package com.taba.tabai.domain.model

import kotlinx.serialization.Serializable

enum class PlanTier { FREE, STARTER, PRO, POWER;
    companion object {
        fun from(s: String?) = entries.firstOrNull { it.name.equals(s, true) } ?: FREE
    }
}

enum class EntitlementSource { FREE, APPLE, GOOGLE, ADMIN, WEB;
    companion object { fun from(s: String?) = entries.firstOrNull { it.name.equals(s, true) } ?: FREE }
}

enum class EntitlementStatus { ACTIVE, INACTIVE, GRACE, CANCELLED, EXPIRED;
    companion object { fun from(s: String?) = entries.firstOrNull { it.name.equals(s, true) } ?: INACTIVE }
}

enum class StreamingPhase { THINKING, GENERATING, FINISHING, IDLE }

enum class BillingCycle { MONTHLY, YEARLY }

@Serializable
data class EntitlementInfo(
    val planTier: String = "free",
    val source: String = "free",
    val status: String = "inactive",
    val expiresAt: String? = null,
    val autoRenew: Boolean = false,
    val externalProductId: String? = null,
    val externalOriginalTransactionId: String? = null,
    val startAt: String? = null,
    val lastValidatedAt: String? = null,
)

@Serializable
data class UserProfile(
    val id: String,
    val email: String,
    val username: String,
    val displayName: String? = null,
    val role: String = "USER",
    val status: String = "ENABLED",
    val planTier: String = "free",
    val emailVerified: Boolean = false,
    val entitlement: EntitlementInfo? = null,
    val lastActiveAt: String? = null,
    val createdAt: String? = null,
) {
    val effectivePlanTier get() = PlanTier.from(entitlement?.planTier ?: planTier)
}

@Serializable
data class AIModel(
    val id: String,
    val displayName: String? = null,
    val providerModelId: String? = null,
    val vendor: String? = null,
    val capabilities: List<String> = emptyList(),
    val requiredPlanTier: String = "free",
    val canAccess: Boolean = true,
    val lockReason: String? = null,
    val contextLength: Int? = null,
    val logoUrl: String? = null,
) {
    val tierEnum get() = PlanTier.from(requiredPlanTier)
}

@Serializable
data class ChatThread(
    val id: String,
    val title: String,
    val modelId: String? = null,
    val isPinned: Boolean = false,
    val isDeleted: Boolean = false,
    val folderId: String? = null,
    val createdAt: String = "",
    val updatedAt: String = "",
)

@Serializable
data class ChatMessage(
    val id: String,
    val role: String,
    val content: String,
    val isDeleted: Boolean = false,
    val createdAt: String = "",
)

@Serializable
data class ChatFolder(
    val id: String,
    val name: String,
    val color: String? = null,
)

data class SubscriptionPlan(
    val planTier: PlanTier,
    val billingCycle: BillingCycle,
    val productId: String,
    val title: String,
)

data class UIChatMessage(
    val id: String,
    val role: Role,
    var text: String,
    var isStreaming: Boolean = false,
    var isFailed: Boolean = false,
    var remoteId: String? = null,
    var poweredBy: String? = null,
) {
    enum class Role { USER, ASSISTANT }
}
