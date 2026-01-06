import Foundation

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct SignupRequest: Codable {
    let fullName: String
    let username: String
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
