import Foundation

struct CategoryAPI {

    private static let baseURL = "https://api.grahak24.com/tasks/taskcategory"

    // MARK: - Fetch All Categories
    static func fetchCategories(token: String) async throws -> [CategoryModel] {
        guard let url = URL(string: baseURL) else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(
            url: url,
            token: token
        )
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw ApiError(message: "Failed to fetch categories")
        }

        return try JSONDecoder().decode([CategoryModel].self, from: data)
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

        var request = NetworkHelpers.authorizedRequest(
            url: url,
            token: token
        )
        request.httpMethod = "POST"

        let body: [String: Any] = [
            "title": title,
            "color": color,
            "icon": icon
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 || http.statusCode == 201 else {
            throw ApiError(message: "Failed to create category")
        }

        return try JSONDecoder().decode(CategoryModel.self, from: data)
    }

    // MARK: - Update Category
    static func updateCategory(
        id: String,
        title: String,
        color: String,
        icon: String,
        token: String
    ) async throws -> CategoryModel {

        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(
            url: url,
            token: token
        )
        request.httpMethod = "PUT"

        let body: [String: Any] = [
            "title": title,
            "color": color,
            "icon": icon
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else {
            throw ApiError(message: "Failed to update category")
        }

        return try JSONDecoder().decode(CategoryModel.self, from: data)
    }

    // MARK: - Delete Category
    static func deleteCategory(
        id: String,
        token: String
    ) async throws {

        guard let url = URL(string: "\(baseURL)/\(id)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(
            url: url,
            token: token
        )
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 || http.statusCode == 204 else {
            throw ApiError(message: "Failed to delete category")
        }
    }
}
