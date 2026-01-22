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

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode(RecentTasksResponse.self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to fetch recent tasks"
        throw ApiError(message: raw)
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

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([TaskModel].self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to fetch tasks"
        throw ApiError(message: raw)
    }


    // MARK: - Create Task
    static func createTask(
        title: String,
        due: Date?,                 // optional
        repeatType: RepeatType?,    // optional
        categoryId: String,
        token: String
    ) async throws -> TaskModel {

        guard let url = URL(string: "\(baseURL)/task/create") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "title": title,
            "taskCategoryId": categoryId
        ]

        // If your backend expects missing keys instead of null, comment out the NSNull lines
        if let due {
            body["due"] = ISO8601DateFormatter().string(from: due)
        }
            // else {
//            body["due"] = NSNull()
//        }

        if let repeatType {
            body["repeat"] = repeatType.rawValue
      }
//            else {
//            body["repeat"] = NSNull()
//        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode(TaskModel.self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to create task"
        throw ApiError(message: raw)
    }


    // MARK: - Toggle Task
    static func toggleTask(taskId: String, token: String) async throws -> TaskModel {

        guard let url = URL(string: "\(baseURL)/task/toggle/\(taskId)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "PATCH"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode(TaskModel.self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to toggle task"
        throw ApiError(message: raw)
    }


    // MARK: - Delete Task
    static func deleteTask(taskId: String, token: String) async throws {

        guard let url = URL(string: "\(baseURL)/task/delete/\(taskId)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "DELETE"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if (200...299).contains(http.statusCode) {
            return
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to delete task"
        throw ApiError(message: raw)
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
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [:]

        if let title { body["title"] = title }
        if let due { body["due"] = ISO8601DateFormatter().string(from: due) }
        if let isCompleted { body["isCompleted"] = isCompleted }
        if let repeatType { body["repeat"] = repeatType.rawValue }
        if let taskCategoryId { body["taskCategoryId"] = taskCategoryId }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode(TaskModel.self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to edit task"
        throw ApiError(message: raw)
    }


    // MARK: - Fetch Today Tasks
    static func fetchTodayTasks(token: String) async throws -> [TaskModel] {
        guard let url = URL(string: "\(baseURL)/task/today") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([TaskModel].self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to fetch today tasks"
        throw ApiError(message: raw)
    }


    // MARK: - Fetch Overdue Tasks
    static func fetchOverdueTasks(token: String) async throws -> [TaskModel] {
        guard let url = URL(string: "\(baseURL)/task/overdue") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([TaskModel].self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to fetch overdue tasks"
        throw ApiError(message: raw)
    }


    // MARK: - Fetch Upcoming Tasks
    static func fetchUpcomingTasks(token: String) async throws -> [TaskModel] {
        guard let url = URL(string: "\(baseURL)/task/upcoming") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([TaskModel].self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to fetch upcoming tasks"
        throw ApiError(message: raw)
    }

    // MARK: - Fetch NoDue Tasks
    static func fetchNoDueTasks(token: String) async throws -> [TaskModel] {
        guard let url = URL(string: "\(baseURL)/task/nodue") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([TaskModel].self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to fetch overdue tasks"
        throw ApiError(message: raw)
    }

    // MARK: - Fetch Tasks For Category
    static func fetchTasksForCategory(token: String, categoryId: String) async throws -> [TaskModel] {
        guard let url = URL(string: "\(baseURL)/task/\(categoryId)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([TaskModel].self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to fetch category tasks"
        throw ApiError(message: raw)
    }
    
    
}
