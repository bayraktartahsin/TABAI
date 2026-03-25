package com.taba.tabai.feature.subscription

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.taba.tabai.core.designsystem.DS
import com.taba.tabai.domain.model.PlanTier

private val marqueeModels = mapOf(
    PlanTier.FREE to listOf("Gemma 3", "Llama 3.3 70B", "Gemma 3 27B", "Mistral Small"),
    PlanTier.STARTER to listOf("GPT-4o Mini", "Claude Haiku 4.5", "Gemini 2.5 Flash", "Llama 3.3 70B", "DeepSeek V3"),
    PlanTier.PRO to listOf("GPT-4.1", "Claude Sonnet 4.5", "Gemini 2.5 Pro", "DeepSeek R1", "O3 Mini", "Mistral Large"),
    PlanTier.POWER to listOf("Claude Opus 4.5", "GPT-5", "O1", "O3", "Grok 4"),
)

private data class Feature(val label: String, val freeHas: Boolean, val paidHas: Boolean)

private fun featuresFor(tier: PlanTier): List<Feature> = when (tier) {
    PlanTier.FREE -> listOf(Feature("8 free AI models", true, true), Feature("Basic daily usage", true, true), Feature("1 concurrent chat", true, true))
    PlanTier.STARTER -> listOf(Feature("Free AI models", true, true), Feature("Access to top AI models", false, true), Feature("Vision models", false, true), Feature("Higher daily usage", false, true), Feature("2 concurrent chats", false, true))
    PlanTier.PRO -> listOf(Feature("Free AI models", true, true), Feature("Access to top AI models", false, true), Feature("Advanced reasoning", false, true), Feature("Image understanding", false, true), Feature("Higher daily usage", false, true), Feature("3 concurrent chats", false, true))
    PlanTier.POWER -> listOf(Feature("Free AI models", true, true), Feature("All AI models unlocked", false, true), Feature("Premium reasoning (O1, O3)", false, true), Feature("Maximum daily usage", false, true), Feature("4 concurrent chats", false, true), Feature("Priority access", false, true))
}

// Prices matching App Store (same worldwide pricing)
private data class TierPricing(val monthlyPrice: String, val yearlyPrice: String, val yearlyMonthly: String, val discount: Int)
private val pricing = mapOf(
    PlanTier.STARTER to TierPricing("$4.99 /mo", "$39.99/yr", "$3.33 /mo", 33),
    PlanTier.PRO to TierPricing("$14.99 /mo", "$119.99/yr", "$9.99 /mo", 33),
    PlanTier.POWER to TierPricing("$29.99 /mo", "$239.99/yr", "$19.99 /mo", 33),
)

// All tiers use the theme accent color
private val tierColor = DS.accent

@Composable
fun SubscriptionScreen(onDismiss: () -> Unit) {
    var selectedTier by remember { mutableStateOf(PlanTier.PRO) }
    var selectedCycle by remember { mutableStateOf("yearly") }
    val tierPricing = pricing[selectedTier]

    Column(
        modifier = Modifier.fillMaxSize()
            .background(Brush.verticalGradient(listOf(Color(0xFF141E28), Color(0xFF0F1721), Color(0xFF0A0F17))))
            .systemBarsPadding()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 20.dp),
    ) {
        // Top bar
        Row(Modifier.fillMaxWidth().padding(top = 8.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onDismiss, Modifier.size(36.dp).clip(CircleShape).background(DS.fieldBackground)) {
                Icon(Icons.Default.Close, "Close", tint = DS.textPrimary, modifier = Modifier.size(14.dp))
            }
            TextButton(onClick = { /* restore */ }) { Text("Restore", fontSize = 13.sp, color = DS.textSecondary) }
        }

        Spacer(Modifier.height(12.dp))

        // Hero
        Text("Get the most\naccurate answers", fontSize = 26.sp, fontWeight = FontWeight.Bold, color = DS.textPrimary, textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
        Spacer(Modifier.height(10.dp))
        ModelMarquee(marqueeModels[selectedTier] ?: emptyList())

        Spacer(Modifier.height(16.dp))

        // Tier picker
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).background(Color(0xFF1A1F2A)).padding(3.dp),
            horizontalArrangement = Arrangement.spacedBy(3.dp),
        ) {
            PlanTier.entries.forEach { tier ->
                val sel = selectedTier == tier
                Surface(
                    Modifier.weight(1f).clickable { selectedTier = tier }, RoundedCornerShape(10.dp),
                    color = if (sel) Color(0xFF2A3040) else Color.Transparent,
                    border = if (sel) ButtonDefaults.outlinedButtonBorder.copy(brush = Brush.linearGradient(listOf(DS.accent.copy(alpha = 0.5f), DS.accent.copy(alpha = 0.5f)))) else null,
                ) {
                    Text(
                        tier.name.lowercase().replaceFirstChar { it.uppercase() },
                        fontSize = 13.sp, fontWeight = FontWeight.SemiBold,
                        color = if (sel) DS.accent else Color.White.copy(alpha = 0.5f),
                        textAlign = TextAlign.Center, modifier = Modifier.padding(vertical = 10.dp),
                    )
                }
            }
        }

        Spacer(Modifier.height(14.dp))

        // Feature comparison table
        Surface(shape = RoundedCornerShape(14.dp), color = DS.cardBackground, border = ButtonDefaults.outlinedButtonBorder.copy(brush = Brush.linearGradient(listOf(DS.cardBorder, DS.cardBorder)))) {
            Column(Modifier.fillMaxWidth()) {
                Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp)) {
                    Text("Features", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = DS.textSecondary, modifier = Modifier.weight(1f))
                    Text("Free", fontSize = 13.sp, fontWeight = FontWeight.Medium, color = DS.textSecondary, modifier = Modifier.width(50.dp), textAlign = TextAlign.Center)
                    Text(selectedTier.name.lowercase().replaceFirstChar { it.uppercase() }, fontSize = 13.sp, fontWeight = FontWeight.Bold, color = DS.accent, modifier = Modifier.width(60.dp), textAlign = TextAlign.Center)
                }
                HorizontalDivider(color = DS.cardBorder)
                featuresFor(selectedTier).forEach { feature ->
                    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
                        Text(feature.label, fontSize = 14.sp, color = DS.textPrimary, modifier = Modifier.weight(1f))
                        Box(Modifier.width(50.dp), contentAlignment = Alignment.Center) {
                            if (feature.freeHas) Icon(Icons.Default.Check, null, tint = DS.accent, modifier = Modifier.size(14.dp))
                            else Text("—", color = DS.textSecondary.copy(alpha = 0.4f), fontSize = 13.sp)
                        }
                        Box(Modifier.width(60.dp), contentAlignment = Alignment.Center) {
                            if (feature.paidHas) Icon(Icons.Default.Check, null, tint = DS.accent, modifier = Modifier.size(14.dp))
                            else Text("—", color = DS.textSecondary.copy(alpha = 0.4f), fontSize = 13.sp)
                        }
                    }
                }
            }
        }

        Spacer(Modifier.height(14.dp))

        // Pricing cards
        if (tierPricing != null) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                PricingCard(
                    title = "Yearly", isSelected = selectedCycle == "yearly",
                    discount = tierPricing.discount,
                    priceMain = tierPricing.yearlyMonthly, priceSub = tierPricing.yearlyPrice,
                    accentColor = DS.accent,
                    onClick = { selectedCycle = "yearly" }, modifier = Modifier.weight(1f),
                )
                PricingCard(
                    title = "Monthly", isSelected = selectedCycle == "monthly",
                    discount = null,
                    priceMain = tierPricing.monthlyPrice, priceSub = "",
                    accentColor = DS.accent,
                    onClick = { selectedCycle = "monthly" }, modifier = Modifier.weight(1f),
                )
            }
            Spacer(Modifier.height(14.dp))

            // CTA
            Button(
                onClick = { /* purchase */ }, Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(26.dp),
                colors = ButtonDefaults.buttonColors(containerColor = DS.accent),
            ) { Text("Get ${selectedTier.name.lowercase().replaceFirstChar { it.uppercase() }}", fontWeight = FontWeight.SemiBold, fontSize = 17.sp, color = Color.Black) }
        }

        Spacer(Modifier.height(10.dp))

        Text(
            "Payment will be charged to your Google Play account. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.",
            fontSize = 10.sp, color = DS.textSecondary.copy(alpha = 0.5f), textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth(),
        )
        Spacer(Modifier.height(24.dp))
    }
}

