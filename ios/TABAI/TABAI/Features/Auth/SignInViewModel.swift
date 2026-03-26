import Foundation
import AuthenticationServices
import Combine

@MainActor
final class SignInViewModel: ObservableObject {
    enum AuthMode: Hashable {
        case signIn
        case createAccount
    }

    enum AuthProvider {
        case apple
        case google
    }

    @Published var mode: AuthMode = .signIn
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var infoMessage: String?
    @Published var providerStatusMessage: String?
    @Published var showEmailNotVerified: Bool = false
    @Published var showForgotPassword: Bool = false
    @Published var forgotPasswordEmail: String = ""

    var isPrimaryActionDisabled: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedEmail.isEmpty || password.isEmpty
    }

    func selectEmailPath() {
        mode = .signIn
        providerStatusMessage = nil
        errorMessage = nil
        infoMessage = nil
    }

    func handleProviderTap(_ provider: AuthProvider) {
        errorMessage = nil
        infoMessage = nil
        switch provider {
        case .apple:
            providerStatusMessage = nil // Apple Sign-In is handled natively
        case .google:
            providerStatusMessage = "Google Sign-In coming soon. Use Apple or Email for now."
        }
    }

    // MARK: - Apple Sign-In

    func handleAppleSignIn(result: Result<ASAuthorization, Error>, appEnvironment: AppEnvironment) async {
        errorMessage = nil
        infoMessage = nil
        providerStatusMessage = nil

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                errorMessage = "Could not read Apple credentials. Please try again."
                return
            }

            isLoading = true
            do {
                try await appEnvironment.signInWithApple(
                    identityToken: identityToken,
                    fullName: credential.fullName,
                    email: credential.email
                )
            } catch let error as TABAIError {
                errorMessage = error.localizedDescription
            } catch {
                errorMessage = "Apple Sign-In failed. Please try again or use email."
            }
            isLoading = false

        case .failure(let error):
            // User cancelled — don't show error
            if (error as? ASAuthorizationError)?.code == .canceled {
                return
            }
            errorMessage = "Apple Sign-In was interrupted. Please try again."
        }
    }

    // MARK: - Google Sign-In (Web OAuth)

    func handleGoogleSignIn(appEnvironment: AppEnvironment) async {
        errorMessage = nil
        infoMessage = nil
        providerStatusMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            try await appEnvironment.signInWithGoogle()
        } catch {
            if (error as NSError).code == 1 {
                // User cancelled — don't show error
                return
            }
            errorMessage = "Google Sign-In failed. Please try again or use email."
        }
    }

    // MARK: - Password Validation

    static let minPasswordLength = 8

    static func validatePassword(_ password: String) -> String? {
        if password.count < minPasswordLength {
            return "Password must be at least \(minPasswordLength) characters."
        }
        if !password.contains(where: { $0.isUppercase }) {
            return "Password must contain at least one uppercase letter."
        }
        if !password.contains(where: { $0.isLowercase }) {
            return "Password must contain at least one lowercase letter."
        }
        if !password.contains(where: { $0.isNumber }) {
            return "Password must contain at least one number."
        }
        if !password.contains(where: { "!@#$%^&*()_+-=[]{}|;:',.<>?/~`".contains($0) }) {
            return "Password must contain at least one special character."
        }
        return nil // valid
    }

    // MARK: - Email Sign-In / Sign-Up

    func submitEmail(appEnvironment: AppEnvironment) async {
        errorMessage = nil
        infoMessage = nil
        providerStatusMessage = nil
        showEmailNotVerified = false

        if mode == .createAccount {
            // Validate password for signup
            if let passwordError = Self.validatePassword(password) {
                errorMessage = passwordError
                return
            }
            if password != confirmPassword {
                errorMessage = "Passwords don't match."
                return
            }
            await signUp(appEnvironment: appEnvironment)
        } else {
            await signIn(appEnvironment: appEnvironment)
        }
    }

    func signIn(appEnvironment: AppEnvironment) async {
        errorMessage = nil
        infoMessage = nil
        providerStatusMessage = nil
        showEmailNotVerified = false
        isLoading = true
        do {
            try await appEnvironment.signIn(email: email, password: password)
        } catch let error as TABAIAuthService.Error {
            switch error {
            case .emailNotVerified:
                errorMessage = "Verify your email to sign in. Check your inbox for the verification link."
                showEmailNotVerified = true
            case .invalidCredentials:
                errorMessage = "Invalid email or password. Please try again."
            default:
                errorMessage = "Sign-in failed. Check your email and password, then try again."
            }
        } catch {
            errorMessage = "Sign-in failed. Check your email and password, then try again."
        }
        isLoading = false
    }

    func signUp(appEnvironment: AppEnvironment) async {
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        do {
            try await appEnvironment.signUp(email: email, password: password)
            infoMessage = "Account created! Check your email for a verification link, then sign in."
            mode = .signIn
            password = ""
            confirmPassword = ""
        } catch {
            errorMessage = "Could not create account. The email may already be registered."
        }
        isLoading = false
    }

    // MARK: - Resend Verification

    func resendVerification(appEnvironment: AppEnvironment) async {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        do {
            let authService = appEnvironment.authService as? TABAIAuthService
            try await authService?.requestVerification(email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
            infoMessage = "Verification email sent. Check your inbox."
            showEmailNotVerified = false
        } catch {
            infoMessage = "Verification email sent. Check your inbox."
        }
        isLoading = false
    }

    // MARK: - Forgot Password

    func sendPasswordReset(appEnvironment: AppEnvironment) async {
        let trimmed = forgotPasswordEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        do {
            let authService = appEnvironment.authService as? TABAIAuthService
            try await authService?.requestPasswordReset(email: trimmed.lowercased())
        } catch {
            // Silently succeed — don't reveal whether email exists
        }
        isLoading = false
        showForgotPassword = false
        infoMessage = "If an account exists for that email, we've sent a reset link."
    }
}
