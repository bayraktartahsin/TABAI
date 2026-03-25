package com.taba.tabai.data.repository

import com.taba.tabai.data.dto.*
import com.taba.tabai.data.remote.api.TABAIApi
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class GenerationRepository @Inject constructor(
    private val api: TABAIApi,
) {
    suspend fun submitImage(request: GenerateImageRequest): Result<GenerationSubmitResponse> {
        val res = api.generateImage(request)
        return if (res.isSuccessful && res.body() != null) Result.success(res.body()!!)
        else Result.failure(Exception(res.errorBody()?.string()?.take(200) ?: "Image generation failed"))
    }

    suspend fun submitVideo(request: GenerateVideoRequest): Result<GenerationSubmitResponse> {
        val res = api.generateVideo(request)
        return if (res.isSuccessful && res.body() != null) Result.success(res.body()!!)
        else Result.failure(Exception(res.errorBody()?.string()?.take(200) ?: "Video generation failed"))
    }

    suspend fun checkStatus(generationId: String): Result<GenerationStatusResponse> {
        val res = api.generationStatus(generationId)
        return if (res.isSuccessful && res.body() != null) Result.success(res.body()!!)
        else Result.failure(Exception("Status check failed"))
    }

    suspend fun getResult(generationId: String): Result<GenerationRecordDTO> {
        val res = api.generationResult(generationId)
        return if (res.isSuccessful && res.body() != null) Result.success(res.body()!!)
        else Result.failure(Exception("Failed to get result"))
    }

    suspend fun getHistory(limit: Int = 50, offset: Int = 0): Result<List<GenerationRecordDTO>> {
        val res = api.generationHistory(limit, offset)
        return if (res.isSuccessful) Result.success(res.body()?.generations ?: emptyList())
        else Result.failure(Exception("Failed to load history"))
    }

    suspend fun cancel(generationId: String): Result<Unit> {
        val res = api.cancelGeneration(generationId)
        return if (res.isSuccessful) Result.success(Unit)
        else Result.failure(Exception("Cancel failed"))
    }
}
