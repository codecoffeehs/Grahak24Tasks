import Foundation

struct AuthAPI {

    static let baseURL = "https://api.grahak24.com/auth/taskuserauth"

    // MARK: - Login
    static func login(
        email: String,
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
            email: email,
            password: password
        )

        request.httpBody = try JSONEncoder().encode(body)

        // 4. Network call
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

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

    // MARK: - Signup (no decoding, just success check)
    static func signup(
        fullName: String,
        email: String,
        password: String
    ) async throws {

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
            email: email,
            password: password
        )

        request.httpBody = try JSONEncoder().encode(body)

        // 4. Network call
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        // 6. Handle status codes (no body expected)
        if (200...299).contains(http.statusCode) {
            return
        } else {
            if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                throw ApiError(message: apiError.message)
            } else {
                let raw = String(data: data, encoding: .utf8) ?? "Something went wrong. Please try again."
                throw ApiError(message: raw)
            }
        }
    }
    
    // MARK: - Verify
    static func verify(
        email: String,
        otp: String
    ) async throws -> AuthResponse {

        // 1. URL
        guard let url = URL(string: "\(baseURL)/verify") else {
            throw ApiError(message: "Invalid URL")
        }

        // 2. Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3. Body
        let body = VerifySignupRequest(
            email: email,
            otp: otp
        )

        request.httpBody = try JSONEncoder().encode(body)

        // 4. Network call
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

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
    
    // MARK: - SEND PASSWORD RESET OTP
    static func sendPasswordresetOtp(email:String) async throws{
        // 1. URL
        guard let url = URL(string: "\(baseURL)/send-reset-otp") else {
            throw ApiError(message: "Invalid URL")
        }

        // 2. Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3. Body
        let body: [String: String] = [
            "email": email
        ]

        request.httpBody = try JSONEncoder().encode(body)

        // 4. Network call
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        // 6. Handle status codes
        if http.statusCode == 200 {
            return
        } else {
            if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                throw ApiError(message: apiError.message)
            } else {
                throw ApiError(message: "Something went wrong. Please try again.")
            }
        }
    }
    
    // MARK: - CONFIRM PASSWORD RESET OTP
    static func confirmPasswordResetOtp(email:String,otp:String) async throws {
        // 1. URL
        guard let url = URL(string: "\(baseURL)/confirm-reset-otp") else {
            throw ApiError(message: "Invalid URL")
        }

        // 2. Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3. Body
        let body: [String: String] = [
            "email": email,
            "otp": otp
        ]

        request.httpBody = try JSONEncoder().encode(body)

        // 4. Network call
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        // 6. Handle status codes
        if http.statusCode == 200 {
            return
        } else {
            if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                throw ApiError(message: apiError.message)
            } else {
                throw ApiError(message: "Something went wrong. Please try again.")
            }
        }
    }
    
    // MARK: - RESET PASSWORD
    static func resetPassword(email:String,otp:String,newPassword:String) async throws -> AuthResponse{
        // 1. URL
        guard let url = URL(string: "\(baseURL)/reset") else {
            throw ApiError(message: "Invalid URL")
        }

        // 2. Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3. Body
        let body: [String: String] = [
            "email": email,
            "otp": otp,
            "newPassword":newPassword
        ]

        request.httpBody = try JSONEncoder().encode(body)

        // 4. Network call
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

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
    
    // MARK: - RESEND OTP
    static func resendOtp(email:String,otpPurpose:Int) async throws{
        // 1. URL
        guard let url = URL(string: "\(baseURL)/resend-otp") else {
            throw ApiError(message: "Invalid URL")
        }

        // 2. Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3. Body
        let body = ResendOtpRequest(
            email: email,
            otpPurpose: otpPurpose
        )
        request.httpBody = try JSONEncoder().encode(body)

        // 4. Network call
        let (data, response) = try await URLSession.shared.data(for: request)

        // 5. Validate response
        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        // 6. Handle status codes
        if http.statusCode == 200 {
            return
        } else {
            if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                throw ApiError(message: apiError.message)
            } else {
                throw ApiError(message: "Something went wrong. Please try again.")
            }
        }
    }
}

