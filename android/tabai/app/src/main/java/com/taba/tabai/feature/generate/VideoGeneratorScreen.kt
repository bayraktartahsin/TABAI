package com.taba.tabai.feature.generate

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.taba.tabai.core.designsystem.DS
import com.taba.tabai.domain.model.PlanTier

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VideoGeneratorScreen(
    uiState: GenerationUiState,
    planTier: PlanTier,
    onUpdatePrompt: (String) -> Unit,
    onSelectModel: (String) -> Unit,
    onSelectDuration: (String) -> Unit,
    onSelectResolution: (String) -> Unit,
    onGenerate: () -> Unit,
    onCancel: () -> Unit,
    onReset: () -> Unit,
    onDismiss: () -> Unit,
) {
    val accessibleModels = FalModelInfo.accessibleModels(planTier, "video")
    val scrollState = rememberScrollState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Generate Video", fontSize = 17.sp, fontWeight = FontWeight.SemiBold) },
                navigationIcon = {
                    IconButton(onClick = onDismiss) {
                        Icon(Icons.Default.Close, contentDescription = "Close")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = DS.backgroundTop),
            )
        },
        containerColor = DS.backgroundTop,
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(scrollState)
                .padding(horizontal = DS.horizontalPadding)
                .padding(bottom = 40.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            // Prompt
            OutlinedTextField(
                value = uiState.prompt,
                onValueChange = onUpdatePrompt,
                modifier = Modifier.fillMaxWidth().heightIn(min = 100.dp),
                placeholder = { Text("Describe the video you want to create...", color = DS.textSecondary.copy(alpha = 0.6f)) },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = DS.textPrimary,
                    unfocusedTextColor = DS.textPrimary,
                    focusedBorderColor = DS.accent,
                    unfocusedBorderColor = DS.glassStroke,
                    focusedContainerColor = DS.fieldBackground,
                    unfocusedContainerColor = DS.fieldBackground,
                ),
                shape = RoundedCornerShape(DS.fieldCornerRadius),
            )

            // Duration
            SectionLabel("Duration")
            ChipRow(listOf("3s", "5s", "10s"), listOf("3", "5", "10").indexOf(uiState.selectedDuration).coerceAtLeast(0)) {
                onSelectDuration(listOf("3", "5", "10")[it])
            }

            // Resolution
            SectionLabel("Resolution")
            ChipRow(listOf("720p", "1080p"), listOf("720p", "1080p").indexOf(uiState.selectedResolution).coerceAtLeast(0)) {
                onSelectResolution(listOf("720p", "1080p")[it])
            }

            // Model
            SectionLabel("Model")
            if (accessibleModels.isEmpty()) {
                Text("Upgrade to Pro to generate videos.", color = DS.textSecondary, fontSize = 14.sp)
            } else {
                ChipRow(accessibleModels.map { it.displayName }, accessibleModels.indexOfFirst { it.id == uiState.selectedVideoModelId }.coerceAtLeast(0)) {
                    onSelectModel(accessibleModels[it].id)
                }
            }

            // Generate / Progress / Result
            when (val state = uiState.state) {
                is GenerationState.Idle -> {
                    Button(
                        onClick = onGenerate,
                        modifier = Modifier.fillMaxWidth().height(50.dp),
                        shape = RoundedCornerShape(DS.fieldCornerRadius),
                        colors = ButtonDefaults.buttonColors(containerColor = if (uiState.prompt.isNotBlank()) DS.accent else DS.textSecondary.copy(alpha = 0.3f)),
                        enabled = uiState.prompt.isNotBlank(),
                    ) {
                        Text("Generate Video", fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
                    }
                }
                is GenerationState.Submitting, is GenerationState.Polling -> {
                    GenerationProgress(text = uiState.progressText, onCancel = onCancel)
                }
                is GenerationState.Completed -> {
                    GenerationResultCard(resultUrl = state.resultUrl, prompt = uiState.prompt)
                    Button(
                        onClick = onReset,
                        modifier = Modifier.fillMaxWidth().height(50.dp),
                        shape = RoundedCornerShape(DS.fieldCornerRadius),
                        colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
                    ) {
                        Text("Generate Another", fontWeight = FontWeight.SemiBold)
                    }
                }
                is GenerationState.Failed -> {
                    Text(state.message, color = DS.danger, fontSize = 13.sp)
                    Button(
                        onClick = onReset,
                        modifier = Modifier.fillMaxWidth().height(50.dp),
                        shape = RoundedCornerShape(DS.fieldCornerRadius),
                        colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
                    ) {
                        Text("Try Again", fontWeight = FontWeight.SemiBold)
                    }
                }
            }
        }
    }
}
