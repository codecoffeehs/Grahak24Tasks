import SwiftUI

struct ForgotPasswordView: View {
    @State private var email: String = ""
    @State private var otp: String = ""

    @State private var didSendOtp: Bool = false
    @State private var isLoading: Bool = false

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
        isEmailValid && !isLoading
    }

    private var canVerifyOtp: Bool {
        didSendOtp && otp.count == 4 && !isLoading
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Forgot password")
                    .font(.largeTitle.bold())

                Text(didSendOtp
                     ? "Enter the 4-digit code sent to your email"
                     : "We’ll send you a 4-digit OTP to reset your password")
                    .font(.callout)
                    .foregroundStyle(.secondary)
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
                                sendOtp()
                            }
                        }
                        .disabled(isLoading || didSendOtp) // lock email after OTP sent

                    Divider()
                        .background(underlineColor(valid: isEmailValid || email.isEmpty))
                }

                // OTP (appears after sending)
                if didSendOtp {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("OTP")
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Button("Resend") {
                                lightImpact()
                                resendOtp()
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(Color.blue)
                            .buttonStyle(.plain)
                            .disabled(isLoading)
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

                                // auto verify when full
                                if otp.count == 4 {
                                    lightImpact()
                                }
                            }
                            .disabled(isLoading)

                        Divider()
                            .background(underlineColor(valid: otp.isEmpty || otp.count == 4))
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: didSendOtp)

            // Primary Button
            PrimaryActionButton(
                title: isLoading
                    ? "Please wait…"
                    : (didSendOtp ? "Verify OTP" : "Send OTP"),
                isLoading: isLoading,
                isDisabled: didSendOtp ? !canVerifyOtp : !canSendOtp
            ) {
                if didSendOtp {
                    verifyOtp()
                } else {
                    sendOtp()
                }
            }

            // Secondary action
            if didSendOtp {
                Button {
                    lightImpact()
                    // allow editing email again
                    didSendOtp = false
                    otp = ""
                    focusedField = .email
                } label: {
                    Text("Change email")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.blue)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            } else {
                Text("Remembered it? Go back and sign in.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
    }

    // MARK: - Dummy flows

    private func sendOtp() {
        guard canSendOtp else {
            warningImpact()
            return
        }

        lightImpact()
        isLoading = true

        // dummy network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false
            didSendOtp = true
            focusedField = .otp
            successHaptic()
        }
    }

    private func resendOtp() {
        lightImpact()
        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isLoading = false
            successHaptic()
        }
    }

    private func verifyOtp() {
        guard canVerifyOtp else {
            warningImpact()
            return
        }

        isLoading = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isLoading = false

            // dummy check
            if otp == "1234" {
                successHaptic()
                // TODO: Navigate to ResetPasswordView later
            } else {
                otp = ""
                errorHaptic()
            }
        }
    }

    // MARK: - Underline color
    private func underlineColor(valid: Bool) -> Color {
        if isLoading { return Color.gray.opacity(0.3) }
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
    }
}
