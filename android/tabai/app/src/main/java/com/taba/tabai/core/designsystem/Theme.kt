package com.taba.tabai.core.designsystem

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

object DS {
    // Colors matching iOS DS.swift exactly
    val accent = Color(0xFF59CCB3) // RGB(0.35, 0.80, 0.70)
    val backgroundTop = Color(0xFF141A24)    // RGB(0.08, 0.10, 0.14)
    val backgroundBottom = Color(0xFF080A12)  // RGB(0.03, 0.04, 0.07)
    val textPrimary = Color(0xFFF5F5F5)
    val textSecondary = Color(0xFF8E8E93)
    val danger = Color(0xFFFF3B30)
    val success = Color(0xFF34C759)

    // Card & field
    val cardBackground = Color(0xFF1C2333)    // RGB(0.11, 0.14, 0.20) * 0.78
    val fieldBackground = Color.White.copy(alpha = 0.06f)
    val glassStroke = Color.White.copy(alpha = 0.14f)
    val cardBorder = Color.White.copy(alpha = 0.08f)

    // Layout (matching iOS)
    val cornerRadius = 24.dp
    val fieldCornerRadius = 14.dp
    val horizontalPadding = 24.dp
    val verticalSpacing = 16.dp
    val cardPadding = 24.dp

    // Avatar gradient
    val avatarGradientStart = Color(0xFF4D73FF) // (0.30, 0.45, 1.0)
    val avatarGradientEnd = Color(0xFFA659E6)   // (0.65, 0.35, 0.90)

    // Marquee / brand gradient stops
    val gradientBlue = Color(0xFF3366FF)
    val gradientIndigo = Color(0xFF7340F2)
    val gradientPurple = Color(0xFFB333BF)
    val gradientPink = Color(0xFFE66680)
    val gradientOrange = Color(0xFFF29940)
    val gradientGold = Color(0xFFF2CC4D)
}

private val DarkColorScheme = darkColorScheme(
    primary = DS.accent,
    onPrimary = Color.Black,
    surface = DS.backgroundTop,
    onSurface = DS.textPrimary,
    surfaceVariant = DS.cardBackground,
    onSurfaceVariant = DS.textSecondary,
    outline = DS.cardBorder,
    error = DS.danger,
    background = DS.backgroundBottom,
    onBackground = DS.textPrimary,
)

val TABAITypography = Typography(
    headlineLarge = TextStyle(fontSize = 34.sp, fontWeight = FontWeight.SemiBold, letterSpacing = (-0.5).sp),
    headlineMedium = TextStyle(fontSize = 28.sp, fontWeight = FontWeight.Bold, letterSpacing = (-0.3).sp),
    headlineSmall = TextStyle(fontSize = 22.sp, fontWeight = FontWeight.SemiBold),
    titleLarge = TextStyle(fontSize = 20.sp, fontWeight = FontWeight.SemiBold),
    titleMedium = TextStyle(fontSize = 17.sp, fontWeight = FontWeight.SemiBold),
    titleSmall = TextStyle(fontSize = 16.sp, fontWeight = FontWeight.Medium),
    bodyLarge = TextStyle(fontSize = 15.sp, fontWeight = FontWeight.Normal),
    bodyMedium = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.Normal),
    bodySmall = TextStyle(fontSize = 13.sp, fontWeight = FontWeight.Normal),
    labelLarge = TextStyle(fontSize = 14.sp, fontWeight = FontWeight.SemiBold),
    labelMedium = TextStyle(fontSize = 12.sp, fontWeight = FontWeight.Medium),
    labelSmall = TextStyle(fontSize = 11.sp, fontWeight = FontWeight.Medium),
)

@Composable
fun TABAITheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = TABAITypography,
        content = content,
    )
}
