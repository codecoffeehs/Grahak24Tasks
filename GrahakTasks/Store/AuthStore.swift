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
    func login(username: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthAPI.login(
                username: username,
                password: password
            )

            token = response.token
            KeychainService.save(key: tokenKey, value: response.token)
            KeychainService.save(key: "fullName", value: response.userResponse.fullName)
            isAuthenticated = true

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }

    // MARK: - Signup
    func signup(
        fullName: String,
        username: String,
        password: String
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await AuthAPI.signup(
                fullName: fullName,
                username: username,
                password: password
            )

            token = response.token
            KeychainService.save(key: tokenKey, value: response.token)
            KeychainService.save(key: "fullName", value: response.userResponse.fullName)
            isAuthenticated = true

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }

    // MARK: - Logout
    func logout() {
        token = nil
        isAuthenticated = false
        KeychainService.delete(key: tokenKey)
        KeychainService.delete(key: "fullName")
    }
}
