import Foundation

struct FormValid {
    static func isValid(username: String, password: String, isLoading: Bool) -> Bool {
        !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isLoading
    }
}
