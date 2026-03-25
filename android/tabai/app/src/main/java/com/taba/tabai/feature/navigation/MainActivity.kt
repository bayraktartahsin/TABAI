package com.taba.tabai.feature.navigation

import android.os.Bundle
import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.os.LocaleListCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.taba.tabai.core.designsystem.DS
import com.taba.tabai.core.designsystem.TABAITheme
import com.taba.tabai.data.repository.AuthRepository
import com.taba.tabai.data.repository.BootstrapRepository
import com.taba.tabai.data.repository.ChatRepository
import com.taba.tabai.domain.model.AIModel
import com.taba.tabai.domain.model.ChatThread
import com.taba.tabai.domain.model.UserProfile
import com.taba.tabai.feature.auth.SignInScreen
import com.taba.tabai.feature.chat.ChatScreen
import com.taba.tabai.feature.chat.ChatViewModel
import com.taba.tabai.feature.settings.SettingsScreen
import com.taba.tabai.feature.subscription.SubscriptionScreen
import dagger.hilt.android.AndroidEntryPoint
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            TABAITheme {
                Surface(modifier = Modifier.fillMaxSize()) {
                    AppRoot()
                }
            }
        }
    }
}

// ── App-level state ──

data class AppState(
    val isAuthenticated: Boolean = false,
    val isCheckingAuth: Boolean = true,
    val user: UserProfile? = null,
    val models: List<AIModel> = emptyList(),
    val threads: List<ChatThread> = emptyList(),
    val selectedModelId: String? = null,
    val selectedThreadId: String? = null,
    val currentScreen: Screen = Screen.CHAT,
    val selectedTheme: String = "Dark",
    val selectedLanguage: String = "System default",
) {
    enum class Screen { CHAT, SETTINGS, SUBSCRIPTION }
}

// Language code mapping
val languageMap = mapOf(
    "System default" to "",
    "English" to "en",
    "Turkce" to "tr",
    "Francais" to "fr",
    "Deutsch" to "de",
    "Espanol" to "es",
    "Italiano" to "it",
    "Portugues" to "pt",
    "Russian" to "ru",
    "Japanese" to "ja",
    "Korean" to "ko",
    "Chinese" to "zh",
    "Hindi" to "hi",
    "Arabic" to "ar",
    "Thai" to "th",
    "Ukrainian" to "uk",
)

@HiltViewModel
class AppViewModel @Inject constructor(
    private val authRepository: AuthRepository,
    private val bootstrapRepository: BootstrapRepository,
    private val chatRepository: ChatRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(AppState())
    val state: StateFlow<AppState> = _state

    init { checkAuth() }

    private fun checkAuth() {
        viewModelScope.launch {
            _state.update { it.copy(isCheckingAuth = true) }
            authRepository.me()
                .onSuccess { user ->
                    _state.update { it.copy(isAuthenticated = true, user = user, isCheckingAuth = false) }
                    loadBootstrap()
                }
                .onFailure { _state.update { it.copy(isAuthenticated = false, isCheckingAuth = false) } }
        }
    }

    fun onSignedIn() {
        viewModelScope.launch {
            _state.update { it.copy(isAuthenticated = true) }
            loadBootstrap()
        }
    }

    private suspend fun loadBootstrap() {
        bootstrapRepository.fetch().onSuccess { bootstrap ->
            val firstAccessible = bootstrap.models.firstOrNull { it.canAccess }
            _state.update {
                it.copy(
                    user = bootstrap.user,
                    models = bootstrap.models,
                    threads = bootstrap.chats,
                    selectedModelId = it.selectedModelId ?: firstAccessible?.id ?: bootstrap.models.firstOrNull()?.id,
                )
            }
        }
    }

    fun selectModel(modelId: String) = _state.update { it.copy(selectedModelId = modelId, selectedThreadId = null) }
    fun selectThread(threadId: String?) = _state.update { it.copy(selectedThreadId = threadId) }
    fun navigate(screen: AppState.Screen) = _state.update { it.copy(currentScreen = screen) }
    fun setTheme(theme: String) = _state.update { it.copy(selectedTheme = theme) }
    fun setLanguage(lang: String) = _state.update { it.copy(selectedLanguage = lang) }

    fun signOut() {
        viewModelScope.launch {
            authRepository.signOut()
            _state.update { AppState(isCheckingAuth = false) }
        }
    }

    fun refreshThreads() {
        viewModelScope.launch {
            val threads = chatRepository.fetchChats()
            _state.update { it.copy(threads = threads) }
        }
    }

    fun newChat() = _state.update { it.copy(selectedThreadId = null, currentScreen = AppState.Screen.CHAT) }
}

