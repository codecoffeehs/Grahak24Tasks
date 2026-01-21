import SwiftUI

struct ResetPasswordView: View {
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""

    @State private var showNewPassword: Bool = false
    @State private var showConfirmPassword: Bool = false

    @State private var isLoading: Bool = false
    @State private var showSuccessAlert: Bool = false

    @FocusState private var focusedField: Field?

    enum Field {
        case newPassword
        case confirmPassword
    }

    private var canSubmit: Bool {
        !newPassword.isEmpty &&
        !confirmPassword.isEmpty &&
        newPassword.count >= 6 &&
        newPassword == confirmPassword &&
        !isLoading
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Reset password")
                    .font(.largeTitle.bold())

                Text("Create a new password for your account")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Fields
            VStack(spacing: 18) {
                // New password
                VStack(alignment: .leading, spacing: 8) {
                    Text("New password")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Group {
                            if showNewPassword {
                                TextField("New password", text: $newPassword)
                            } else {
                                SecureField("New password", text: $newPassword)
                            }
                        }
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .newPassword)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .confirmPassword }
                        .disabled(isLoading)

                        Button {
                            showNewPassword.toggle()
                            lightImpact()
                        } label: {
                            Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showNewPassword ? "Hide new password" : "Show new password")
                    }

                    Divider()
                        .background(underlineColor(valid: newPassword.isEmpty || newPassword.count >= 6))
                }

                // Confirm password
                VStack(alignment: .leading, spacing: 8) {
                    Text("Confirm password")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 8) {
                        Group {
                            if showConfirmPassword {
                                TextField("Confirm password", text: $confirmPassword)
                            } else {
                                SecureField("Confirm password", text: $confirmPassword)
                            }
                        }
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .submitLabel(.go)
                        .onSubmit {
                            if canSubmit {
                                Task { await resetPassword() }
                            } else {
                                warningImpact()
                            }
                        }
                        .disabled(isLoading)

                        Button {
                            showConfirmPassword.toggle()
                            lightImpact()
                        } label: {
                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showConfirmPassword ? "Hide confirm password" : "Show confirm password")
                    }

                    Divider()
                        .background(underlineColor(valid: confirmPassword.isEmpty || confirmPassword == newPassword))
                }

                // Helper text
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password requirements")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text("• At least 8 characters\n• Must match confirmation")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
            }

            // Primary Button
            PrimaryActionButton(
                title: isLoading ? "Updating…" : "Update Password",
                isLoading: isLoading,
                isDisabled: !canSubmit
            ) {
                await resetPassword()
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 420)
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                focusedField = .newPassword
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your password was updated.")
        }
    }

    // MARK: - Dummy reset logic
    private func resetPassword() async {
        guard canSubmit else {
            warningImpact()
            return
        }

        lightImpact()
        isLoading = true

        // Dummy delay
        try? await Task.sleep(nanoseconds: 800_000_000)

        isLoading = false
        successHaptic()
        showSuccessAlert = true
    }

    // MARK: - Underline color logic (same style)
    private func underlineColor(valid: Bool) -> Color {
        if isLoading { return Color.gray.opacity(0.3) }
        return valid ? Color.secondary.opacity(0.25) : Color.red.opacity(0.6)
    }

    // MARK: - Haptics (same vibe)
    private func successHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
        ResetPasswordView()
    }
}
