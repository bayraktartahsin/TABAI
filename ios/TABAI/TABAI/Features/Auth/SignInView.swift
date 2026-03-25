import SwiftUI
import AuthenticationServices
import UIKit

struct SignInView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel: SignInViewModel
    @State private var showEmailForm = false
    @State private var legalDestination: LegalLinkDestination?

    init(viewModel: SignInViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Background
            GradientBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + brand
                VStack(spacing: 16) {
                    AnimatedBrandLogo(size: 56)

                    Text("TABAI")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.Colors.textPrimary)

                    Text("Create an account for free")
                        .font(.system(size: 15))
                        .foregroundStyle(DS.Colors.textSecondary)
                }

                Spacer()
                Spacer()

                // Auth buttons
                VStack(spacing: 12) {
                    if showEmailForm {
                        emailForm
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else {
                        authButtons
                            .transition(.opacity)
                    }
                }
                .padding(.horizontal, 20)
                .animation(DS.Motion.spring, value: showEmailForm)

                // Legal footer
                HStack {
                    Button("Privacy policy") {
                        legalDestination = LegalLinkDestination(key: .privacy)
                    }
                    Spacer()
                    Button("Terms of service") {
                        legalDestination = LegalLinkDestination(key: .terms)
                    }
                }
                .font(.system(size: 13))
                .foregroundStyle(DS.Colors.textSecondary.opacity(0.6))
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
        }
        .sheet(item: $legalDestination) { destination in
            InAppSafariView(url: destination.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $viewModel.showForgotPassword) {
            forgotPasswordSheet
        }
        .onChange(of: viewModel.errorMessage) { _, newValue in
            guard newValue != nil else { return }
            Haptics.impact(.rigid)
        }
        .onChange(of: appEnvironment.session?.isAuthenticated == true) { _, isAuthed in
            guard isAuthed else { return }
        }
    }

    // MARK: - Auth Buttons (Perplexity-style)

    private var authButtons: some View {
        VStack(spacing: 10) {
            // Apple - black/white native button
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.email, .fullName]
            } onCompletion: { result in
                Task {
                    await viewModel.handleAppleSignIn(result: result, appEnvironment: appEnvironment)
                }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            // Google - white with colorful G
            Button {
                Task {
                    await viewModel.handleGoogleSignIn(appEnvironment: appEnvironment)
                }
            } label: {
                HStack(spacing: 10) {
                    // Colorful Google "G"
                    GoogleGLogo()
                        .frame(width: 18, height: 18)
                    Text("Continue with Google")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .buttonStyle(.plain)

            // Email - grey
            Button {
                withAnimation(DS.Motion.spring) {
                    showEmailForm = true
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                    Text("Sign in with email")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .buttonStyle(.plain)

            if let err = viewModel.errorMessage {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
            }

            if viewModel.isLoading {
                ProgressView()
                    .tint(DS.Colors.accent)
                    .padding(.top, 8)
            }
        }
    }

    // MARK: - Email Form (expandable)

    private var emailForm: some View {
        VStack(spacing: 12) {
            // Back button
            HStack {
                Button {
                    withAnimation(DS.Motion.spring) {
                        showEmailForm = false
                        viewModel.errorMessage = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .medium))
                        Text("Back")
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(DS.Colors.textSecondary)
                }
                .buttonStyle(.plain)
                Spacer()
            }

            TAITextField(title: "Email", text: $viewModel.email)
            TAITextField(title: "Password", text: $viewModel.password, isSecure: true)

            if viewModel.mode == .createAccount {
                TAITextField(title: "Confirm Password", text: $viewModel.confirmPassword, isSecure: true)

                // Password requirements hint
                VStack(alignment: .leading, spacing: 3) {
                    passwordHint("8+ characters", met: viewModel.password.count >= 8)
                    passwordHint("Uppercase letter", met: viewModel.password.contains(where: { $0.isUppercase }))
                    passwordHint("Lowercase letter", met: viewModel.password.contains(where: { $0.isLowercase }))
                    passwordHint("Number", met: viewModel.password.contains(where: { $0.isNumber }))
                    passwordHint("Special character", met: viewModel.password.contains(where: { "!@#$%^&*()_+-=[]{}|;:',.<>?/~`".contains($0) }))
                }
                .padding(.vertical, 4)
            }

            if let err = viewModel.errorMessage {
                Text(err)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(
                title: viewModel.mode == .createAccount ? "Create Account" : "Sign In",
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.isPrimaryActionDisabled
            ) {
                dismissKeyboard()
                Task { await viewModel.submitEmail(appEnvironment: appEnvironment) }
            }

            if viewModel.showEmailNotVerified {
                Button("Resend Verification Email") {
                    Task { await viewModel.resendVerification(appEnvironment: appEnvironment) }
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.accent)
            }

            if viewModel.mode == .signIn {
                Button("Forgot password?") {
                    viewModel.forgotPasswordEmail = viewModel.email
                    viewModel.showForgotPassword = true
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.Colors.textSecondary)
            }

            // Toggle between sign in and create account
            Button(viewModel.mode == .signIn ? "Don't have an account? Create one" : "Already have an account? Sign in") {
                withAnimation(DS.Motion.spring) {
                    viewModel.mode = viewModel.mode == .signIn ? .createAccount : .signIn
                    viewModel.errorMessage = nil
                    viewModel.infoMessage = nil
                }
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(DS.Colors.accent)

            if let info = viewModel.infoMessage {
                Text(info)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.accent)
            }
        }
    }

    // MARK: - Forgot Password Sheet

    private var forgotPasswordSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reset Password")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(DS.Colors.textPrimary)

                Text("Enter your email and we'll send you a link to reset your password.")
                    .font(.system(size: 15))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)

                TAITextField(title: "Email", text: $viewModel.forgotPasswordEmail)

                PrimaryButton(
                    title: "Send Reset Link",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.forgotPasswordEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    dismissKeyboard()
                    Task { await viewModel.sendPasswordReset(appEnvironment: appEnvironment) }
                }

                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.showForgotPassword = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func passwordHint(_ text: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 11))
                .foregroundStyle(met ? DS.Colors.accent : DS.Colors.textSecondary.opacity(0.4))
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(met ? DS.Colors.textPrimary : DS.Colors.textSecondary.opacity(0.5))
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Google "G" Logo (accurate proportions)

private struct GoogleGLogo: View {
    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let cx = size.width / 2
            let cy = size.height / 2
            let outer = s / 2
            let inner = outer * 0.58
            let stroke = outer - inner

            // Full colored ring (4 segments)
            // Red: top-left arc (150° to 240°)
            drawArcSegment(context: context, cx: cx, cy: cy, outer: outer, inner: inner,
                          start: 150, end: 240, color: Color(red: 0.92, green: 0.26, blue: 0.21))
            // Yellow: bottom-left arc (240° to 315°)
            drawArcSegment(context: context, cx: cx, cy: cy, outer: outer, inner: inner,
                          start: 240, end: 315, color: Color(red: 0.98, green: 0.74, blue: 0.02))
            // Green: bottom-right arc (315° to 30°)
            drawArcSegment(context: context, cx: cx, cy: cy, outer: outer, inner: inner,
                          start: 315, end: 390, color: Color(red: 0.20, green: 0.66, blue: 0.33))
            // Blue: top-right arc (30° to 150°)
            drawArcSegment(context: context, cx: cx, cy: cy, outer: outer, inner: inner,
                          start: 30, end: 150, color: Color(red: 0.26, green: 0.52, blue: 0.96))

            // Blue horizontal bar (the crossbar of the G)
            let barY = cy - stroke * 0.5
            let barH = stroke
            let barRect = CGRect(x: cx - stroke * 0.15, y: barY, width: outer + stroke * 0.15, height: barH)
            context.fill(Path(barRect), with: .color(Color(red: 0.26, green: 0.52, blue: 0.96)))

            // Clear the right-top opening to form the "G" shape
            let clearRect = CGRect(x: cx + inner * 0.2, y: cy - outer - 1, width: outer, height: outer - stroke * 0.5 + 1)
            context.fill(Path(clearRect), with: .color(.white))
        }
    }

    private func drawArcSegment(context: GraphicsContext, cx: CGFloat, cy: CGFloat,
                                 outer: CGFloat, inner: CGFloat,
                                 start: Double, end: Double, color: Color) {
        var path = Path()
        path.addArc(center: CGPoint(x: cx, y: cy), radius: outer,
                    startAngle: .degrees(start - 90), endAngle: .degrees(end - 90), clockwise: false)
        path.addArc(center: CGPoint(x: cx, y: cy), radius: inner,
                    startAngle: .degrees(end - 90), endAngle: .degrees(start - 90), clockwise: true)
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }
}
