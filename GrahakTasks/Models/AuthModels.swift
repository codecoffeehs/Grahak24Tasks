import Foundation

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct SignupRequest: Codable {
    let fullName: String
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let token: String
    let userResponse: UserResponse
}

struct UserResponse : Codable {
    let userId : String
    let initials : String
    let fullName : String
}
