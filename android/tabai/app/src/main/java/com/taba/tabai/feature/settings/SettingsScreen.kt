package com.taba.tabai.feature.settings

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.taba.tabai.core.config.LegalLinks
import com.taba.tabai.core.designsystem.DS
import com.taba.tabai.domain.model.AIModel
import com.taba.tabai.domain.model.PlanTier
import com.taba.tabai.domain.model.UserProfile

@Composable
fun SettingsScreen(
    user: UserProfile?,
    models: List<AIModel> = emptyList(),
    selectedTheme: String = "Dark",
    selectedLanguage: String = "System default",
    onThemeChange: (String) -> Unit = {},
    onLanguageChange: (String) -> Unit = {},
    onBack: () -> Unit,
    onSignOut: () -> Unit,
    onUpgrade: () -> Unit,
) {
    val context = LocalContext.current
    var showSignOutDialog by remember { mutableStateOf(false) }
    var showPasswordDialog by remember { mutableStateOf(false) }
    var showUsageDialog by remember { mutableStateOf(false) }
    var showThemeDialog by remember { mutableStateOf(false) }
    var showLanguageDialog by remember { mutableStateOf(false) }
    var notificationsOn by remember { mutableStateOf(true) }
    var voiceOn by remember { mutableStateOf(false) }
    var hapticsOn by remember { mutableStateOf(true) }
    var biometricOn by remember { mutableStateOf(false) }

    val accessibleModels = models.count { it.canAccess }
    val totalModels = models.size
    val modelsByTier = PlanTier.entries.associateWith { tier -> models.count { it.tierEnum == tier } }

    Column(
        modifier = Modifier.fillMaxSize()
            .background(Brush.verticalGradient(listOf(DS.backgroundTop, DS.backgroundBottom)))
            .systemBarsPadding()
    ) {
        // Header
        Row(Modifier.fillMaxWidth().padding(horizontal = 8.dp, vertical = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            IconButton(onClick = onBack) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back", tint = DS.textPrimary) }
            Spacer(Modifier.width(4.dp))
            com.taba.tabai.core.designsystem.components.BrandLogoMark(size = 24.dp)
            Spacer(Modifier.width(8.dp))
            Text("Settings", fontWeight = FontWeight.Bold, fontSize = 22.sp, color = DS.textPrimary)
        }

        Column(
            Modifier.fillMaxWidth().verticalScroll(rememberScrollState()).padding(horizontal = DS.horizontalPadding),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Spacer(Modifier.height(8.dp))

            // Profile card
            Surface(shape = RoundedCornerShape(DS.fieldCornerRadius), color = DS.cardBackground) {
                Row(Modifier.fillMaxWidth().padding(16.dp), verticalAlignment = Alignment.CenterVertically) {
                    Box(Modifier.size(48.dp).clip(CircleShape).background(Brush.linearGradient(listOf(DS.avatarGradientStart, DS.avatarGradientEnd))), contentAlignment = Alignment.Center) {
                        Text((user?.displayName ?: user?.username ?: "?").take(1).uppercase(), fontSize = 20.sp, fontWeight = FontWeight.SemiBold, color = Color.White)
                    }
                    Spacer(Modifier.width(14.dp))
                    Column(Modifier.weight(1f)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Text(user?.displayName ?: user?.username ?: "—", fontWeight = FontWeight.SemiBold, fontSize = 16.sp, color = DS.textPrimary)
                            Spacer(Modifier.width(8.dp))
                            Surface(shape = RoundedCornerShape(999.dp), color = DS.accent.copy(alpha = 0.1f)) {
                                Text((user?.effectivePlanTier?.name ?: "FREE").uppercase(), fontSize = 12.sp, fontWeight = FontWeight.SemiBold, color = DS.accent,
                                    modifier = Modifier.padding(horizontal = 8.dp, vertical = 3.dp))
                            }
                        }
                        Text(user?.email ?: "", fontSize = 13.sp, color = DS.textSecondary)
                    }
                }
            }

            // Quick Actions
            SectionHeader("Quick Actions")
            SettingsCard {
                SettingsRow(Icons.Default.CreditCard, "Subscription", (user?.effectivePlanTier?.name ?: "Free").uppercase(), onClick = onUpgrade)
                Div()
                SettingsRow(Icons.Default.BarChart, "Usage", "$accessibleModels of $totalModels models", onClick = { showUsageDialog = true })
                Div()
                SettingsRow(Icons.Default.Key, "Change Password", onClick = { showPasswordDialog = true })
            }

            // Preferences
            SectionHeader("Preferences")
            SettingsCard {
                SettingsRow(Icons.Default.DarkMode, "Theme", selectedTheme, onClick = { showThemeDialog = true })
                Div()
                SettingsRow(Icons.Default.Language, "Language", selectedLanguage, onClick = { showLanguageDialog = true })
                Div()
                SettingsToggle(Icons.Default.Notifications, "Notifications", notificationsOn) { notificationsOn = it }
                Div()
                SettingsToggle(Icons.Default.Mic, "Voice Input", voiceOn) { voiceOn = it }
                Div()
                SettingsToggle(Icons.Default.Vibration, "Haptics", hapticsOn) { hapticsOn = it }
                Div()
                SettingsToggle(Icons.Default.Fingerprint, "Biometrics", biometricOn) { biometricOn = it }
            }

            // Legal
            SectionHeader("About & Legal")
            SettingsCard {
                SettingsRow(Icons.Default.Shield, "Privacy Policy", onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(LegalLinks.PRIVACY))) })
                Div()
                SettingsRow(Icons.Default.Description, "Terms of Service", onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(LegalLinks.TERMS))) })
                Div()
                SettingsRow(Icons.Default.VerifiedUser, "Acceptable Use", onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(LegalLinks.ACCEPTABLE_USE))) })
                Div()
                SettingsRow(Icons.Default.CreditCard, "Subscription Terms", onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(LegalLinks.SUBSCRIPTION))) })
                Div()
                SettingsRow(Icons.Default.HelpOutline, "Support", onClick = { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(LegalLinks.SUPPORT))) })
            }

            // Sign out
            Spacer(Modifier.height(12.dp))
            Surface(Modifier.fillMaxWidth().clickable { showSignOutDialog = true }, RoundedCornerShape(12.dp), DS.danger.copy(alpha = 0.06f)) {
                Text("Sign Out", color = DS.danger.copy(alpha = 0.8f), fontWeight = FontWeight.SemiBold, fontSize = 15.sp,
                    textAlign = TextAlign.Center, modifier = Modifier.padding(vertical = 14.dp).fillMaxWidth())
            }

            Spacer(Modifier.height(16.dp))
            Text("TABAI v1.0.1", fontSize = 11.sp, color = DS.textSecondary.copy(alpha = 0.4f), textAlign = TextAlign.Center, modifier = Modifier.fillMaxWidth())
            Spacer(Modifier.height(32.dp))
        }
    }

    // ── Dialogs ──

    if (showSignOutDialog) {
        AlertDialog(onDismissRequest = { showSignOutDialog = false },
            title = { Text("Sign Out") }, text = { Text("Are you sure you want to sign out?") },
            confirmButton = { TextButton(onClick = { showSignOutDialog = false; onSignOut() }) { Text("Sign Out", color = DS.danger) } },
            dismissButton = { TextButton(onClick = { showSignOutDialog = false }) { Text("Cancel") } })
    }

    if (showThemeDialog) {
        SelectionDialog(title = "Theme", options = listOf("Dark", "Light", "System"), selected = selectedTheme,
            onSelect = { onThemeChange(it); showThemeDialog = false }, onDismiss = { showThemeDialog = false })
    }

    if (showLanguageDialog) {
        SelectionDialog(title = "Language",
            options = listOf("System default", "English", "Turkce", "Francais", "Deutsch", "Espanol", "Italiano", "Portugues", "Russian", "Japanese", "Korean", "Chinese", "Hindi", "Arabic", "Thai", "Ukrainian"),
            selected = selectedLanguage,
            onSelect = { onLanguageChange(it); showLanguageDialog = false }, onDismiss = { showLanguageDialog = false })
    }

    if (showPasswordDialog) {
        PasswordDialog(onDismiss = { showPasswordDialog = false })
    }

    if (showUsageDialog) {
        UsageDialog(models = models, accessibleModels = accessibleModels, totalModels = totalModels, modelsByTier = modelsByTier, onDismiss = { showUsageDialog = false })
    }
}

