package com.taba.tabai.data.local

import android.content.Context
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore(name = "tai_prefs")

class DataStoreManager(private val context: Context) {
    companion object {
        val KEY_THEME = stringPreferencesKey("theme")
        val KEY_LANGUAGE = stringPreferencesKey("language")
        val KEY_BIOMETRIC_ENABLED = booleanPreferencesKey("biometric_enabled")
        val KEY_HAPTICS_ENABLED = booleanPreferencesKey("haptics_enabled")
        val KEY_VOICE_ENABLED = booleanPreferencesKey("voice_enabled")
        val KEY_CACHED_MODELS_JSON = stringPreferencesKey("cached_models")
        val KEY_AUTH_TOKEN = stringPreferencesKey("auth_token")
    }

    val theme: Flow<String> = context.dataStore.data.map { it[KEY_THEME] ?: "system" }
    val biometricEnabled: Flow<Boolean> = context.dataStore.data.map { it[KEY_BIOMETRIC_ENABLED] ?: false }
    val hapticsEnabled: Flow<Boolean> = context.dataStore.data.map { it[KEY_HAPTICS_ENABLED] ?: true }
    val authToken: Flow<String?> = context.dataStore.data.map { it[KEY_AUTH_TOKEN] }

    suspend fun setTheme(value: String) = context.dataStore.edit { it[KEY_THEME] = value }
    suspend fun setBiometric(value: Boolean) = context.dataStore.edit { it[KEY_BIOMETRIC_ENABLED] = value }
    suspend fun setHaptics(value: Boolean) = context.dataStore.edit { it[KEY_HAPTICS_ENABLED] = value }
    suspend fun setAuthToken(value: String?) = context.dataStore.edit {
        if (value != null) it[KEY_AUTH_TOKEN] = value else it.remove(KEY_AUTH_TOKEN)
    }
    suspend fun setCachedModels(json: String) = context.dataStore.edit { it[KEY_CACHED_MODELS_JSON] = json }
    suspend fun clear() = context.dataStore.edit { it.clear() }
}
