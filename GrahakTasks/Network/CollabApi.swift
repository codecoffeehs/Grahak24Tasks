import Foundation

struct CollabApi{
    
    static let baseURL = "https://api.grahak24.com/userinsights/taskuser"
    
//    static func fetchSharedTasks(token : String) async throws {
//        guard let url = URL(string: "\(baseURL)/shared") else {
//            throw ApiError(message: "Invalid URL")
//        }
//
//        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
//        request.httpMethod = "GET"
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//
//        guard let http = response as? HTTPURLResponse else {
//            throw ApiError(message: "Invalid server response")
//        }
//
//        if (200...299).contains(http.statusCode) {
//            return try JSONDecoder().decode(RecentTasksResponse.self, from: data)
//        }
//
//        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
//            throw ApiError(message: apiError.message)
//        }
//
//        let raw = String(data: data, encoding: .utf8) ?? "Failed to fetch recent tasks"
//        throw ApiError(message: raw)
//    }
    static func searchTaskUsers(token: String, search: String) async throws -> [TaskUserModel] {

        guard var components = URLComponents(string: baseURL) else {
            throw ApiError(message: "Invalid URL")
        }

        // Add query param here
        components.queryItems = [
            URLQueryItem(name: "searchTerm", value: search)
        ]

        guard let url = components.url else {
            throw ApiError(message: "Invalid URL with query")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([TaskUserModel].self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to fetch users"
        throw ApiError(message: raw)
    }

    
}
