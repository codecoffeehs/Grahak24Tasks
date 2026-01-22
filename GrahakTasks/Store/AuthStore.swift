import Foundation
import SwiftUI
import Combine

@MainActor
class AuthStore: ObservableObject {

    // MARK: - Auth State
    @Published var isAuthenticated: Bool = false
    @Published var token: String?

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false

    // MARK: - Keychain
    private let tokenKey = "auth_token"

    // MARK: - Init (Auto login)
    init() {
        if let savedToken = KeychainService.read(key: tokenKey) {
            token = savedToken
            isAuthenticated = true
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthAPI.login(
                email: email,
                password: password
            )

            token = response.token
            KeychainService.save(key: tokenKey, value: response.token)
            KeychainService.save(key: "fullName", value: response.userResponse.fullName)
            withAnimation{
                isAuthenticated = true
            }

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }

    // MARK: - Signup
    func signup(
        fullName: String,
        email: String,
        password: String
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            _ = try await AuthAPI.signup(
                fullName: fullName,
                email: email,
                password: password
            )

//            token = response.token
//            KeychainService.save(key: tokenKey, value: response.token)
//            KeychainService.save(key: "fullName", value: response.userResponse.fullName)
//            withAnimation{
//                isAuthenticated = true
//            }

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }

    // MARK: - Verify (post-signup OTP)
    func verify(email: String, otp: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthAPI.verify(
                email: email,
                otp: otp
            )

            // Persist token and user info
            token = response.token
            KeychainService.save(key: tokenKey, value: response.token)
            KeychainService.save(key: "fullName", value: response.userResponse.fullName)

            withAnimation {
                isAuthenticated = true
            }

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }

    // MARK: - Logout
    func logout() {
        token = nil
        withAnimation{
            isAuthenticated = false
        }

        KeychainService.delete(key: tokenKey)
        KeychainService.delete(key: "fullName")
    }
    
    // MARK: - Send Password Reset OTP
    func sendPasswordResetOtp(email:String) async {
        isLoading = true
        errorMessage = nil
        
        do{
            _ = try await AuthAPI.sendPasswordresetOtp(email: email)
        }catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }
    
    // MARK: - Confirm Password Reset OTP
    func confirmPasswordresetOtp(email:String, otp:String) async {
        isLoading = true
        errorMessage = nil
        
        do{
            _ = try await AuthAPI.confirmPasswordResetOtp(email: email, otp: otp)
        }catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }
    
    // MARK: - Reset Password (final step)
    func resetPassword(email:String, otp:String, newPassword:String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthAPI.resetPassword(email: email, otp: otp, newPassword: newPassword)

            // Persist token and user info
            token = response.token
            KeychainService.save(key: tokenKey, value: response.token)
            KeychainService.save(key: "fullName", value: response.userResponse.fullName)

            withAnimation {
                isAuthenticated = true
            }

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }
}

