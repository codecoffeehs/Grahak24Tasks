import Foundation

struct CategoryApi{
    
    static let baseURL = "https://api.grahak24.com/tasks/taskcategory"
    
    // MARK: - Fetch All Categories
    static func fetchCategories(token:String) async throws -> [CategoryModel]{
        guard let url = URL(string: baseURL) else{
            throw ApiError(message: "Invalid URL")
        }
        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod  = HTTPMethod.get.rawValue
        let (data,response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse,
              http.statusCode == 200 else{
            throw ApiError(message: "Failed to fetch categories")
        }
        return try JSONDecoder().decode([CategoryModel].self,from: data)
        
     }
    
    // MARK: - Create Category
    static func createCategory( title: String,
                                color: String,
                                icon: String,
                                token: String) async throws -> CategoryModel{
        guard let url = URL(string: "\(baseURL)/create") else {
                    throw ApiError(message: "Invalid URL")
                }
        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod  = HTTPMethod.post.rawValue
        
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

    // MARK: - DELETE CATEGORY
    static func deleteCategory(categoryId:String,token:String) async throws {
        guard let url = URL(string: "\(baseURL)/task/catergory/delete/\(categoryId)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(
            url: url,
            token: token
        )
        request.httpMethod = "DELETE"

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if http.statusCode != 200 && http.statusCode != 204 {
            throw ApiError(message: "Failed to delete category")
        }
    }
}
