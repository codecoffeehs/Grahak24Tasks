import Foundation

struct NetworkHelpers {
    static func authorizedRequest(
        url: URL,
        token: String
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    // Minimal 401 handler. Call this after you get an HTTPURLResponse.
    static func handleUnauthorizedIfNeeded(_ http: HTTPURLResponse) {
        if http.statusCode == 401 {
            Task { @MainActor in
                AuthStore.shared.logout()
            }
        }
    }
}

