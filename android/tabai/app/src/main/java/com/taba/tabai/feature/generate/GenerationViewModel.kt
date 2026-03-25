package com.taba.tabai.feature.generate

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.taba.tabai.data.dto.*
import com.taba.tabai.data.repository.GenerationRepository
import com.taba.tabai.domain.model.PlanTier
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import javax.inject.Inject

enum class GenerationMode { IMAGE, VIDEO }

enum class ImageStyle(val label: String) {
    PHOTO("Photo"), ART("Art"), ILLUSTRATION("Illustration"), THREE_D("3D"), ANIME("Anime")
}

enum class ImageSize(val value: String, val label: String) {
    SQUARE_HD("square_hd", "Square HD"),
    SQUARE("square", "Square"),
    LANDSCAPE("landscape_4_3", "4:3"),
    WIDE("landscape_16_9", "16:9"),
    PORTRAIT("portrait_4_3", "Portrait"),
}

data class FalModelInfo(
    val id: String,
    val displayName: String,
    val generationType: String,
    val minTier: PlanTier,
) {
    companion object {
        val imageModels = listOf(
            FalModelInfo("fal-ai/flux/schnell", "TABAI Image Fast", "image", PlanTier.STARTER),
            FalModelInfo("fal-ai/flux/dev", "TABAI Image", "image", PlanTier.PRO),
            FalModelInfo("fal-ai/flux-2-pro", "TABAI Image Pro", "image", PlanTier.PRO),
            FalModelInfo("fal-ai/flux-2-pro-ultra", "TABAI Image Ultra", "image", PlanTier.POWER),
        )
        val videoModels = listOf(
            FalModelInfo("fal-ai/kling-video/v2.5/master/text-to-video", "TABAI Video", "video", PlanTier.PRO),
            FalModelInfo("fal-ai/veo3", "TABAI Video Pro", "video", PlanTier.POWER),
            FalModelInfo("fal-ai/sora-2-pro", "TABAI Video Ultra", "video", PlanTier.POWER),
        )

        fun accessibleModels(tier: PlanTier, type: String): List<FalModelInfo> {
            val source = if (type == "image") imageModels else videoModels
            return source.filter { tier.ordinal >= it.minTier.ordinal }
        }
    }
}

sealed class GenerationState {
    data object Idle : GenerationState()
    data object Submitting : GenerationState()
    data class Polling(val generationId: String) : GenerationState()
    data class Completed(val resultUrl: String) : GenerationState()
    data class Failed(val message: String) : GenerationState()
}

data class GenerationUiState(
    val mode: GenerationMode = GenerationMode.IMAGE,
    val prompt: String = "",
    val negativePrompt: String = "",
    val selectedImageModelId: String = FalModelInfo.imageModels.firstOrNull()?.id ?: "",
    val selectedVideoModelId: String = FalModelInfo.videoModels.firstOrNull()?.id ?: "",
    val selectedStyle: ImageStyle = ImageStyle.PHOTO,
    val selectedSize: ImageSize = ImageSize.SQUARE_HD,
    val selectedDuration: String = "5",
    val selectedResolution: String = "720p",
    val state: GenerationState = GenerationState.Idle,
    val progressText: String = "",
    val queuePosition: Int? = null,
    val history: List<GenerationRecordDTO> = emptyList(),
)

