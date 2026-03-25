package com.taba.tabai.feature.chat

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.unit.sp
import com.taba.tabai.core.designsystem.DS
import android.Manifest
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.DisposableEffect
import com.taba.tabai.domain.model.AIModel
import com.taba.tabai.domain.model.StreamingPhase
import com.taba.tabai.domain.model.UIChatMessage
import com.taba.tabai.feature.chat.components.AttachmentSheet
import com.taba.tabai.feature.voice.VoiceInputManager
import kotlinx.coroutines.launch

private val suggestions = listOf(
    "Explain quantum computing simply",
    "Plan a 3-day Istanbul trip",
    "Write a Python web scraper",
    "Compare React vs Compose",
    "Summarize this article for me",
    "Help me debug my code",
)

@Composable
fun ChatScreen(
    state: ChatState,
    models: List<AIModel>,
    selectedModelId: String?,
    planTier: com.taba.tabai.domain.model.PlanTier = com.taba.tabai.domain.model.PlanTier.FREE,
    onSend: (String) -> Unit,
    onStop: () -> Unit,
    onRegenerate: () -> Unit,
    onModelSelected: (String) -> Unit,
    onMenuClick: () -> Unit,
    onNewChat: () -> Unit,
) {
    val clipboardManager = LocalClipboardManager.current
    val context = androidx.compose.ui.platform.LocalContext.current
    var composerText by remember { mutableStateOf("") }
    var showModelPicker by remember { mutableStateOf(false) }
    var showAttachmentSheet by remember { mutableStateOf(false) }
    var showImageGenerator by remember { mutableStateOf(false) }
    var showVideoGenerator by remember { mutableStateOf(false) }
    val listState = rememberLazyListState()
    val scope = rememberCoroutineScope()

    // Attachments
    var attachedImageUri by remember { mutableStateOf<Uri?>(null) }
    val photoPickerLauncher = rememberLauncherForActivityResult(ActivityResultContracts.GetContent()) { uri ->
        attachedImageUri = uri
    }
    val cameraLauncher = rememberLauncherForActivityResult(ActivityResultContracts.TakePicturePreview()) { bitmap ->
        // Camera capture done — bitmap available
    }
    val fileLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        attachedImageUri = uri
    }

    // Voice input
    val voiceManager = remember { VoiceInputManager(context) }
    val voiceState by voiceManager.state.collectAsState()
    val micPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
        voiceManager.onPermissionResult(granted)
        if (granted) voiceManager.startListening()
    }

    // Apply voice transcript to composer
    LaunchedEffect(voiceState.transcript) {
        if (voiceState.transcript.isNotEmpty() && !voiceState.isListening) {
            composerText = voiceState.transcript
            voiceManager.clearTranscript()
        }
    }

    DisposableEffect(Unit) {
        voiceManager.checkPermission()
        onDispose { voiceManager.destroy() }
    }
    val selectedModel = models.firstOrNull { it.id == selectedModelId }

    LaunchedEffect(state.messages.size, state.isStreaming) {
        if (state.messages.isNotEmpty()) {
            listState.animateScrollToItem(state.messages.size - 1)
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Brush.verticalGradient(listOf(DS.backgroundTop, DS.backgroundBottom)))
            .systemBarsPadding()
            .imePadding()
    ) {
        // ── Header ──
        Row(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = onMenuClick) {
                Icon(Icons.Default.Menu, contentDescription = "Menu", tint = DS.textPrimary)
            }
            Spacer(Modifier.weight(1f))
            com.taba.tabai.core.designsystem.components.AnimatedBrandText(fontSize = 17f)
            Spacer(Modifier.weight(1f))
            if (state.messages.isNotEmpty()) {
                IconButton(onClick = onNewChat) {
                    Icon(Icons.Default.EditNote, contentDescription = "New chat", tint = DS.textPrimary)
                }
            } else {
                Spacer(Modifier.size(48.dp))
            }
        }

        // ── Content ──
        if (state.isLoadingChat) {
            Box(Modifier.weight(1f).fillMaxWidth(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = DS.accent, strokeWidth = 2.dp)
            }
        } else if (state.messages.isEmpty()) {
            // Empty state — Perplexity style
            Column(
                modifier = Modifier.weight(1f).fillMaxWidth().padding(horizontal = DS.horizontalPadding),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Spacer(Modifier.weight(0.3f))

                // Animated logo
                com.taba.tabai.core.designsystem.components.AnimatedBrandLogoSimple(size = 72.dp)
                Spacer(Modifier.height(12.dp))

                Text("Ask anything", fontSize = 28.sp, fontWeight = FontWeight.SemiBold, color = DS.textPrimary)
                Spacer(Modifier.height(28.dp))

                // Suggestion grid (2 columns)
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    for (i in suggestions.indices step 2) {
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            suggestions.getOrNull(i)?.let { suggestion ->
                                SuggestionChip(
                                    text = suggestion,
                                    modifier = Modifier.weight(1f),
                                    onClick = { composerText = suggestion },
                                )
                            }
                            suggestions.getOrNull(i + 1)?.let { suggestion ->
                                SuggestionChip(
                                    text = suggestion,
                                    modifier = Modifier.weight(1f),
                                    onClick = { composerText = suggestion },
                                )
                            }
                        }
                    }
                }

                Spacer(Modifier.weight(0.7f))
            }
        } else {
            // Message list
            LazyColumn(
                state = listState,
                modifier = Modifier.weight(1f).fillMaxWidth().padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp),
                contentPadding = PaddingValues(vertical = 12.dp),
            ) {
                items(state.messages, key = { it.id }) { msg ->
                    ChatBubble(msg, state.streamingPhase,
                        onCopy = { clipboardManager.setText(AnnotatedString(msg.text)) },
                        onRegenerate = onRegenerate)
                }
            }
        }

        // ── Error card ──
        state.error?.let { error ->
            Surface(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                shape = RoundedCornerShape(12.dp),
                color = DS.fieldBackground,
            ) {
                Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Default.Warning, contentDescription = null, tint = Color(0xFFFF8C00), modifier = Modifier.size(16.dp))
                    Spacer(Modifier.width(8.dp))
                    Text(error, fontSize = 13.sp, color = DS.textSecondary, maxLines = 2, overflow = TextOverflow.Ellipsis)
                }
            }
        }

        // Voice listening indicator
        if (voiceState.isListening) {
            Surface(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                shape = RoundedCornerShape(12.dp), color = DS.accent.copy(alpha = 0.1f),
            ) {
                Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                    val pulse by rememberInfiniteTransition(label = "mic_pulse").animateFloat(
                        initialValue = 0.4f, targetValue = 1f,
                        animationSpec = infiniteRepeatable(tween(800), RepeatMode.Reverse), label = "p",
                    )
                    Box(Modifier.size(8.dp).clip(CircleShape).background(DS.accent.copy(alpha = pulse)))
                    Spacer(Modifier.width(10.dp))
                    Text("Listening...", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = DS.accent)
                    Spacer(Modifier.weight(1f))
                    TextButton(onClick = { voiceManager.stopListening() }) {
                        Text("Stop", fontSize = 13.sp, color = DS.accent)
                    }
                }
            }
        }

        // ── Composer ──
        ComposerBar(
            text = composerText,
            onTextChange = { composerText = it },
            isStreaming = state.isStreaming,
            isListening = voiceState.isListening,
            selectedModel = selectedModel,
            onSend = {
                if (composerText.isNotBlank()) {
                    onSend(composerText)
                    composerText = ""
                }
            },
            onStop = onStop,
            onAttach = { showAttachmentSheet = true },
            onMic = {
                if (voiceState.isListening) {
                    voiceManager.stopListening()
                } else if (voiceState.hasPermission) {
                    voiceManager.startListening()
                } else {
                    micPermissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                }
            },
            onModelPickerClick = { showModelPicker = true },
        )
    }

    // Attachment sheet
    if (showAttachmentSheet) {
        AttachmentSheet(
            onPhoto = { photoPickerLauncher.launch("image/*") },
            onCamera = { cameraLauncher.launch(null) },
            onFile = { fileLauncher.launch(arrayOf("*/*")) },
            onGenerateImage = { showImageGenerator = true },
            onGenerateVideo = { showVideoGenerator = true },
            onDismiss = { showAttachmentSheet = false },
        )
    }

    // Model picker sheet
    if (showModelPicker) {
        com.taba.tabai.feature.chat.components.ModelPickerSheet(
            models = models,
            selectedModelId = selectedModelId,
            onSelect = { onModelSelected(it); showModelPicker = false },
            onDismiss = { showModelPicker = false },
        )
    }

    // Image generator (full-screen dialog)
    if (showImageGenerator) {
        val genViewModel: com.taba.tabai.feature.generate.GenerationViewModel = androidx.hilt.navigation.compose.hiltViewModel()
        val genState by genViewModel.ui.collectAsState()
        LaunchedEffect(Unit) { genViewModel.loadHistory(); genViewModel.selectMode(com.taba.tabai.feature.generate.GenerationMode.IMAGE) }
        androidx.compose.ui.window.Dialog(onDismissRequest = { showImageGenerator = false }, properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false)) {
            com.taba.tabai.feature.generate.ImageGeneratorScreen(
                uiState = genState,
                planTier = planTier,
                onUpdatePrompt = genViewModel::updatePrompt,
                onUpdateNegativePrompt = genViewModel::updateNegativePrompt,
                onSelectStyle = genViewModel::selectStyle,
                onSelectSize = genViewModel::selectSize,
                onSelectModel = genViewModel::selectImageModel,
                onGenerate = genViewModel::generate,
                onCancel = genViewModel::cancel,
                onReset = genViewModel::reset,
                onDismiss = { showImageGenerator = false },
            )
        }
    }

    // Video generator (full-screen dialog)
    if (showVideoGenerator) {
        val genViewModel: com.taba.tabai.feature.generate.GenerationViewModel = androidx.hilt.navigation.compose.hiltViewModel()
        val genState by genViewModel.ui.collectAsState()
        LaunchedEffect(Unit) { genViewModel.selectMode(com.taba.tabai.feature.generate.GenerationMode.VIDEO) }
        androidx.compose.ui.window.Dialog(onDismissRequest = { showVideoGenerator = false }, properties = androidx.compose.ui.window.DialogProperties(usePlatformDefaultWidth = false)) {
            com.taba.tabai.feature.generate.VideoGeneratorScreen(
                uiState = genState,
                planTier = planTier,
                onUpdatePrompt = genViewModel::updatePrompt,
                onSelectModel = genViewModel::selectVideoModel,
                onSelectDuration = genViewModel::selectDuration,
                onSelectResolution = genViewModel::selectResolution,
                onGenerate = genViewModel::generate,
                onCancel = genViewModel::cancel,
                onReset = genViewModel::reset,
                onDismiss = { showVideoGenerator = false },
            )
        }
    }
}

