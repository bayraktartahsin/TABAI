package com.taba.tabai.feature.generate

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Close
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.AsyncImage
import com.taba.tabai.core.designsystem.DS
import com.taba.tabai.domain.model.PlanTier

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ImageGeneratorScreen(
    uiState: GenerationUiState,
    planTier: PlanTier,
    onUpdatePrompt: (String) -> Unit,
    onUpdateNegativePrompt: (String) -> Unit,
    onSelectStyle: (ImageStyle) -> Unit,
    onSelectSize: (ImageSize) -> Unit,
    onSelectModel: (String) -> Unit,
    onGenerate: () -> Unit,
    onCancel: () -> Unit,
    onReset: () -> Unit,
    onDismiss: () -> Unit,
) {
    val accessibleModels = FalModelInfo.accessibleModels(planTier, "image")
    val scrollState = rememberScrollState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Generate Image", fontSize = 17.sp, fontWeight = FontWeight.SemiBold) },
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
                placeholder = { Text("Describe what you want to create...", color = DS.textSecondary.copy(alpha = 0.6f)) },
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

            // Style selector
            SectionLabel("Style")
            ChipRow(ImageStyle.entries.map { it.label }, ImageStyle.entries.indexOf(uiState.selectedStyle)) {
                onSelectStyle(ImageStyle.entries[it])
            }

            // Size selector
            SectionLabel("Size")
            ChipRow(ImageSize.entries.map { it.label }, ImageSize.entries.indexOf(uiState.selectedSize)) {
                onSelectSize(ImageSize.entries[it])
            }

            // Model selector
            SectionLabel("Model")
            if (accessibleModels.isEmpty()) {
                Text("Upgrade your plan to generate images.", color = DS.textSecondary, fontSize = 14.sp)
            } else {
                ChipRow(accessibleModels.map { it.displayName }, accessibleModels.indexOfFirst { it.id == uiState.selectedImageModelId }.coerceAtLeast(0)) {
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
                        Text("Generate", fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
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

            // History grid
            val imageHistory = uiState.history.filter { it.generationType == "image" && it.status == "completed" && it.resultUrl != null }
            if (imageHistory.isNotEmpty()) {
                SectionLabel("Recent")
                LazyVerticalGrid(
                    columns = GridCells.Fixed(2),
                    modifier = Modifier.fillMaxWidth().heightIn(max = 400.dp),
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                ) {
                    items(imageHistory.take(10)) { gen ->
                        AsyncImage(
                            model = gen.resultUrl,
                            contentDescription = gen.prompt,
                            modifier = Modifier
                                .aspectRatio(1f)
                                .clip(RoundedCornerShape(12.dp)),
                            contentScale = ContentScale.Crop,
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun GenerationProgress(text: String, onCancel: () -> Unit) {
    val shimmerAnim = rememberInfiniteTransition(label = "shimmer")
    val shimmerOffset by shimmerAnim.animateFloat(
        initialValue = -1f, targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(1500, easing = LinearEasing), RepeatMode.Reverse),
        label = "shimmerOffset",
    )

    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(16.dp)) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp)
                .clip(RoundedCornerShape(16.dp))
                .background(DS.fieldBackground)
                .background(
                    Brush.horizontalGradient(
                        colors = listOf(Color.Transparent, DS.accent.copy(alpha = 0.15f), Color.Transparent),
                        startX = shimmerOffset * 600f,
                        endX = shimmerOffset * 600f + 300f,
                    )
                ),
            contentAlignment = Alignment.Center,
        ) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                CircularProgressIndicator(color = DS.accent, modifier = Modifier.size(24.dp), strokeWidth = 2.dp)
                Text(text, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = DS.textSecondary)
            }
        }
        TextButton(onClick = onCancel) {
            Text("Cancel", color = DS.textSecondary)
        }
    }
}

@Composable
fun GenerationResultCard(resultUrl: String, prompt: String) {
    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        color = DS.cardBackground,
        border = androidx.compose.foundation.BorderStroke(0.5.dp, DS.glassStroke),
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            AsyncImage(
                model = resultUrl,
                contentDescription = prompt,
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp)),
                contentScale = ContentScale.FillWidth,
            )
            Text(prompt, fontSize = 12.sp, color = DS.textSecondary, maxLines = 2)
        }
    }
}

@Composable
fun SectionLabel(text: String) {
    Text(text, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = DS.textSecondary)
}

@Composable
fun ChipRow(labels: List<String>, selectedIndex: Int, onSelect: (Int) -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        labels.forEachIndexed { index, label ->
            val selected = index == selectedIndex
            Surface(
                modifier = Modifier.clickable { onSelect(index) },
                shape = CircleShape,
                color = if (selected) DS.accent.copy(alpha = 0.2f) else DS.fieldBackground,
                border = androidx.compose.foundation.BorderStroke(
                    0.5.dp,
                    if (selected) DS.accent.copy(alpha = 0.5f) else DS.glassStroke,
                ),
            ) {
                Text(
                    label,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    color = if (selected) DS.accent else DS.textPrimary,
                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                )
            }
        }
    }
}