// ── Dialogs ──

@Composable
private fun SelectionDialog(title: String, options: List<String>, selected: String, onSelect: (String) -> Unit, onDismiss: () -> Unit) {
    AlertDialog(onDismissRequest = onDismiss, title = { Text(title) },
        text = {
            Column {
                options.forEach { option ->
                    Row(
                        Modifier.fillMaxWidth().clickable { onSelect(option) }.padding(vertical = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(option, fontSize = 15.sp, color = DS.textPrimary, modifier = Modifier.weight(1f))
                        if (selected == option) Icon(Icons.Default.Check, null, tint = DS.accent, modifier = Modifier.size(18.dp))
                    }
                }
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Done") } })
}

@Composable
private fun PasswordDialog(onDismiss: () -> Unit) {
    var currentPassword by remember { mutableStateOf("") }
    var newPassword by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }

    AlertDialog(onDismissRequest = onDismiss, title = { Text("Change Password") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                OutlinedTextField(value = currentPassword, onValueChange = { currentPassword = it; error = null },
                    label = { Text("Current Password") }, singleLine = true, visualTransformation = PasswordVisualTransformation(),
                    modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
                OutlinedTextField(value = newPassword, onValueChange = { newPassword = it; error = null },
                    label = { Text("New Password") }, singleLine = true, visualTransformation = PasswordVisualTransformation(),
                    modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
                OutlinedTextField(value = confirmPassword, onValueChange = { confirmPassword = it; error = null },
                    label = { Text("Confirm New Password") }, singleLine = true, visualTransformation = PasswordVisualTransformation(),
                    modifier = Modifier.fillMaxWidth(), shape = RoundedCornerShape(12.dp))
                error?.let { Text(it, color = DS.danger, fontSize = 13.sp) }
            }
        },
        confirmButton = {
            TextButton(onClick = {
                when {
                    currentPassword.isBlank() -> error = "Enter current password"
                    newPassword.length < 8 -> error = "New password must be at least 8 characters"
                    newPassword != confirmPassword -> error = "Passwords do not match"
                    else -> {
                        // TODO: call backend PATCH /api/auth/me with password
                        onDismiss()
                    }
                }
            }) { Text("Update", color = DS.accent) }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } })
}

@Composable
private fun UsageDialog(models: List<AIModel>, accessibleModels: Int, totalModels: Int, modelsByTier: Map<PlanTier, Int>, onDismiss: () -> Unit) {
    AlertDialog(onDismissRequest = onDismiss, title = { Text("Usage") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                // Access summary
                Text("$accessibleModels of $totalModels models accessible", fontSize = 15.sp, color = DS.textPrimary)

                // Tier breakdown
                PlanTier.entries.forEach { tier ->
                    val count = modelsByTier[tier] ?: 0
                    val accessible = models.count { it.tierEnum == tier && it.canAccess }
                    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                        Text(tier.name.lowercase().replaceFirstChar { it.uppercase() }, fontSize = 14.sp, fontWeight = FontWeight.Medium, color = DS.textPrimary, modifier = Modifier.weight(1f))
                        Text("$accessible / $count", fontSize = 14.sp, color = if (accessible == count) DS.accent else DS.textSecondary)
                    }
                    // Progress bar
                    LinearProgressIndicator(
                        progress = { if (count > 0) accessible.toFloat() / count else 0f },
                        modifier = Modifier.fillMaxWidth().height(4.dp).clip(RoundedCornerShape(2.dp)),
                        color = DS.accent, trackColor = DS.fieldBackground,
                    )
                }

                Spacer(Modifier.height(4.dp))
                Text("Upgrade your plan to unlock more models", fontSize = 12.sp, color = DS.textSecondary)
            }
        },
        confirmButton = { TextButton(onClick = onDismiss) { Text("Done") } })
}

// ── Components ──

@Composable private fun SectionHeader(title: String) {
    Text(title, fontSize = 13.sp, fontWeight = FontWeight.Medium, color = DS.textSecondary.copy(alpha = 0.6f), modifier = Modifier.padding(top = 20.dp, bottom = 6.dp))
}

@Composable private fun SettingsCard(content: @Composable ColumnScope.() -> Unit) {
    Surface(shape = RoundedCornerShape(DS.fieldCornerRadius), color = DS.cardBackground,
        border = ButtonDefaults.outlinedButtonBorder.copy(brush = Brush.linearGradient(listOf(DS.cardBorder, DS.cardBorder)))) {
        Column(Modifier.fillMaxWidth(), content = content)
    }
}

@Composable private fun SettingsRow(icon: ImageVector, label: String, sublabel: String? = null, onClick: (() -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth().then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier).padding(horizontal = 16.dp, vertical = 13.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Icon(icon, null, tint = DS.textSecondary, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(14.dp))
        Text(label, fontSize = 15.sp, color = DS.textPrimary, modifier = Modifier.weight(1f))
        sublabel?.let { Text(it, fontSize = 13.sp, color = DS.textSecondary); Spacer(Modifier.width(4.dp)) }
        if (onClick != null) Icon(Icons.Default.ChevronRight, null, tint = DS.textSecondary.copy(alpha = 0.4f), modifier = Modifier.size(16.dp))
    }
}

@Composable private fun SettingsToggle(icon: ImageVector, label: String, checked: Boolean, onCheckedChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, null, tint = DS.textSecondary, modifier = Modifier.size(20.dp))
        Spacer(Modifier.width(14.dp))
        Text(label, fontSize = 15.sp, color = DS.textPrimary, modifier = Modifier.weight(1f))
        Switch(checked, onCheckedChange, colors = SwitchDefaults.colors(checkedTrackColor = DS.accent, checkedThumbColor = Color.White), modifier = Modifier.height(24.dp))
    }
}

@Composable private fun Div() { HorizontalDivider(color = DS.cardBorder, modifier = Modifier.padding(start = 50.dp)) }
