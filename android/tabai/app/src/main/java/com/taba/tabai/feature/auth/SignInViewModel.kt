package com.taba.tabai.feature.auth

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.taba.tabai.data.repository.AuthRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SignInState(
    val email: String = "",
    val username: String = "",
    val password: String = "",
    val confirmPassword: String = "",
    val isSignUp: Boolean = false,
    val showEmailForm: Boolean = false,
    val isLoading: Boolean = false,
    val error: String? = null,
    val signedIn: Boolean = false,
)

@HiltViewModel
class SignInViewModel @Inject constructor(
    private val authRepository: AuthRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(SignInState())
    val state: StateFlow<SignInState> = _state

    fun setEmail(v: String) = _state.update { it.copy(email = v, error = null) }
    fun setUsername(v: String) = _state.update { it.copy(username = v, error = null) }
    fun setPassword(v: String) = _state.update { it.copy(password = v, error = null) }
    fun setConfirmPassword(v: String) = _state.update { it.copy(confirmPassword = v, error = null) }
    fun toggleMode() = _state.update { it.copy(isSignUp = !it.isSignUp, error = null, password = "", confirmPassword = "") }
    fun showEmailForm() = _state.update { it.copy(showEmailForm = true, error = null) }
    fun hideEmailForm() = _state.update { it.copy(showEmailForm = false, error = null) }

    fun isFormValid(): Boolean {
        val s = _state.value
        if (s.email.isBlank() || s.password.isBlank()) return false
        if (s.isSignUp) {
            if (s.username.isBlank()) return false
            if (s.password != s.confirmPassword) return false
            if (s.password.length < 8) return false
            if (!s.password.any { it.isUpperCase() }) return false
            if (!s.password.any { it.isLowerCase() }) return false
            if (!s.password.any { it.isDigit() }) return false
            if (!s.password.any { "!@#\$%^&*".contains(it) }) return false
        }
        return true
    }

    fun signIn() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            authRepository.signIn(_state.value.email, _state.value.password)
                .onSuccess { _state.update { it.copy(isLoading = false, signedIn = true) } }
                .onFailure { e -> _state.update { it.copy(isLoading = false, error = e.message) } }
        }
    }

    fun signUp() {
        val s = _state.value
        if (s.password != s.confirmPassword) {
            _state.update { it.copy(error = "Passwords do not match") }
            return
        }
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true, error = null) }
            authRepository.signUp(s.email, s.username, s.password)
                .onSuccess { _state.update { it.copy(isLoading = false, signedIn = true) } }
                .onFailure { e -> _state.update { it.copy(isLoading = false, error = e.message) } }
        }
    }
}