// ── Root ──

@Composable
fun AppRoot(appViewModel: AppViewModel = hiltViewModel()) {
    val appState by appViewModel.state.collectAsState()
    val context = LocalContext.current

    // Apply theme
    LaunchedEffect(appState.selectedTheme) {
        val mode = when (appState.selectedTheme) {
            "Light" -> AppCompatDelegate.MODE_NIGHT_NO
            "Dark" -> AppCompatDelegate.MODE_NIGHT_YES
            else -> AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM
        }
        AppCompatDelegate.setDefaultNightMode(mode)
    }

    // Apply language
    LaunchedEffect(appState.selectedLanguage) {
        val langCode = languageMap[appState.selectedLanguage] ?: ""
        if (langCode.isEmpty()) {
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.getEmptyLocaleList())
        } else {
            AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(langCode))
        }
    }

    when {
        appState.isCheckingAuth -> {
            Box(
                modifier = Modifier.fillMaxSize().background(Brush.verticalGradient(listOf(DS.backgroundTop, DS.backgroundBottom))),
                contentAlignment = Alignment.Center,
            ) {
                com.taba.tabai.core.designsystem.components.AnimatedBrandLogoSimple(size = 72.dp)
            }
        }
        !appState.isAuthenticated -> {
            SignInScreen(onSignedIn = appViewModel::onSignedIn)
        }
        else -> {
            MainShell(appViewModel = appViewModel, appState = appState)
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainShell(appViewModel: AppViewModel, appState: AppState) {
    val drawerState = rememberDrawerState(DrawerValue.Closed)
    val scope = rememberCoroutineScope()
    val chatViewModel: ChatViewModel = hiltViewModel()
    val context = LocalContext.current
    var backPressedOnce by remember { mutableStateOf(false) }

    // Back button handling — Android standard
    BackHandler {
        when {
            // Close drawer first
            drawerState.isOpen -> scope.launch { drawerState.close() }
            // Navigate back to chat from other screens
            appState.currentScreen != AppState.Screen.CHAT -> appViewModel.navigate(AppState.Screen.CHAT)
            // Double-tap to exit from chat screen
            else -> {
                if (backPressedOnce) {
                    (context as? AppCompatActivity)?.finish()
                } else {
                    backPressedOnce = true
                    Toast.makeText(context, "Press back again to exit", Toast.LENGTH_SHORT).show()
                    // Reset after 2 seconds
                    scope.launch {
                        kotlinx.coroutines.delay(2000)
                        backPressedOnce = false
                    }
                }
            }
        }
    }

    // Keep chat VM in sync
    LaunchedEffect(appState.selectedModelId) {
        chatViewModel.selectedModelId = appState.selectedModelId
        chatViewModel.isAuthenticated = appState.isAuthenticated
    }

    LaunchedEffect(appState.selectedThreadId) {
        val threadId = appState.selectedThreadId
        if (threadId != null) chatViewModel.loadChat(threadId)
        else chatViewModel.beginNewChat()
    }

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet(drawerContainerColor = DS.backgroundTop, modifier = Modifier.width(300.dp)) {
                DrawerContent(
                    user = appState.user,
                    threads = appState.threads,
                    selectedThreadId = appState.selectedThreadId,
                    onThreadSelected = { threadId ->
                        appViewModel.selectThread(threadId)
                        appViewModel.navigate(AppState.Screen.CHAT)
                        scope.launch { drawerState.close() }
                    },
                    onNewChat = {
                        appViewModel.newChat()
                        chatViewModel.beginNewChat()
                        scope.launch { drawerState.close() }
                    },
                    onSettings = {
                        appViewModel.navigate(AppState.Screen.SETTINGS)
                        scope.launch { drawerState.close() }
                    },
                    onUpgrade = {
                        appViewModel.navigate(AppState.Screen.SUBSCRIPTION)
                        scope.launch { drawerState.close() }
                    },
                )
            }
        },
    ) {
        when (appState.currentScreen) {
            AppState.Screen.CHAT -> {
                val chatState by chatViewModel.state.collectAsState()
                ChatScreen(
                    state = chatState,
                    models = appState.models,
                    selectedModelId = appState.selectedModelId,
                    planTier = appState.user?.effectivePlanTier ?: com.taba.tabai.domain.model.PlanTier.FREE,
                    onSend = { text ->
                        chatViewModel.send(text)
                        appViewModel.refreshThreads()
                    },
                    onStop = chatViewModel::stopStreaming,
                    onRegenerate = chatViewModel::regenerate,
                    onModelSelected = { modelId ->
                        appViewModel.selectModel(modelId)
                        chatViewModel.beginNewChat()
                    },
                    onMenuClick = { scope.launch { drawerState.open() } },
                    onNewChat = {
                        appViewModel.newChat()
                        chatViewModel.beginNewChat()
                    },
                )
            }
            AppState.Screen.SETTINGS -> {
                SettingsScreen(
                    user = appState.user,
                    models = appState.models,
                    selectedTheme = appState.selectedTheme,
                    selectedLanguage = appState.selectedLanguage,
                    onThemeChange = appViewModel::setTheme,
                    onLanguageChange = appViewModel::setLanguage,
                    onBack = { appViewModel.navigate(AppState.Screen.CHAT) },
                    onSignOut = appViewModel::signOut,
                    onUpgrade = { appViewModel.navigate(AppState.Screen.SUBSCRIPTION) },
                )
            }
            AppState.Screen.SUBSCRIPTION -> {
                SubscriptionScreen(onDismiss = { appViewModel.navigate(AppState.Screen.CHAT) })
            }
        }
    }
}