// ── Composer Bar ──

@Composable
private fun ComposerBar(
    text: String,
    onTextChange: (String) -> Unit,
    isStreaming: Boolean,
    isListening: Boolean = false,
    selectedModel: AIModel?,
    onSend: () -> Unit,
    onStop: () -> Unit,
    onAttach: () -> Unit = {},
    onMic: () -> Unit = {},
    onModelPickerClick: () -> Unit,
) {
    val canSend = text.isNotBlank() && !isStreaming

    Surface(
        modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp).padding(bottom = 8.dp),
        shape = RoundedCornerShape(24.dp),
        color = DS.fieldBackground,
        border = ButtonDefaults.outlinedButtonBorder.copy(
            brush = Brush.linearGradient(listOf(DS.glassStroke.copy(alpha = 0.7f), DS.glassStroke.copy(alpha = 0.7f))),
        ),
    ) {
        Column(modifier = Modifier.padding(top = 4.dp)) {
            // Text input
            TextField(
                value = text,
                onValueChange = onTextChange,
                placeholder = { Text("Ask anything...", color = DS.textSecondary.copy(alpha = 0.6f), fontSize = 15.sp) },
                colors = TextFieldDefaults.colors(
                    focusedContainerColor = Color.Transparent,
                    unfocusedContainerColor = Color.Transparent,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent,
                    cursorColor = DS.accent,
                ),
                modifier = Modifier.fillMaxWidth().heightIn(min = 42.dp, max = 180.dp),
                maxLines = 6,
                textStyle = LocalTextStyle.current.copy(fontSize = 15.sp),
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                keyboardActions = KeyboardActions(onSend = { if (canSend) onSend() }),
            )

            // Bottom toolbar
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp).padding(bottom = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                // Attach button
                Icon(
                    Icons.Default.AddCircleOutline,
                    contentDescription = "Attach",
                    tint = DS.textSecondary,
                    modifier = Modifier.size(22.dp).clickable(onClick = onAttach),
                )
                Spacer(Modifier.width(12.dp))

                // Model picker chip
                Surface(
                    modifier = Modifier.clickable(onClick = onModelPickerClick),
                    shape = RoundedCornerShape(999.dp),
                    color = DS.fieldBackground,
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 10.dp, vertical = 5.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            selectedModel?.displayName?.take(18) ?: "Select model",
                            fontSize = 12.sp, fontWeight = FontWeight.Medium, color = DS.textSecondary,
                            maxLines = 1, overflow = TextOverflow.Ellipsis,
                        )
                        Icon(Icons.Default.ArrowDropDown, contentDescription = null, tint = DS.textSecondary, modifier = Modifier.size(14.dp))
                    }
                }

                Spacer(Modifier.weight(1f))

                // Mic button
                Icon(
                    if (isListening) Icons.Default.GraphicEq else Icons.Default.Mic,
                    contentDescription = "Voice",
                    tint = if (isListening) DS.accent else DS.textSecondary,
                    modifier = Modifier.size(22.dp).clickable(onClick = onMic),
                )
                Spacer(Modifier.width(10.dp))

                // Send / Stop button
                if (isStreaming) {
                    IconButton(onClick = onStop, modifier = Modifier.size(32.dp)) {
                        Box(
                            modifier = Modifier.size(32.dp).clip(CircleShape).background(Color(0xFFFF9500).copy(alpha = 0.15f)),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(Icons.Default.Stop, contentDescription = "Stop", tint = Color(0xFFFF9500), modifier = Modifier.size(16.dp))
                        }
                    }
                } else {
                    IconButton(onClick = { if (canSend) onSend() }, enabled = canSend, modifier = Modifier.size(32.dp)) {
                        Box(
                            modifier = Modifier.size(32.dp).clip(CircleShape)
                                .background(if (canSend) DS.accent.copy(alpha = 0.15f) else Color.Transparent),
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(
                                Icons.Default.ArrowUpward,
                                contentDescription = "Send",
                                tint = if (canSend) DS.accent else DS.textSecondary.copy(alpha = 0.3f),
                                modifier = Modifier.size(16.dp),
                            )
                        }
                    }
                }
            }
        }
    }
}

