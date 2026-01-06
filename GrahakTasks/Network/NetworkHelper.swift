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
}
