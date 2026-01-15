import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword: Bool = false
    @FocusState private var focusedField: Field?
    @EnvironmentObject var auth: AuthStore
    @Environment(\.colorScheme) private var colorScheme

    enum Field {
        case email
        case password
    }

    // Minimal validation: email contains "@" and "."
    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    private var canSubmit: Bool {
        !email.isEmpty && !password.isEmpty && isEmailValid && !auth.isLoading
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome back")
                    .font(.largeTitle.bold())

                Text("Sign in to continue")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Fields (minimal style)
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    TextField("you@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .textContentType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                        .disabled(auth.isLoading)

                    Divider()
                        .background(underlineColor(valid: isEmailValid || email.isEmpty))
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Password")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Forgot password?") {
                            lightImpact()
                            // Hook up your reset flow here
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.blue)
                        .buttonStyle(.plain)
                        .disabled(auth.isLoading)
                    }

                    HStack(spacing: 8) {
                        Group {
                            if showPassword {
                                TextField("Your password", text: $password)
                            } else {
                                SecureField("Your password", text: $password)
                            }
                        }
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit {
                            if canSubmit {
                                Task { await performLogin() }
                            } else {
                                warningImpact()
                            }
                        }
                        .disabled(auth.isLoading)

                        Button {
                            showPassword.toggle()
                            lightImpact()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showPassword ? "Hide password" : "Show password")
                    }

                    Divider()
                        .background(underlineColor(valid: !password.isEmpty || password.isEmpty))
                }
            }

            // Primary Button
            PrimaryActionButton(
                title: auth.isLoading ? "Signing in…" : "Log In",
                isLoading: auth.isLoading,
                isDisabled: !canSubmit
            ) {
                await performLogin()
            }

            // Navigation
            NavigationLink {
                SignupView()
            } label: {
                Text("Don’t have an account? Sign up")
                    .font(.footnote)
                    .foregroundStyle(Color.blue)
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 420)
        .background(Color(.systemBackground).ignoresSafeArea())

        // Top decorative overlay (your original, stronger styling)
        .overlay(alignment: .topLeading) {
            ZStack {
                RoundedRectangle(cornerRadius: 120, style: .continuous)
                    .stroke(Color.orange.opacity(0.10), lineWidth: 1)
                    .frame(width: 460, height: 320)
                    .rotationEffect(.degrees(-18))

                RoundedRectangle(cornerRadius: 120, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                    .frame(width: 420, height: 290)
                    .rotationEffect(.degrees(-18))

                RoundedRectangle(cornerRadius: 120, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    .frame(width: 380, height: 260)
                    .rotationEffect(.degrees(-18))
            }
            .offset(x: -180, y: -140)
            .allowsHitTesting(false)
        }

        // Bottom decorative overlay (subtle)
        .overlay(alignment: .bottomTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 90, style: .continuous)
                    .fill(Color.orange.opacity(0.035))
                    .frame(width: 360, height: 240)
                    .rotationEffect(.degrees(14))

                RoundedRectangle(cornerRadius: 70, style: .continuous)
                    .fill(Color.primary.opacity(0.02))
                    .frame(width: 300, height: 200)
                    .rotationEffect(.degrees(8))
            }
            .offset(x: 160, y: 140)
            .allowsHitTesting(false)
        }

        .alert("Error", isPresented: $auth.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "Couldn't sign in")
        }
        .onAppear {
            // Focus email on first appearance
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if email.isEmpty { focusedField = .email }
            }
        }
        // Haptics on state changes
        .onChange(of: auth.showErrorAlert) { _, newValue in
            if newValue { errorHaptic() }
        }
        .onChange(of: auth.isAuthenticated) { _, newValue in
            if newValue { successHaptic() }
        }
    }

    // Minimal underline color logic
    private func underlineColor(valid: Bool) -> Color {
        if auth.isLoading { return Color.gray.opacity(0.3) }
        return valid ? Color.secondary.opacity(0.25) : Color.red.opacity(0.6)
    }

    private func performLogin() async {
        await auth.login(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
    }

    // MARK: - Haptics
    private func successHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    private func errorHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
    }

    private func warningImpact() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
    }

    private func lightImpact() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        #endif
    }
}

#Preview {
   LoginView()
        .environmentObject(AuthStore())
}