@HiltViewModel
class GenerationViewModel @Inject constructor(
    private val repository: GenerationRepository,
) : ViewModel() {

    private val _ui = MutableStateFlow(GenerationUiState())
    val ui: StateFlow<GenerationUiState> = _ui

    private var pollingJob: Job? = null

    fun updatePrompt(text: String) { _ui.update { it.copy(prompt = text) } }
    fun updateNegativePrompt(text: String) { _ui.update { it.copy(negativePrompt = text) } }
    fun selectMode(mode: GenerationMode) { _ui.update { it.copy(mode = mode) } }
    fun selectImageModel(id: String) { _ui.update { it.copy(selectedImageModelId = id) } }
    fun selectVideoModel(id: String) { _ui.update { it.copy(selectedVideoModelId = id) } }
    fun selectStyle(style: ImageStyle) { _ui.update { it.copy(selectedStyle = style) } }
    fun selectSize(size: ImageSize) { _ui.update { it.copy(selectedSize = size) } }
    fun selectDuration(d: String) { _ui.update { it.copy(selectedDuration = d) } }
    fun selectResolution(r: String) { _ui.update { it.copy(selectedResolution = r) } }

    val canGenerate: Boolean get() = _ui.value.prompt.isNotBlank() && _ui.value.state is GenerationState.Idle

    fun generate() {
        val s = _ui.value
        if (s.prompt.isBlank() || s.state !is GenerationState.Idle) return

        _ui.update { it.copy(state = GenerationState.Submitting, progressText = "Submitting...") }

        viewModelScope.launch {
            val result = if (s.mode == GenerationMode.IMAGE) {
                repository.submitImage(
                    GenerateImageRequest(
                        prompt = s.prompt.trim(),
                        negativePrompt = s.negativePrompt.trim().ifBlank { null },
                        modelId = s.selectedImageModelId,
                        imageSize = s.selectedSize.value,
                        numImages = 1,
                        style = s.selectedStyle.name.lowercase(),
                    )
                )
            } else {
                repository.submitVideo(
                    GenerateVideoRequest(
                        prompt = s.prompt.trim(),
                        negativePrompt = s.negativePrompt.trim().ifBlank { null },
                        modelId = s.selectedVideoModelId,
                        duration = s.selectedDuration,
                        resolution = s.selectedResolution,
                    )
                )
            }

            result.fold(
                onSuccess = { response ->
                    _ui.update {
                        it.copy(
                            state = GenerationState.Polling(response.id),
                            progressText = if (s.mode == GenerationMode.IMAGE) "Creating your image..." else "Creating your video...",
                        )
                    }
                    startPolling(response.id, s.mode)
                },
                onFailure = { error ->
                    _ui.update { it.copy(state = GenerationState.Failed(error.message ?: "Generation failed"), progressText = "") }
                },
            )
        }
    }

    fun cancel() {
        pollingJob?.cancel()
        pollingJob = null
        val s = _ui.value
        if (s.state is GenerationState.Polling) {
            viewModelScope.launch { repository.cancel(s.state.generationId) }
        }
        _ui.update { it.copy(state = GenerationState.Idle, progressText = "", queuePosition = null) }
    }

    fun reset() {
        pollingJob?.cancel()
        pollingJob = null
        _ui.update { it.copy(state = GenerationState.Idle, progressText = "", queuePosition = null) }
    }

    fun loadHistory() {
        viewModelScope.launch {
            repository.getHistory().onSuccess { records ->
                _ui.update { it.copy(history = records) }
            }
        }
    }

    private fun startPolling(generationId: String, mode: GenerationMode) {
        pollingJob?.cancel()
        pollingJob = viewModelScope.launch {
            var attempts = 0
            while (isActive) {
                repository.checkStatus(generationId).onSuccess { status ->
                    _ui.update { it.copy(queuePosition = status.queuePosition) }
                    when (status.status) {
                        "completed" -> {
                            val url = status.resultUrl
                            if (url != null) {
                                _ui.update { it.copy(state = GenerationState.Completed(url), progressText = "") }
                                loadHistory()
                            } else {
                                _ui.update { it.copy(state = GenerationState.Failed("No result URL"), progressText = "") }
                            }
                            return@launch
                        }
                        "failed" -> {
                            _ui.update { it.copy(state = GenerationState.Failed(status.errorMessage ?: "Failed"), progressText = "") }
                            return@launch
                        }
                        "processing" -> {
                            _ui.update { it.copy(progressText = if (mode == GenerationMode.IMAGE) "Almost ready..." else "Rendering video...") }
                        }
                        else -> {
                            val pos = status.queuePosition
                            _ui.update {
                                it.copy(progressText = if (pos != null && pos > 0) "Queue position: $pos"
                                    else if (mode == GenerationMode.IMAGE) "Creating your image..." else "Creating your video...")
                            }
                        }
                    }
                }
                attempts++
                val delayMs = if (mode == GenerationMode.IMAGE) { if (attempts < 5) 1500L else 3000L } else { if (attempts < 3) 3000L else 5000L }
                delay(delayMs)
            }
        }
    }
}
