//
//  SignupConfirmView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 21/01/26.
//

import SwiftUI
import UIKit

struct SignupConfirmView: View {
    let email: String

    @State private var d1: String = ""
    @State private var d2: String = ""
    @State private var d3: String = ""
    @State private var d4: String = ""

    // Local resend cooldown state
    @State private var canResendOtp: Bool = true
    @State private var resendCountdown: Int = 0
    @State private var cooldownTask: Task<Void, Never>?

    enum Field: Hashable {
        case d1, d2, d3, d4
    }

    @FocusState private var focusedField: Field?
    @EnvironmentObject private var auth: AuthStore

    private var otp: String { d1 + d2 + d3 + d4 }
    private var canVerify: Bool { otp.count == 4 && otp.allSatisfy({ $0.isNumber }) }

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 20)

            VStack(alignment: .leading, spacing: 6) {
                Text("Verify your email")
                    .font(.largeTitle.bold())

                Text("We’ve sent an OTP to \(email)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // OTP Inputs
            HStack(spacing: 12) {
                otpBox(text: $d1, tag: .d1, next: .d2, prev: nil)
                otpBox(text: $d2, tag: .d2, next: .d3, prev: .d1)
                otpBox(text: $d3, tag: .d3, next: .d4, prev: .d2)
                otpBox(text: $d4, tag: .d4, next: nil, prev: .d3)
            }
            .padding(.top, 8)

            // Verify button
            PrimaryActionButton(
                title: auth.isLoading ? "Verifying" : "Verify",
                isLoading: auth.isLoading,
                isDisabled: !canVerify
            ) {
                await performVerify()
            }

            // Resend row
            HStack {
                Text("Didn’t receive the code?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Button(canResendOtp ? "Resend" : "Resend in \(resendCountdown)s") {
                    #if os(iOS)
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    #endif
                    Task {
                        await resendSignupOtp()
                    }
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.plain)
                .foregroundStyle(canResendOtp ? Color.blue : Color.gray)
                .disabled(auth.isLoading || !canResendOtp)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: auth.isLoading)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: canResendOtp)
            }
            .padding(.top, 2)

            // Change email
            Button {
                #if os(iOS)
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                #endif
            } label: {
                Text("Sign up with a different email ID")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.blue)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 420)
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            // Focus first field after a brief delay to ensure the view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                focusedField = .d1
            }
            // Start an initial cooldown assuming OTP was just sent during signup
            startCooldown(seconds: 15)
        }
        .onDisappear {
            cooldownTask?.cancel()
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: $auth.showErrorAlert) {
            Button("OK", role: .cancel) {
                // After acknowledging error, clear and refocus
                clearAllOTP()
                focusedField = .d1
            }
        } message: {
            Text(auth.errorMessage ?? "Couldn't verify")
        }
    }

    // MARK: - Verify
    private func performVerify() async {
        guard canVerify else { return }
        await auth.verify(email: email, otp: otp)
        // If verify failed, AuthStore sets errorMessage/showErrorAlert. We clear on alert dismiss.
    }

    // MARK: - Resend (signup, otpPurpose = 0)
    private func resendSignupOtp() async {
        guard canResendOtp, !auth.isLoading else { return }
        await auth.resendSignupOtp(email: email)
        if auth.errorMessage == nil {
            startCooldown(seconds: 15)
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

    // MARK: - OTP Box
    @ViewBuilder
    private func otpBox(text: Binding<String>, tag: Field, next: Field?, prev: Field?) -> some View {
        OTPDigitField(
            text: Binding(
                get: { String(text.wrappedValue.prefix(1)) },
                set: { newValue in
                    let digits = newValue.filter { $0.isNumber }

                    // Handle paste of multiple digits
                    if digits.count > 1 {
                        distributePastedDigits(digits)
                        return
                    }

                    // Single digit typing
                    text.wrappedValue = String(digits.prefix(1))

                    if !digits.isEmpty {
                        if let next {
                            focusedField = next
                        } else {
                            // Last box filled, hide keyboard
                            #if os(iOS)
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            #endif
                        }
                    }
                }
            ),
            onDeleteBackward: {
                // If current is empty, move focus back and clear previous
                if text.wrappedValue.isEmpty, let prev {
                    switch prev {
                    case .d1: d1 = ""
                    case .d2: d2 = ""
                    case .d3: d3 = ""
                    case .d4: d4 = ""
                    }
                    focusedField = prev
                } else {
                    // If current had a digit, delete it
                    text.wrappedValue = ""
                }
            }
        )
        .keyboardType(.numberPad)
        .textContentType(.oneTimeCode)
        .multilineTextAlignment(.center)
        .frame(width: 52, height: 52)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(focusedField == tag ? Color.blue.opacity(0.6) : Color.black.opacity(0.08), lineWidth: 1)
        )
        .font(.title2.weight(.semibold))
        .focused($focusedField, equals: tag)
    }

    // Distribute pasted digits across the four boxes
    private func distributePastedDigits(_ digits: String) {
        let chars = Array(digits.filter { $0.isNumber }.prefix(4))
        d1 = chars.count > 0 ? String(chars[0]) : ""
        d2 = chars.count > 1 ? String(chars[1]) : ""
        d3 = chars.count > 2 ? String(chars[2]) : ""
        d4 = chars.count > 3 ? String(chars[3]) : ""

        // Move focus to next empty or resign if all filled
        if d1.isEmpty { focusedField = .d1 }
        else if d2.isEmpty { focusedField = .d2 }
        else if d3.isEmpty { focusedField = .d3 }
        else {
            focusedField = nil
            #if os(iOS)
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            #endif
        }
    }

    private func clearAllOTP() {
        d1 = ""; d2 = ""; d3 = ""; d4 = ""
    }
}

// MARK: - UIKit-backed single-digit field to intercept backspace

private struct OTPDigitField: UIViewRepresentable {
    final class BackspaceTextField: UITextField {
        var onDeleteBackward: (() -> Void)?

        override func deleteBackward() {
            // If empty when backspace pressed, notify
            if text?.isEmpty ?? true {
                onDeleteBackward?()
            } else {
                super.deleteBackward()
            }
        }
    }

    @Binding var text: String
    var onDeleteBackward: () -> Void

    func makeUIView(context: Context) -> BackspaceTextField {
        let tf = BackspaceTextField()
        tf.keyboardType = .numberPad
        tf.textAlignment = .center
        tf.font = UIFont.preferredFont(forTextStyle: .title3).withSize(20).bold()
        tf.addTarget(context.coordinator, action: #selector(Coordinator.textChanged(_:)), for: .editingChanged)
        tf.onDeleteBackward = { onDeleteBackward() }
        tf.autocorrectionType = .no
        tf.textContentType = .oneTimeCode
        return tf
    }

    func updateUIView(_ uiView: BackspaceTextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        @objc func textChanged(_ sender: UITextField) {
            // Filter to one digit
            let digits = (sender.text ?? "").filter { $0.isNumber }
            let one = String(digits.prefix(1))
            if sender.text != one {
                sender.text = one
            }
            text = one
        }
    }
}

private extension UIFont {
    func bold() -> UIFont {
        let desc = fontDescriptor.withSymbolicTraits(.traitBold) ?? fontDescriptor
        return UIFont(descriptor: desc, size: pointSize)
    }
}

#Preview {
    NavigationStack {
        SignupConfirmView(email: "you@example.com")
            .environmentObject(AuthStore())
    }
}