// ── Chat Bubble ──

@Composable
private fun ChatBubble(message: UIChatMessage, phase: StreamingPhase, onCopy: () -> Unit = {}, onRegenerate: () -> Unit = {}) {
    val isUser = message.role == UIChatMessage.Role.USER

    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = if (isUser) Alignment.End else Alignment.Start,
    ) {
        if (isUser) {
            // User bubble
            Surface(
                shape = RoundedCornerShape(20.dp),
                color = Color.White.copy(alpha = 0.08f),
                modifier = Modifier.widthIn(max = 300.dp),
            ) {
                Text(
                    message.text, fontSize = 15.sp, color = DS.textPrimary, lineHeight = 22.sp,
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                )
            }
        } else {
            // Assistant answer card (Perplexity-style)
            Column(modifier = Modifier.fillMaxWidth()) {
                // AI label
                Text("AI", fontSize = 11.sp, fontWeight = FontWeight.SemiBold, color = DS.accent,
                    modifier = Modifier.padding(bottom = 6.dp))

                if (message.text.isEmpty() && message.isStreaming) {
                    // Thinking dots
                    ThinkingDots()
                } else {
                    // Message text
                    Text(
                        message.text, fontSize = 15.sp, color = DS.textPrimary, lineHeight = 22.sp,
                    )

                    // Blinking cursor while streaming
                    if (message.isStreaming && phase == StreamingPhase.GENERATING) {
                        val alpha by rememberInfiniteTransition(label = "cursor").animateFloat(
                            initialValue = 1f, targetValue = 0f,
                            animationSpec = infiniteRepeatable(tween(550), RepeatMode.Reverse),
                            label = "cursor_alpha",
                        )
                        Text("▌", fontSize = 15.sp, color = DS.accent.copy(alpha = alpha))
                    }
                }

                // Powered by (TABAI composite model)
                if (message.poweredBy != null && !message.isStreaming) {
                    Text(
                        "Powered by ${message.poweredBy}",
                        fontSize = 11.sp,
                        color = DS.textSecondary.copy(alpha = 0.5f),
                        modifier = Modifier.padding(top = 4.dp),
                    )
                }

                if (message.isFailed) {
                    Row(modifier = Modifier.padding(top = 6.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(Icons.Default.Warning, contentDescription = null, tint = Color(0xFFFF8C00), modifier = Modifier.size(14.dp))
                        Spacer(Modifier.width(6.dp))
                        Text("Response failed", fontSize = 12.sp, color = Color(0xFFFF8C00))
                    }
                }

                // Action bar
                if (!message.isStreaming && message.text.isNotEmpty()) {
                    HorizontalDivider(color = DS.cardBorder, modifier = Modifier.padding(vertical = 10.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        ActionButton(Icons.Default.ContentCopy, "Copy", onCopy)
                        ActionButton(Icons.Default.Refresh, "Regenerate", onRegenerate)
                    }
                }
            }
        }
    }
}

@Composable
private fun ThinkingDots() {
    val transition = rememberInfiniteTransition(label = "dots")
    Row(horizontalArrangement = Arrangement.spacedBy(4.dp), modifier = Modifier.padding(vertical = 8.dp)) {
        repeat(3) { i ->
            val alpha by transition.animateFloat(
                initialValue = 0.3f, targetValue = 1f,
                animationSpec = infiniteRepeatable(
                    tween(600, delayMillis = i * 150),
                    RepeatMode.Reverse,
                ),
                label = "dot_$i",
            )
            Box(
                modifier = Modifier.size(6.dp).clip(CircleShape).background(DS.accent.copy(alpha = alpha)),
            )
        }
        Spacer(Modifier.width(8.dp))
        Text("Thinking...", fontSize = 14.sp, color = DS.textSecondary)
    }
}

@Composable
private fun ActionButton(icon: androidx.compose.ui.graphics.vector.ImageVector, label: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier.clickable(onClick = onClick).padding(vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(icon, contentDescription = label, tint = DS.textSecondary, modifier = Modifier.size(14.dp))
        Text(label, fontSize = 12.sp, fontWeight = FontWeight.Medium, color = DS.textSecondary)
    }
}

@Composable
private fun SuggestionChip(text: String, modifier: Modifier = Modifier, onClick: () -> Unit) {
    Surface(
        modifier = modifier.clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        color = Color.White.copy(alpha = 0.05f),
        border = ButtonDefaults.outlinedButtonBorder.copy(
            brush = Brush.linearGradient(listOf(Color.White.copy(alpha = 0.08f), Color.White.copy(alpha = 0.08f))),
        ),
    ) {
        Text(
            text, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = DS.textSecondary,
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
            maxLines = 2, overflow = TextOverflow.Ellipsis,
        )
    }
}
