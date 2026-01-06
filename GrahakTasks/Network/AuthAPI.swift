import Foundation

struct AuthAPI {

    static let baseURL = "https://api.grahak24.com/auth/taskuserauth"

    // MARK: - Login
    static func login(
        username: String,
        password: String
    ) async throws -> AuthResponse {

        // 1. URL
        guard let url = URL(string: "\(baseURL)/login") else {
            throw ApiError(message: "Invalid URL")
        }

        // 2. Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3. Body
        let body = LoginRequest(
            username: username,
            password: password
        )

        request.httpBody = try JSONEncoder().encode(body)

        // 4. Network call
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        // 6. Handle status codes
        if http.statusCode == 200 {
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        } else {
            if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                throw ApiError(message: apiError.message)
            } else {
                throw ApiError(message: "Something went wrong. Please try again.")
            }
        }
    }

    // MARK: - Signup
    static func signup(
        fullName: String,
        username: String,
        password: String
    ) async throws -> AuthResponse {

        // 1. URL
        guard let url = URL(string: "\(baseURL)/signup") else {
            throw ApiError(message: "Invalid URL")
        }

        // 2. Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3. Body
        let body = SignupRequest(
            fullName: fullName,
            username: username,
            password: password
        )

        request.httpBody = try JSONEncoder().encode(body)

        // 4. Network call
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        // 6. Handle status codes
        if http.statusCode == 201 || http.statusCode == 200 {
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        } else {
            if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                throw ApiError(message: apiError.message)
            } else {
                throw ApiError(message: "Something went wrong. Please try again.")
            }
        }
    }
}
