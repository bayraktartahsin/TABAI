package com.taba.tabai.data.dto

import kotlinx.serialization.Serializable

@Serializable
data class GenerateImageRequest(
    val prompt: String,
    val negativePrompt: String? = null,
    val modelId: String,
    val chatId: String? = null,
    val imageSize: String? = null,
    val numImages: Int? = null,
    val style: String? = null,
)

@Serializable
data class GenerateVideoRequest(
    val prompt: String,
    val negativePrompt: String? = null,
    val modelId: String,
    val chatId: String? = null,
    val duration: String? = null,
    val resolution: String? = null,
    val imageUrl: String? = null,
)

@Serializable
data class GenerationSubmitResponse(
    val id: String,
    val falRequestId: String = "",
    val status: String = "queued",
)

@Serializable
data class GenerationStatusResponse(
    val id: String,
    val status: String,
    val resultUrl: String? = null,
    val queuePosition: Int? = null,
    val errorMessage: String? = null,
)

@Serializable
data class GenerationRecordDTO(
    val id: String,
    val userId: String = "",
    val chatId: String? = null,
    val falRequestId: String = "",
    val provider: String = "fal",
    val modelId: String = "",
    val modelDisplayName: String? = null,
    val generationType: String = "image",
    val status: String = "queued",
    val prompt: String = "",
    val negativePrompt: String? = null,
    val resultUrl: String? = null,
    val estimatedCostUnits: Int = 0,
    val errorMessage: String? = null,
    val createdAt: String = "",
    val completedAt: String? = null,
)

@Serializable
data class GenerationHistoryResponse(
    val generations: List<GenerationRecordDTO> = emptyList(),
)

@Serializable
data class GenerationCancelResponse(
    val ok: Boolean = false,
    val cancelled: String? = null,
)
