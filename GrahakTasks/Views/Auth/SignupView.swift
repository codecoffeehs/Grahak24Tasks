import SwiftUI

struct SignupView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var passwordTooLongAlert = false

    @FocusState private var focusedField: Field?
    @EnvironmentObject var auth: AuthStore
    @Environment(\.colorScheme) private var colorScheme

    // Navigation to confirm view
    @State private var navigateToConfirm = false

    enum Field {
        case fullName
        case email
        case password
        case confirmPassword
    }

    // Minimal validation similar to LoginView
    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    private var isNameValid: Bool {
        fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    // Password validation
    private var isPasswordMinValid: Bool {
        password.count >= 8
    }

    private var isPasswordMaxValid: Bool {
        password.count <= 12
    }

    private var doPasswordsMatch: Bool {
        password == confirmPassword
    }

    private var canSubmit: Bool {
        isNameValid
        && !email.isEmpty
        && !password.isEmpty
        && !confirmPassword.isEmpty
        && isEmailValid
        && isPasswordMinValid
        && doPasswordsMatch
        && !auth.isLoading
    }

    var body: some View {

        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Create account")
                    .font(.largeTitle.bold())

                Text("Start organizing your tasks")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Fields (minimal style)
            VStack(spacing: 18) {
                // Full name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full name")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    TextField("Name Here", text: $fullName)
                        .textInputAutocapitalization(.words)
                        .disableAutocorrection(true)
                        .textContentType(.name)
                        .focused($focusedField, equals: .fullName)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .email }
                        .disabled(auth.isLoading)

                    Divider()
                        .background(underlineColor(valid: isNameValid || fullName.isEmpty))
                }

                // Email
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

                // Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Group {
                            if showPassword {
                                TextField("Create a password", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            } else {
                                SecureField("Create a password", text: $password)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            }
                        }
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirmPassword }
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

                    // Helper text: show only when user typed something but it's under 8 chars
                    if !password.isEmpty && !isPasswordMinValid {
                        Text("Password must be at least 8 characters.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }
                }

                // Confirm Password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm password")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    Group {
                        if showPassword {
                            TextField("Re-enter password", text: $confirmPassword)
                        } else {
                            SecureField("Re-enter password", text: $confirmPassword)
                        }
                    }
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .submitLabel(.go)
                    .onSubmit {
                        if canSubmit {
                            Task { await performSignupWithLengthCheck() }
                        } else {
                            warningImpact()
                            if !isPasswordMaxValid {
                                passwordTooLongAlert = true
                            }
                        }
                    }
                    .disabled(auth.isLoading)

                    Divider()
                        .background(underlineColor(valid: confirmPassword.isEmpty || doPasswordsMatch))

                    // Mismatch text (red)
                    if !confirmPassword.isEmpty && !doPasswordsMatch {
                        Text("Passwords do not match.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }
                }
            }

            // Primary Button
            PrimaryActionButton(
                title: auth.isLoading ? "Creating account…" : "Sign Up",
                isLoading: auth.isLoading,
                isDisabled: !canSubmit
            ) {
                await performSignupWithLengthCheck()
            }

            // Navigation
            NavigationLink {
                LoginView()
            } label: {
                Text("Already have an account? Log in")
                    .font(.footnote)
                    .foregroundStyle(Color.blue)
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 420)

        // Background
        .background(
            Color(.systemBackground)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    // Dismiss focus when tapping outside
                    focusedField = nil
                    #if os(iOS)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    #endif
                }
        )

        // Top decorative overlay (to match LoginView’s stronger styling)
        .overlay(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 130, style: .continuous)
                    .stroke(Color.orange.opacity(0.10), lineWidth: 1)
                    .frame(width: 480, height: 340)
                    .rotationEffect(.degrees(14))

                RoundedRectangle(cornerRadius: 120, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                    .frame(width: 440, height: 310)
                    .rotationEffect(.degrees(14))

                RoundedRectangle(cornerRadius: 110, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    .frame(width: 400, height: 280)
                    .rotationEffect(.degrees(14))
            }
            .offset(x: 200, y: -120)
            .allowsHitTesting(false)
        }

        // Bottom decorative overlay (subtle)
        .overlay(alignment: .bottomLeading) {
            ZStack {
                RoundedRectangle(cornerRadius: 100, style: .continuous)
                    .fill(Color.orange.opacity(0.035))
                    .frame(width: 420, height: 260)
                    .rotationEffect(.degrees(-8))

                RoundedRectangle(cornerRadius: 80, style: .continuous)
                    .fill(Color.primary.opacity(0.02))
                    .frame(width: 340, height: 210)
                    .rotationEffect(.degrees(-4))
            }
            .offset(x: -180, y: 160)
            .allowsHitTesting(false)
        }

        .alert("Error", isPresented: $auth.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "Couldn't sign up")
        }
        // Alert specifically for password > 12 on submit
        .alert("Password too long", isPresented: $passwordTooLongAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please use a password of 12 characters or fewer.")
        }
        .onAppear {
            // Focus full name initially
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if fullName.isEmpty { focusedField = .fullName }
            }
        }
        // Haptics on state changes
        .onChange(of: auth.showErrorAlert) { _, newValue in
            if newValue { errorHaptic() }
        }
        .onChange(of: auth.isAuthenticated) { _, newValue in
            if newValue { successHaptic() }
        }
        // Modern navigation for confirm screen
        .navigationDestination(isPresented: $navigateToConfirm) {
            SignupConfirmView(email: email.trimmingCharacters(in: .whitespacesAndNewlines))
                .environmentObject(auth)
        }
        // Prevent layout shift when keyboard shows
        .ignoresSafeArea(.keyboard)
    }

    // Minimal underline color logic (consistent with LoginView)
    private func underlineColor(valid: Bool) -> Color {
        if auth.isLoading { return Color.gray.opacity(0.3) }
        return valid ? Color.secondary.opacity(0.25) : Color.red.opacity(0.6)
    }

    private func performSignupWithLengthCheck() async {
        // If too long, show alert and stop
        if !isPasswordMaxValid {
            passwordTooLongAlert = true
            warningImpact()
            return
        }
        await performSignup()
    }

    private func performSignup() async {
        await auth.signup(
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )
        // On success, navigate to confirm screen.
        if auth.errorMessage == nil {
            navigateToConfirm = true
        }
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

#Preview{
    SignupView().environmentObject(AuthStore())
}
