package com.taba.tabai.feature.auth

import android.content.Intent
import android.net.Uri
import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.taba.tabai.core.config.LegalLinks
import com.taba.tabai.core.designsystem.DS

@Composable
fun SignInScreen(
    onSignedIn: () -> Unit,
    viewModel: SignInViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsState()
    val context = LocalContext.current

    LaunchedEffect(state.signedIn) { if (state.signedIn) onSignedIn() }

    Box(
        modifier = Modifier.fillMaxSize()
            .background(Brush.verticalGradient(listOf(DS.backgroundTop, DS.backgroundBottom)))
            .systemBarsPadding().imePadding(),
    ) {
        Column(
            modifier = Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Spacer(Modifier.weight(1f))

            // Animated logo
            com.taba.tabai.core.designsystem.components.AnimatedBrandLogoSimple(size = 72.dp)
            Spacer(Modifier.height(16.dp))
            com.taba.tabai.core.designsystem.components.AnimatedBrandText(fontSize = 28f)
            Spacer(Modifier.height(8.dp))

            AnimatedContent(targetState = state.showEmailForm, label = "auth") { showEmail ->
                if (!showEmail) {
                    AuthButtons(
                        state = state,
                        onGoogleClick = { /* TODO: Google credential manager */ },
                        onEmailClick = viewModel::showEmailForm,
                        onLegalClick = { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(LegalLinks.TERMS))) },
                    )
                } else {
                    EmailForm(state = state, viewModel = viewModel)
                }
            }

            Spacer(Modifier.weight(1f))
        }
    }
}

