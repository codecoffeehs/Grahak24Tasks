import Foundation

struct CategoryApi {

    static let baseURL = "https://api.grahak24.com/tasks/taskcategory"

    // MARK: - Fetch All Categories
    static func fetchCategories(token: String) async throws -> [CategoryModel] {

        guard let url = URL(string: baseURL) else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = HTTPMethod.get.rawValue

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        // ✅ Success
        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([CategoryModel].self, from: data)
        }

        // ✅ Failure → backend error message
        if let backendError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: backendError.message)
        }

        let rawMessage = String(data: data, encoding: .utf8) ?? "Failed to fetch categories"
        throw ApiError(message: rawMessage)
    }

    // MARK: - Create Category
    static func createCategory(
        title: String,
        color: String,
        icon: String,
        token: String
    ) async throws -> CategoryModel {

        guard let url = URL(string: "\(baseURL)/create") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "title": title,
            "color": color,
            "icon": icon
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        // ✅ Success
        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode(CategoryModel.self, from: data)
        }

        // ✅ Failure → backend error message
        if let backendError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: backendError.message)
        }

        let rawMessage = String(data: data, encoding: .utf8) ?? "Failed to create category"
        throw ApiError(message: rawMessage)
    }

    // MARK: - Delete Category
    static func deleteCategory(categoryId: String, token: String) async throws {

        guard let url = URL(string: "\(baseURL)/\(categoryId)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = HTTPMethod.delete.rawValue

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        // ✅ Success
        if (200...299).contains(http.statusCode) {
            return
        }

        // ✅ Failure → backend error message
        if let backendError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: backendError.message)
        }

        let rawMessage = String(data: data, encoding: .utf8) ?? "Failed to delete category"
        throw ApiError(message: rawMessage)
    }
}
