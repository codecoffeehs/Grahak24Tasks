import Foundation

struct CollabApi{
    
    static let baseURL = "https://api.grahak24.com/userinsights/taskuser"
    static let baseURLTwo = "https://api.grahak24.com/tasks/tasksharing"
    
    static func searchTaskUsers(token: String, search: String) async throws -> [TaskUserModel] {

        guard var components = URLComponents(string: baseURL) else {
            throw ApiError(message: "Invalid URL")
        }

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
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([TaskUserModel].self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to fetch users"
        throw ApiError(message: raw)
    }

    static func fetchSharedTasks(token:String) async throws -> [SharedTaskModel]{
        guard let url = URL(string: "\(baseURLTwo)/shared") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = HTTPMethod.get.rawValue

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([SharedTaskModel].self, from: data)
        }

        if let backendError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: backendError.message)
        }

        let rawMessage = String(data: data, encoding: .utf8) ?? "Failed to fetch shared tasks"
        throw ApiError(message: rawMessage)
    }
    
    static func fetchSharedTasksRequest(token:String) async throws -> [SharedTaskModel]{
        guard let url = URL(string: "\(baseURL)/requests") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = HTTPMethod.get.rawValue

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([SharedTaskModel].self, from: data)
        }

        if let backendError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: backendError.message)
        }

        let rawMessage = String(data: data, encoding: .utf8) ?? "Failed to fetch shared tasks"
        throw ApiError(message: rawMessage)
    }
    
    
    static func sendInviteForTaskCollab(token: String, taskId: String, sharedWithUserId: String) async throws {
        guard let url = URL(string: "\(baseURLTwo)/invite/\(taskId)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "sharedWithUserId": sharedWithUserId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        if (200...299).contains(http.statusCode) {
            return
        }

        if let backendError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: backendError.message)
        }

        let rawMessage = String(data: data, encoding: .utf8) ?? "Failed to send invite"
        throw ApiError(message: rawMessage)
    }
    
    // MARK: - Fetch Shared Task Requests
    static func fetchTaskRequests(token: String) async throws -> [TaskRequests] {

        guard let url = URL(string: "\(baseURLTwo)/requests") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = HTTPMethod.get.rawValue

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        // ✅ Success
        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode([TaskRequests].self, from: data)
        }

        // ✅ Failure → backend error message
        if let backendError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: backendError.message)
        }

        let rawMessage = String(data: data, encoding: .utf8) ?? "Failed to fetch requests"
        throw ApiError(message: rawMessage)
    }
    
    // MARK: - Accept Invite and Create Task
    static func acceptInviteAndCreateTask(
        inviteId:String,
        title: String,
        due: Date?,
        repeatType: RepeatType?,
        categoryId: String,
        token: String
    ) async throws -> TaskModel {

        guard let url = URL(string: "\(baseURLTwo)/accept/\(inviteId)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "inviteId":inviteId,
            "title": title,
            "taskCategoryId": categoryId
        ]

        // If your backend expects missing keys instead of null, comment out the NSNull lines
        if let due {
            body["due"] = ISO8601DateFormatter().string(from: due)
        }

        if let repeatType {
            body["repeat"] = repeatType.rawValue
      }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        if (200...299).contains(http.statusCode) {
            return try JSONDecoder().decode(TaskModel.self, from: data)
        }

        if let apiError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: apiError.message)
        }

        let raw = String(data: data, encoding: .utf8) ?? "Failed to create task"
        throw ApiError(message: raw)
    }
    
    static func rejectInvite(inviteId:String,token:String) async throws{
        guard let url = URL(string: "\(baseURLTwo)/reject/\(inviteId)") else {
            throw ApiError(message: "Invalid URL")
        }

        var request = NetworkHelpers.authorizedRequest(url: url, token: token)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw ApiError(message: "Invalid server response")
        }
        NetworkHelpers.handleUnauthorizedIfNeeded(http)

        if (200...299).contains(http.statusCode) {
            return
        }

        if let backendError = try? JSONDecoder().decode(ApiErrorResponse.self, from: data) {
            throw ApiError(message: backendError.message)
        }

        let rawMessage = String(data: data, encoding: .utf8) ?? "Failed to reject invite"
        throw ApiError(message: rawMessage)

    }
}

