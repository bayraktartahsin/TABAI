package com.taba.tabai.data.remote.api

import com.taba.tabai.data.dto.*
import retrofit2.Response
import retrofit2.http.*

interface TABAIApi {
    // Auth
    @POST("/api/auth/signin")
    suspend fun signIn(@Body body: SignInRequest): Response<AuthResponse>

    @POST("/api/auth/signup")
    suspend fun signUp(@Body body: SignUpRequest): Response<AuthResponse>

    @POST("/api/auth/signout")
    suspend fun signOut(): Response<Unit>

    @GET("/api/auth/me")
    suspend fun me(): Response<MeResponse>

    // Bootstrap
    @GET("/api/bootstrap")
    suspend fun bootstrap(): Response<BootstrapResponse>

    // Models
    @GET("/api/models")
    suspend fun models(): Response<ModelsResponse>

    // Chats
    @GET("/api/chats")
    suspend fun chats(): Response<ChatsResponse>

    @POST("/api/chats")
    suspend fun createChat(@Body body: ChatCreateRequest): Response<ChatDetailResponse>

    @GET("/api/chats/{chatId}/messages")
    suspend fun messages(@Path("chatId") chatId: String): Response<ChatDetailResponse>

    @DELETE("/api/chats/{chatId}")
    suspend fun deleteChat(@Path("chatId") chatId: String): Response<Unit>

    // Messages
    @POST("/api/chats/{chatId}/messages")
    suspend fun createMessage(@Path("chatId") chatId: String, @Body body: MessageCreateRequest): Response<MessageResponse>

    // Folders
    @GET("/api/folders")
    suspend fun folders(): Response<FoldersResponse>

    @POST("/api/folders")
    suspend fun createFolder(@Body body: FolderCreateRequest): Response<FolderResponse>

    // Entitlement sync
    @POST("/api/entitlements/store/sync")
    suspend fun syncEntitlement(@Body body: StoreSyncRequest): Response<StoreSyncResponse>

    // fal.ai Generation
    @POST("/api/generate/image")
    suspend fun generateImage(@Body body: GenerateImageRequest): Response<GenerationSubmitResponse>

    @POST("/api/generate/video")
    suspend fun generateVideo(@Body body: GenerateVideoRequest): Response<GenerationSubmitResponse>

    @GET("/api/generate/status/{id}")
    suspend fun generationStatus(@Path("id") id: String): Response<GenerationStatusResponse>

    @GET("/api/generate/{id}")
    suspend fun generationResult(@Path("id") id: String): Response<GenerationRecordDTO>

    @GET("/api/generate/history")
    suspend fun generationHistory(@Query("limit") limit: Int = 50, @Query("offset") offset: Int = 0): Response<GenerationHistoryResponse>

    @DELETE("/api/generate/{id}")
    suspend fun cancelGeneration(@Path("id") id: String): Response<GenerationCancelResponse>
}