@Composable
private fun AuthButtons(state: SignInState, onGoogleClick: () -> Unit, onEmailClick: () -> Unit, onLegalClick: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.widthIn(max = 360.dp)) {
        Text("Create an account for free", fontSize = 15.sp, color = DS.textSecondary, textAlign = TextAlign.Center)
        Spacer(Modifier.height(32.dp))

        // Google
        Surface(
            modifier = Modifier.fillMaxWidth().height(52.dp), shape = RoundedCornerShape(26.dp),
            color = Color.White, onClick = onGoogleClick,
        ) {
            Row(Modifier.padding(horizontal = 20.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
                Text("G", fontSize = 20.sp, fontWeight = FontWeight.Bold, color = Color(0xFF4285F4))
                Spacer(Modifier.width(12.dp))
                Text("Continue with Google", fontSize = 17.sp, fontWeight = FontWeight.Medium, color = Color.Black)
            }
        }

        Spacer(Modifier.height(12.dp))

        // Email
        Surface(
            modifier = Modifier.fillMaxWidth().height(52.dp), shape = RoundedCornerShape(26.dp),
            color = Color.White.copy(alpha = 0.12f), onClick = onEmailClick,
        ) {
            Row(Modifier.padding(horizontal = 20.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
                Icon(Icons.Default.Email, contentDescription = null, tint = DS.textPrimary, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(12.dp))
                Text("Sign in with email", fontSize = 17.sp, fontWeight = FontWeight.Medium, color = DS.textPrimary)
            }
        }

        state.error?.let {
            Spacer(Modifier.height(12.dp))
            Text(it, color = DS.danger, fontSize = 13.sp, textAlign = TextAlign.Center)
        }

        Spacer(Modifier.height(32.dp))
        Text(
            "By continuing, you agree to our Terms of Service and Privacy Policy.",
            fontSize = 11.sp, color = DS.textSecondary.copy(alpha = 0.5f), textAlign = TextAlign.Center,
            modifier = Modifier.clickable(onClick = onLegalClick),
        )
    }
}

@Composable
private fun EmailForm(state: SignInState, viewModel: SignInViewModel) {
    Column(modifier = Modifier.widthIn(max = 400.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(Modifier.fillMaxWidth()) {
            IconButton(onClick = viewModel::hideEmailForm) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Back", tint = DS.textPrimary) }
        }
        Text(if (state.isSignUp) "Create your account" else "Welcome back", fontSize = 22.sp, fontWeight = FontWeight.SemiBold, color = DS.textPrimary)
        Spacer(Modifier.height(4.dp))

        if (state.isSignUp) Field("Username", state.username, viewModel::setUsername)
        Field("Email", state.email, viewModel::setEmail, keyboardType = KeyboardType.Email)
        Field("Password", state.password, viewModel::setPassword, isSecure = true)

        if (state.isSignUp) {
            Field("Confirm Password", state.confirmPassword, viewModel::setConfirmPassword, isSecure = true, imeAction = ImeAction.Done)
            Column(verticalArrangement = Arrangement.spacedBy(4.dp), modifier = Modifier.fillMaxWidth()) {
                Req("8+ characters", state.password.length >= 8)
                Req("Uppercase letter", state.password.any { it.isUpperCase() })
                Req("Lowercase letter", state.password.any { it.isLowerCase() })
                Req("Number", state.password.any { it.isDigit() })
                Req("Special character", state.password.any { "!@#\$%^&*".contains(it) })
            }
        }

        state.error?.let { Text(it, color = DS.danger, fontSize = 13.sp, textAlign = TextAlign.Center) }

        Button(
            onClick = { if (state.isSignUp) viewModel.signUp() else viewModel.signIn() },
            enabled = !state.isLoading && viewModel.isFormValid(),
            modifier = Modifier.fillMaxWidth().height(52.dp), shape = RoundedCornerShape(DS.fieldCornerRadius),
            colors = ButtonDefaults.buttonColors(containerColor = DS.accent, disabledContainerColor = DS.accent.copy(alpha = 0.4f)),
        ) {
            if (state.isLoading) CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp, color = Color.Black)
            else Text(if (state.isSignUp) "Create Account" else "Sign In", fontWeight = FontWeight.SemiBold, fontSize = 17.sp, color = Color.Black.copy(alpha = 0.92f))
        }

        TextButton(onClick = viewModel::toggleMode) {
            Text(if (state.isSignUp) "Already have an account? Sign in" else "Don't have an account? Create one", color = DS.textSecondary, fontSize = 13.sp)
        }
        if (!state.isSignUp) {
            TextButton(onClick = {}) { Text("Forgot password?", color = DS.accent.copy(alpha = 0.8f), fontSize = 13.sp) }
        }
    }
}

@Composable
private fun Field(label: String, value: String, onChange: (String) -> Unit, isSecure: Boolean = false, keyboardType: KeyboardType = KeyboardType.Text, imeAction: ImeAction = ImeAction.Next) {
    Column(Modifier.fillMaxWidth()) {
        Text(label, fontSize = 16.sp, fontWeight = FontWeight.Medium, color = DS.textSecondary, modifier = Modifier.padding(bottom = 6.dp))
        OutlinedTextField(
            value = value, onValueChange = onChange, modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(DS.fieldCornerRadius), singleLine = true,
            visualTransformation = if (isSecure) PasswordVisualTransformation() else VisualTransformation.None,
            keyboardOptions = KeyboardOptions(keyboardType = if (isSecure) KeyboardType.Password else keyboardType, imeAction = imeAction),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = DS.glassStroke, unfocusedBorderColor = DS.glassStroke.copy(alpha = 0.5f),
                focusedContainerColor = DS.fieldBackground, unfocusedContainerColor = DS.fieldBackground, cursorColor = DS.accent,
            ),
        )
    }
}

@Composable
private fun Req(text: String, met: Boolean) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(if (met) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked, null,
            tint = if (met) DS.success else DS.textSecondary.copy(alpha = 0.4f), modifier = Modifier.size(14.dp))
        Text(text, fontSize = 12.sp, color = if (met) DS.textPrimary else DS.textSecondary.copy(alpha = 0.6f))
    }
}
