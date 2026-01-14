import Foundation

struct TaskApi {

    static let baseURL = "https://api.grahak24.com/tasks"
    
    // MARK: - Fetch Recent Tasks
    static func fetchRecentTasks(token: String) async throws -> RecentTasksResponse {
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
            return try JSONDecoder().decode(RecentTasksResponse.self, from: data)
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

    
    // MARK: - Create Task
    static func createTask(
        title: String,
        due: Date,
        repeatType: RepeatType,
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
            "repeat": repeatType.rawValue,
            "taskCategoryId": categoryId
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
    
    // MARK: - Edit Task
    static func editTask(
        taskId: String,
        title: String? = nil,
        due: Date? = nil,
        isCompleted: Bool? = nil,
        repeatType: RepeatType? = nil,
        taskCategoryId: String? = nil,
        token: String
    ) async throws -> TaskModel {

        guard let url = URL(string: "\(baseURL)/task/edit/\(taskId)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Only include fields that are being changed
        var body: [String: Any] = [:]

        if let title {
            body["title"] = title
        }

        if let due {
            body["due"] = ISO8601DateFormatter().string(from: due)
        }

        if let isCompleted {
            body["isCompleted"] = isCompleted
        }

        if let repeatType {
            body["repeat"] = repeatType.rawValue
        }
        
        if let taskCategoryId {
            body["taskCategoryId"] = taskCategoryId
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if http.statusCode == 200 {
            return try JSONDecoder().decode(TaskModel.self, from: data)
        } else {
            if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
                throw ApiError(message: apiError.message)
            } else {
                let raw = String(data: data, encoding: .utf8) ?? "No error body"
                throw ApiError(message: "Failed to edit task (\(http.statusCode)): \(raw)")
            }
        }
    }
    
    // MARK: - Fetch Today Tasks
    static func fetchTodayTasks(token:String) async throws -> [TaskModel]{
        guard let url = URL(string: "\(baseURL)/task/today") else {
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
    
    // MARK: - Fetch Overdue Tasks
    static func fetchOverdueTasks(token:String) async throws -> [TaskModel]{
        guard let url = URL(string: "\(baseURL)/task/overdue") else {
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
    
    // MARK: - Fetch Upcoming Tasks
    static func fetchUpcomingTasks(token:String) async throws -> [TaskModel]{
        guard let url = URL(string: "\(baseURL)/task/upcoming") else {
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
    // MARK: - Fetch Tasks For Category
    static func fetchTasksForCategory(token: String,categoryId:String) async throws -> [TaskModel] {
        guard let url = URL(string: "\(baseURL)/task/\(categoryId)") else {
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
}

