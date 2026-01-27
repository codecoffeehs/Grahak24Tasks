import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject private var auth: AuthStore

    @State private var email: String = ""
    @State private var otp: String = ""

    @State private var didSendOtp: Bool = false
    @State private var navigateToReset: Bool = false

    // Local resend cooldown state
    @State private var canResendOtp: Bool = true
    @State private var resendCountdown: Int = 0
    @State private var cooldownTask: Task<Void, Never>?

    @FocusState private var focusedField: Field?

    enum Field {
        case email
        case otp
    }

    // Minimal validation
    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    private var canSendOtp: Bool {
        isEmailValid && !auth.isLoading
    }

    private var canVerifyOtp: Bool {
        didSendOtp && otp.count == 4 && !auth.isLoading
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 12)

            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Forgot password")
                    .font(.largeTitle.bold())
                    .scaleEffect(didSendOtp ? 1.0 : 1.02)
                    .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.6), value: didSendOtp)

                Text(didSendOtp
                     ? "Enter the 4-digit code sent to your email"
                     : "We’ll send you a 4-digit OTP to reset your password")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Fields
            VStack(spacing: 18) {
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
                        .onSubmit {
                            if didSendOtp {
                                focusedField = .otp
                            } else {
                                Task { await sendOtp() }
                            }
                        }
                        .disabled(auth.isLoading || didSendOtp) // lock email after OTP sent

                    Divider()
                        .background(underlineColor(valid: isEmailValid || email.isEmpty))
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.98).combined(with: .opacity).animation(.spring(response: 0.35, dampingFraction: 0.85)),
                    removal: .opacity.animation(.easeOut(duration: 0.18))
                ))

                // OTP (appears after sending)
                if didSendOtp {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("OTP")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button(canResendOtp ? "Resend" : "Resend in \(resendCountdown)s") {
                                lightImpact()
                                Task { await resendOtp() }
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(canResendOtp ? Color.blue : Color.gray)
                            .buttonStyle(.plain)
                            .disabled(auth.isLoading || !canResendOtp)
                            .scaleEffect(auth.isLoading ? 0.98 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: auth.isLoading)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: canResendOtp)
                        }

                        TextField("1234", text: $otp)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .focused($focusedField, equals: .otp)
                            .submitLabel(.done)
                            .onChange(of: otp) { _, newValue in
                                // keep only digits, max 4
                                otp = newValue
                                    .filter { $0.isNumber }
                                    .prefix(4)
                                    .map(String.init)
                                    .joined()

                                // light haptic when full
                                if otp.count == 4 {
                                    lightImpact()
                                }
                            }
                            .disabled(auth.isLoading)

                        Divider()
                            .background(underlineColor(valid: otp.isEmpty || otp.count == 4))
                    }
                    // Bouncy entrance for OTP block
                    .transition(
                        .asymmetric(
                            insertion: .move(edge: .top)
                                .combined(with: .opacity)
                                .combined(with: .scale(scale: 0.98))
                                .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.6)),
                            removal: .opacity.animation(.easeOut(duration: 0.2))
                        )
                    )
                }
            }
            // Make the overall state change feel bouncy
            .animation(.interactiveSpring(response: 0.5, dampingFraction: 0.85, blendDuration: 0.6), value: didSendOtp)

            // Primary Button
            PrimaryActionButton(
                title: auth.isLoading
                    ? "Please wait…"
                    : (didSendOtp ? "Verify OTP" : "Send OTP"),
                isLoading: auth.isLoading,
                isDisabled: didSendOtp ? !canVerifyOtp : !canSendOtp
            ) {
                if didSendOtp {
                    await verifyOtp()
                } else {
                    await sendOtp()
                }
            }
            .scaleEffect(auth.isLoading ? 0.98 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: auth.isLoading)

            // Secondary action
            if didSendOtp {
                Button {
                    lightImpact()
                    // allow editing email again
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        didSendOtp = false
                        otp = ""
                        focusedField = .email
                    }
                    // cancel any running cooldown
                    cooldownTask?.cancel()
                    canResendOtp = true
                    resendCountdown = 0
                } label: {
                    Text("Change email")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.blue)
                }
                .buttonStyle(.plain)
                .disabled(auth.isLoading)
            } else {
                Button{
                    dismiss()
                }label: {
                    Text("Remembered it? Go back and sign in.")
                        .font(.footnote)
                        .foregroundStyle(.blue)
                }
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 420)
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                focusedField = .email
            }
        }
        .onDisappear {
            cooldownTask?.cancel()
        }
        .alert("Error", isPresented: $auth.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "Something went wrong")
        }
        // Modern navigation API: present destination when navigateToReset is true
        .navigationDestination(isPresented: $navigateToReset) {
            ResetPasswordView(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                otp: otp
            )
            .environmentObject(auth)
        }
    }

    // MARK: - Flows

    private func sendOtp() async {
        guard canSendOtp else {
            warningImpact()
            return
        }

        lightImpact()
        await auth.sendPasswordResetOtp(email: email.trimmingCharacters(in: .whitespacesAndNewlines))

        // If no error, consider OTP sent
        if auth.errorMessage == nil {
            withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.85, blendDuration: 0.6)) {
                didSendOtp = true
                focusedField = .otp
            }
            successHaptic()
            startCooldown(seconds: 15)
        }
    }

    private func resendOtp() async {
        guard canResendOtp, !auth.isLoading else { return }
        await auth.resendPassword(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            otpPurpose: 1 // forgot password
        )
        if auth.errorMessage == nil {
            successHaptic()
            startCooldown(seconds: 15)
        }
    }

    private func verifyOtp() async {
        guard canVerifyOtp else {
            warningImpact()
            return
        }

        await auth.confirmPasswordresetOtp(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            otp: otp
        )

        if auth.errorMessage == nil {
            successHaptic()
            withAnimation(.interactiveSpring(response: 0.5, dampingFraction: 0.85, blendDuration: 0.6)) {
                navigateToReset = true
            }
        } else {
            errorHaptic()
        }
    }

    // MARK: - Cooldown (local)
    private func startCooldown(seconds: Int) {
        cooldownTask?.cancel()
        guard seconds > 0 else {
            canResendOtp = true
            resendCountdown = 0
            return
        }
        canResendOtp = false
        resendCountdown = seconds

        cooldownTask = Task { @MainActor in
            while resendCountdown > 0 && !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                resendCountdown -= 1
            }
            if !Task.isCancelled {
                canResendOtp = true
            }
        }
    }

    // MARK: - Underline color
    private func underlineColor(valid: Bool) -> Color {
        if auth.isLoading { return Color.gray.opacity(0.3) }
        return valid ? Color.secondary.opacity(0.25) : Color.red.opacity(0.6)
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
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
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
    NavigationStack {
        ForgotPasswordView()
            .environmentObject(AuthStore())
    }
}
