package com.taba.tabai.feature.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.taba.tabai.data.dto.StreamMessage
import com.taba.tabai.data.repository.ChatRepository
import com.taba.tabai.domain.model.*
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.util.UUID
import javax.inject.Inject

data class ChatState(
    val messages: List<UIChatMessage> = emptyList(),
    val isStreaming: Boolean = false,
    val streamingPhase: StreamingPhase = StreamingPhase.IDLE,
    val isLoadingChat: Boolean = false,
    val error: String? = null,
    val currentThreadId: String? = null,
)

@HiltViewModel
class ChatViewModel @Inject constructor(
    private val chatRepository: ChatRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(ChatState())
    val state: StateFlow<ChatState> = _state

    private var streamJob: Job? = null
    var selectedModelId: String? = null
    var isAuthenticated: Boolean = false

    fun loadChat(threadId: String) {
        viewModelScope.launch {
            _state.update { it.copy(isLoadingChat = true, error = null) }
            val detail = chatRepository.fetchMessages(threadId)
            if (detail != null) {
                _state.update {
                    it.copy(
                        isLoadingChat = false,
                        currentThreadId = threadId,
                        messages = detail.messages.map { m ->
                            UIChatMessage(
                                id = m.id,
                                role = if (m.role == "user") UIChatMessage.Role.USER else UIChatMessage.Role.ASSISTANT,
                                text = m.content,
                                remoteId = m.id,
                            )
                        },
                    )
                }
            } else {
                _state.update { it.copy(isLoadingChat = false, error = "Could not load chat") }
            }
        }
    }

    fun beginNewChat() {
        stopStreaming()
        _state.update { ChatState() }
    }

    fun send(text: String) {
        val trimmed = text.trim()
        if (trimmed.isEmpty() || !isAuthenticated) return
        val modelId = selectedModelId ?: return

        viewModelScope.launch {
            // Add user message
            val userMsg = UIChatMessage(id = UUID.randomUUID().toString(), role = UIChatMessage.Role.USER, text = trimmed)
            _state.update { it.copy(messages = it.messages + userMsg, error = null) }

            // Create thread if needed
            var threadId = _state.value.currentThreadId
            if (threadId == null) {
                val title = trimmed.take(42).ifBlank { "New Chat" }
                val detail = chatRepository.createChat(UUID.randomUUID().toString(), title, modelId)
                threadId = detail?.chat?.id
                _state.update { it.copy(currentThreadId = threadId) }
            }
            if (threadId == null) {
                _state.update { s ->
                    val msgs = s.messages.toMutableList()
                    msgs.lastOrNull()?.let { it.isFailed = true }
                    s.copy(messages = msgs, error = "Failed to create chat")
                }
                return@launch
            }

            // Create message on server
            val created = chatRepository.createMessage(threadId, "user", trimmed)
            if (created != null) {
                _state.update { s ->
                    val msgs = s.messages.toMutableList()
                    msgs.lastOrNull { it.role == UIChatMessage.Role.USER && it.remoteId == null }?.remoteId = created.id
                    s.copy(messages = msgs)
                }
            }

            // Build history for streaming
            val history = _state.value.messages.map {
                StreamMessage(role = if (it.role == UIChatMessage.Role.USER) "user" else "assistant", content = it.text)
            }

            startStreaming(threadId, modelId, history)
        }
    }

    private fun startStreaming(chatId: String, modelId: String, messages: List<StreamMessage>) {
        stopStreaming()

        val assistantMsg = UIChatMessage(
            id = UUID.randomUUID().toString(),
            role = UIChatMessage.Role.ASSISTANT,
            text = "",
            isStreaming = true,
        )
        _state.update { it.copy(messages = it.messages + assistantMsg, isStreaming = true, streamingPhase = StreamingPhase.THINKING) }

        streamJob = viewModelScope.launch {
            val buffer = StringBuilder()
            chatRepository.streamChat(chatId, modelId, messages).collect { event ->
                when (event.event) {
                    "token" -> {
                        val token = event.data
                            .removePrefix("{\"token\":\"").removeSuffix("\"}")
                            .replace("\\n", "\n").replace("\\t", "\t").replace("\\\"", "\"")
                        buffer.append(token)
                        _state.update { s ->
                            val msgs = s.messages.toMutableList()
                            msgs.lastOrNull()?.text = buffer.toString()
                            s.copy(messages = msgs, streamingPhase = StreamingPhase.GENERATING)
                        }
                    }
                    "metadata" -> {
                        // TABAI composite model: extract poweredBy
                        val poweredBy = event.data
                            .let { """\"poweredBy\"\s*:\s*\"([^"]+)\"""".toRegex().find(it)?.groupValues?.get(1) }
                        if (poweredBy != null) {
                            _state.update { s ->
                                val msgs = s.messages.toMutableList()
                                msgs.lastOrNull()?.poweredBy = poweredBy
                                s.copy(messages = msgs)
                            }
                        }
                    }
                    "done" -> {
                        _state.update { s ->
                            val msgs = s.messages.toMutableList()
                            msgs.lastOrNull()?.isStreaming = false
                            s.copy(messages = msgs, isStreaming = false, streamingPhase = StreamingPhase.IDLE)
                        }
                    }
                    "error" -> {
                        _state.update { s ->
                            val msgs = s.messages.toMutableList()
                            msgs.lastOrNull()?.apply { isStreaming = false; isFailed = true; text = buffer.toString() }
                            s.copy(messages = msgs, isStreaming = false, streamingPhase = StreamingPhase.IDLE, error = event.data)
                        }
                    }
                }
            }
            // If flow completes without done event
            _state.update { s ->
                val msgs = s.messages.toMutableList()
                msgs.lastOrNull()?.isStreaming = false
                s.copy(messages = msgs, isStreaming = false, streamingPhase = StreamingPhase.IDLE)
            }
        }
    }

    fun stopStreaming() {
        streamJob?.cancel()
        streamJob = null
        _state.update { s ->
            val msgs = s.messages.toMutableList()
            msgs.lastOrNull()?.isStreaming = false
            s.copy(messages = msgs, isStreaming = false, streamingPhase = StreamingPhase.IDLE)
        }
    }

    fun regenerate() {
        val s = _state.value
        val modelId = selectedModelId ?: return
        val threadId = s.currentThreadId ?: return
        val lastAssistantIdx = s.messages.indexOfLast { it.role == UIChatMessage.Role.ASSISTANT }
        if (lastAssistantIdx < 0) return
        val history = s.messages.filterIndexed { i, _ -> i != lastAssistantIdx }
            .map { StreamMessage(role = if (it.role == UIChatMessage.Role.USER) "user" else "assistant", content = it.text) }
        _state.update { it.copy(messages = it.messages.filterIndexed { i, _ -> i != lastAssistantIdx }) }
        startStreaming(threadId, modelId, history)
    }
}
