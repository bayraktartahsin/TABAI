package com.taba.tabai.feature.chat.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.taba.tabai.core.designsystem.DS
import com.taba.tabai.domain.model.AIModel
import com.taba.tabai.domain.model.PlanTier

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ModelPickerSheet(
    models: List<AIModel>,
    selectedModelId: String?,
    onSelect: (String) -> Unit,
    onDismiss: () -> Unit,
) {
    var query by remember { mutableStateOf("") }
    val tiers = listOf(PlanTier.FREE, PlanTier.STARTER, PlanTier.PRO, PlanTier.POWER)

    val filtered = remember(models, query) {
        val q = query.trim().lowercase()
        if (q.isEmpty()) models
        else models.filter {
            (it.displayName ?: "").lowercase().contains(q) ||
            (it.vendor ?: "").lowercase().contains(q) ||
            (it.providerModelId ?: "").lowercase().contains(q)
        }
    }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = DS.backgroundTop,
        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp),
    ) {
        Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp)) {
            Text("Choose Model", fontWeight = FontWeight.SemiBold, fontSize = 18.sp, color = DS.textPrimary)
            Spacer(Modifier.height(12.dp))

            OutlinedTextField(
                value = query, onValueChange = { query = it },
                placeholder = { Text("Search models...", color = DS.textSecondary.copy(alpha = 0.5f)) },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp), singleLine = true,
            )
            Spacer(Modifier.height(12.dp))

            LazyColumn(
                modifier = Modifier.heightIn(max = 500.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                tiers.forEach { tier ->
                    val tierModels = filtered.filter { it.tierEnum == tier }.sortedBy { it.displayName ?: it.id }
                    if (tierModels.isNotEmpty()) {
                        item(key = "header_$tier") {
                            Text(
                                tier.name, fontSize = 12.sp, fontWeight = FontWeight.SemiBold,
                                color = DS.textSecondary.copy(alpha = 0.6f),
                                modifier = Modifier.padding(top = 8.dp, bottom = 4.dp),
                            )
                        }
                        items(tierModels, key = { it.id }) { model ->
                            val isSelected = selectedModelId == model.id
                            val isLocked = !model.canAccess
                            Surface(
                                modifier = Modifier.fillMaxWidth().clickable { if (!isLocked) onSelect(model.id) },
                                shape = RoundedCornerShape(12.dp),
                                color = if (isSelected) DS.accent.copy(alpha = 0.08f) else DS.cardBackground,
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    Column(modifier = Modifier.weight(1f)) {
                                        Text(
                                            model.displayName ?: model.id,
                                            fontSize = 15.sp,
                                            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal,
                                            color = if (isLocked) DS.textSecondary.copy(alpha = 0.5f) else DS.textPrimary,
                                        )
                                        model.vendor?.let {
                                            Text(it, fontSize = 12.sp, color = DS.textSecondary.copy(alpha = 0.5f))
                                        }
                                    }
                                    if (isSelected) {
                                        Icon(Icons.Default.Check, contentDescription = null, tint = DS.accent, modifier = Modifier.size(18.dp))
                                    } else if (isLocked) {
                                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                            Icon(Icons.Default.Lock, contentDescription = null, tint = DS.textSecondary.copy(alpha = 0.4f), modifier = Modifier.size(12.dp))
                                            Text(tier.name, fontSize = 11.sp, color = DS.textSecondary.copy(alpha = 0.4f))
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Spacer(Modifier.height(24.dp))
        }
    }
}