@Composable
private fun PricingCard(title: String, isSelected: Boolean, discount: Int?, priceMain: String, priceSub: String, accentColor: Color, onClick: () -> Unit, modifier: Modifier) {
    Surface(
        modifier = modifier.clickable(onClick = onClick), shape = RoundedCornerShape(12.dp), color = DS.cardBackground,
        border = ButtonDefaults.outlinedButtonBorder.copy(
            brush = Brush.linearGradient(if (isSelected) listOf(accentColor.copy(alpha = 0.6f), tierColor.copy(alpha = 0.6f)) else listOf(DS.cardBorder, DS.cardBorder)),
            width = if (isSelected) 1.5.dp else 0.5.dp,
        ),
    ) {
        Column(Modifier.padding(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(title, fontSize = 14.sp, fontWeight = FontWeight.SemiBold, color = DS.textPrimary)
                if (discount != null && discount > 0) {
                    Spacer(Modifier.width(6.dp))
                    Surface(shape = RoundedCornerShape(999.dp), color = accentColor) {
                        Text("-$discount%", fontSize = 11.sp, fontWeight = FontWeight.Bold, color = Color.Black,
                            modifier = Modifier.padding(horizontal = 6.dp, vertical = 2.dp))
                    }
                }
                Spacer(Modifier.weight(1f))
                if (isSelected) Icon(Icons.Default.CheckCircle, null, tint = accentColor, modifier = Modifier.size(16.dp))
            }
            Spacer(Modifier.height(6.dp))
            Text(priceMain, fontSize = 18.sp, fontWeight = FontWeight.Bold, color = DS.textPrimary)
            if (priceSub.isNotEmpty()) Text(priceSub, fontSize = 12.sp, color = DS.textSecondary)
        }
    }
}

@Composable
private fun ModelMarquee(models: List<String>) {
    val scrollState = rememberScrollState()
    val transition = rememberInfiniteTransition(label = "marquee")
    val offset by transition.animateFloat(
        initialValue = 0f, targetValue = 1f,
        animationSpec = infiniteRepeatable(tween(models.size * 3500, easing = LinearEasing)), label = "scroll",
    )

    Row(
        modifier = Modifier.fillMaxWidth().horizontalScroll(scrollState)
            .graphicsLayer { translationX = -offset * models.size * 160f },
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        (models + models + models).forEach { name ->
            Surface(
                shape = RoundedCornerShape(999.dp),
                color = DS.accent.copy(alpha = 0.08f),
                border = ButtonDefaults.outlinedButtonBorder.copy(
                    brush = Brush.linearGradient(listOf(DS.accent.copy(alpha = 0.15f), DS.accent.copy(alpha = 0.15f)))
                ),
            ) {
                Text(
                    name, fontSize = 13.sp, fontWeight = FontWeight.Medium,
                    color = Color.White.copy(alpha = 0.9f),
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                )
            }
        }
    }
}
