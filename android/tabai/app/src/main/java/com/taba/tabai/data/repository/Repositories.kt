package com.taba.tabai.data.repository

import com.taba.tabai.data.dto.*
import com.taba.tabai.data.local.DataStoreManager
import com.taba.tabai.data.remote.api.TABAIApi
import com.taba.tabai.data.remote.sse.SSEClient
import com.taba.tabai.data.remote.sse.SSEEvent
import com.taba.tabai.domain.model.*
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthRepository @Inject constructor(
    private val api: TABAIApi,
    private val dataStore: DataStoreManager,
) {
    suspend fun signIn(email: String, password: String): Result<UserProfile> {
        val res = api.signIn(SignInRequest(email.trim(), password))
        return if (res.isSuccessful && res.body()?.user != null) Result.success(res.body()!!.user!!)
        else Result.failure(Exception(res.body()?.error ?: "Sign in failed"))
    }

    suspend fun signUp(email: String, username: String, password: String): Result<UserProfile> {
        val res = api.signUp(SignUpRequest(email.trim(), username.trim(), password))
        return if (res.isSuccessful && res.body()?.user != null) Result.success(res.body()!!.user!!)
        else Result.failure(Exception(res.body()?.error ?: "Sign up failed"))
    }

    suspend fun me(): Result<UserProfile> {
        val res = api.me()
        return if (res.isSuccessful && res.body()?.user != null) Result.success(res.body()!!.user!!)
        else Result.failure(Exception("Not authenticated"))
    }

    suspend fun signOut() {
        try { api.signOut() } catch (_: Exception) {}
        dataStore.setAuthToken(null)
    }
}

@Singleton
class BootstrapRepository @Inject constructor(private val api: TABAIApi) {
    suspend fun fetch(): Result<BootstrapResponse> {
        val res = api.bootstrap()
        return if (res.isSuccessful && res.body() != null) Result.success(res.body()!!)
        else Result.failure(Exception("Bootstrap failed"))
    }
}

@Singleton
class ModelRepository @Inject constructor(private val api: TABAIApi) {
    suspend fun fetchModels(): Result<List<AIModel>> {
        val res = api.models()
        return if (res.isSuccessful) Result.success(res.body()?.models ?: emptyList())
        else Result.failure(Exception("Failed to load models"))
    }
}

@Singleton
class ChatRepository @Inject constructor(
    private val api: TABAIApi,
    private val sseClient: SSEClient,
) {
    suspend fun fetchChats(): List<ChatThread> {
        return api.chats().body()?.chats ?: emptyList()
    }

    suspend fun createChat(id: String, title: String, modelId: String): ChatDetailResponse? {
        val res = api.createChat(ChatCreateRequest(id, title, modelId))
        return res.body()
    }

    suspend fun fetchMessages(chatId: String): ChatDetailResponse? {
        return api.messages(chatId).body()
    }

    suspend fun createMessage(chatId: String, role: String, content: String): ChatMessage? {
        val res = api.createMessage(chatId, MessageCreateRequest(role, content))
        return res.body()?.message
    }

    suspend fun deleteChat(chatId: String) {
        api.deleteChat(chatId)
    }

    fun streamChat(chatId: String?, model: String, messages: List<StreamMessage>): Flow<SSEEvent> {
        return sseClient.stream(StreamRequest(chatId = chatId, model = model, messages = messages))
    }
}

@Singleton
class EntitlementRepository @Inject constructor(private val api: TABAIApi) {
    suspend fun syncGooglePurchase(productId: String, purchaseToken: String): Result<StoreSyncResponse> {
        val res = api.syncEntitlement(StoreSyncRequest(provider = "google", productId = productId, purchaseToken = purchaseToken))
        return if (res.isSuccessful && res.body() != null) Result.success(res.body()!!)
        else Result.failure(Exception("Entitlement sync failed"))
    }
}