// ── Drawer ──

@Composable
private fun DrawerContent(
    user: UserProfile?,
    threads: List<ChatThread>,
    selectedThreadId: String?,
    onThreadSelected: (String) -> Unit,
    onNewChat: () -> Unit,
    onSettings: () -> Unit,
    onUpgrade: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxHeight().padding(16.dp)) {
        com.taba.tabai.core.designsystem.components.AnimatedBrandText(fontSize = 22f)
        Spacer(Modifier.height(4.dp))
        Text(user?.email ?: "", fontSize = 12.sp, color = DS.textSecondary)

        Spacer(Modifier.height(16.dp))

        Surface(
            modifier = Modifier.fillMaxWidth().clickable(onClick = onNewChat),
            shape = RoundedCornerShape(12.dp), color = DS.accent.copy(alpha = 0.1f),
        ) {
            Row(modifier = Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Add, null, tint = DS.accent, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text("New Chat", fontWeight = FontWeight.SemiBold, fontSize = 14.sp, color = DS.accent)
            }
        }

        Spacer(Modifier.height(12.dp))

        LazyColumn(modifier = Modifier.weight(1f)) {
            items(threads.filter { !it.isDeleted }.take(50), key = { it.id }) { thread ->
                val isSelected = selectedThreadId == thread.id
                Surface(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 2.dp).clickable { onThreadSelected(thread.id) },
                    shape = RoundedCornerShape(10.dp),
                    color = if (isSelected) DS.accent.copy(alpha = 0.08f) else Color.Transparent,
                ) {
                    Text(thread.title, fontSize = 13.sp, color = DS.textPrimary, maxLines = 1,
                        modifier = Modifier.padding(horizontal = 12.dp, vertical = 10.dp))
                }
            }
        }

        HorizontalDivider(color = DS.cardBorder, modifier = Modifier.padding(vertical = 8.dp))
        Row(Modifier.fillMaxWidth().clickable(onClick = onUpgrade).padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Star, null, tint = DS.accent, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(10.dp))
            Text("Upgrade Plan", fontSize = 14.sp, color = DS.textPrimary)
        }
        Row(Modifier.fillMaxWidth().clickable(onClick = onSettings).padding(vertical = 10.dp), verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Settings, null, tint = DS.textSecondary, modifier = Modifier.size(18.dp))
            Spacer(Modifier.width(10.dp))
            Text("Settings", fontSize = 14.sp, color = DS.textPrimary)
        }
    }
}
