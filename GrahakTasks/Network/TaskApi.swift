import Foundation

struct TaskApi {

    static let baseURL = "https://api.grahak24.com/tasks"
    
    // MARK: - Fetch Recent Tasks
    static func fetchRecentTasks(token: String) async throws -> [TaskModel] {
        guard let url = URL(string: "\(baseURL)/task/recent") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if http.statusCode == 200 {
            return try JSONDecoder().decode([TaskModel].self, from: data)
        } else {
            throw ApiError(message: "Failed to fetch tasks")
        }
    }
    
    
    // MARK: - Fetch Tasks
    static func fetchTasks(token: String) async throws -> [TaskModel] {
        guard let url = URL(string: "\(baseURL)/task") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if http.statusCode == 200 {
            return try JSONDecoder().decode([TaskModel].self, from: data)
        } else {
            throw ApiError(message: "Failed to fetch tasks")
        }
    }

    // MARK: - Create Tasks
    static func createTask(
        title: String,
        due: Date,
        categoryId:String,
        token: String
    ) async throws -> TaskModel {

        guard let url = URL(string: "\(baseURL)/task/create") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "POST"

        let body: [String: Any] = [
            "title": title,
            "due": ISO8601DateFormatter().string(from: due),
            "categoryId":categoryId
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if http.statusCode == 201 || http.statusCode == 200 {
            return try JSONDecoder().decode(TaskModel.self, from: data)
        } else {
            throw ApiError(message: "Failed to create task")
        }
    }
    
    // MARK: - Toggle Task
    static func toggleTask(
            taskId: String,
            token: String
    ) async throws -> TaskModel {
        
        guard let url = URL(string: "\(baseURL)/task/toggle/\(taskId)") else {
            throw ApiError(message: "Invalid URL")
        }
        
        var request = NetworkHelpers.authorizedRequest(
            url: url,
            token: token
        )
        request.httpMethod = "PATCH"
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        
        if http.statusCode == 200 {
            return try JSONDecoder().decode(TaskModel.self, from: data)
        } else {
            throw ApiError(message: "Failed to toggle task")
        }
        
    }
    
    // MARK: - Delete Task
        static func deleteTask(
            taskId: String,
            token: String
        ) async throws {

            guard let url = URL(string: "\(baseURL)/task/delete/\(taskId)") else {
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
                throw ApiError(message: "Failed to delete task")
            }
        }
    
}
