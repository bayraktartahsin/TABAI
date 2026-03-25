package com.taba.tabai.data.dto

import com.taba.tabai.domain.model.*
import kotlinx.serialization.Serializable

@Serializable
data class SignInRequest(val email: String, val password: String)

@Serializable
data class SignUpRequest(val email: String, val username: String, val password: String)

@Serializable
data class AuthResponse(val user: UserProfile? = null, val error: String? = null)

@Serializable
data class MeResponse(val user: UserProfile? = null, val error: String? = null)

@Serializable
data class BootstrapResponse(
    val user: UserProfile,
    val models: List<AIModel> = emptyList(),
    val chats: List<ChatThread> = emptyList(),
    val settings: SettingsDTO? = null,
)

@Serializable
data class SettingsDTO(
    val theme: String = "system",
    val language: String = "en",
)

@Serializable
data class ChatsResponse(val chats: List<ChatThread> = emptyList())

@Serializable
data class ChatCreateRequest(val id: String, val title: String, val modelId: String, val folderId: String? = null)

@Serializable
data class ChatDetailResponse(val chat: ChatThread, val messages: List<ChatMessage> = emptyList())

@Serializable
data class MessageCreateRequest(val role: String, val content: String)

@Serializable
data class MessageResponse(val message: ChatMessage)

@Serializable
data class ModelsResponse(val models: List<AIModel> = emptyList())

@Serializable
data class StreamRequest(
    val chatId: String? = null,
    val model: String,
    val messages: List<StreamMessage>,
    val maxTokens: Int = 1024,
)

@Serializable
data class StreamMessage(val role: String, val content: String)

@Serializable
data class StoreSyncRequest(
    val provider: String = "google",
    val productId: String? = null,
    val purchaseToken: String? = null,
    val environment: String = "production",
)

@Serializable
data class StoreSyncResponse(
    val code: String? = null,
    val message: String? = null,
    val entitlement: EntitlementInfo? = null,
)

@Serializable
data class FolderCreateRequest(val name: String)

@Serializable
data class FolderResponse(val folder: ChatFolder)

@Serializable
data class FoldersResponse(val folders: List<ChatFolder> = emptyList())

@Serializable
data class ErrorResponse(val error: String? = null, val code: String? = null)
