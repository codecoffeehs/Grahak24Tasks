import Foundation
import Combine

@MainActor
class CollabStore : ObservableObject{
    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    
    @Published var taskUsers : [TaskUserModel] = []
    @Published var sharedTasks : [SharedTaskModel] = []
    @Published var taskRequests: [TaskRequests] = []
    
    func searchTaskUsers(token: String,search:String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await CollabApi.searchTaskUsers(token: token, search: search)
            taskUsers = response

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }
    
    func fetchSharedTasks(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await CollabApi.fetchSharedTasks(token: token)
            sharedTasks = response

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }
    
    // Sends invite; success is indicated by lack of error. UI can show its own success message.
    func shareTask(token: String, taskId: String, sharedWithUserId:String) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await CollabApi.sendInviteForTaskCollab(token: token, taskId: taskId, sharedWithUserId: sharedWithUserId)
            // On success: no state change needed; UI can present its own success message.
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    func fetchTaskRequest(token:String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await CollabApi.fetchTaskRequests(token: token)
            taskRequests = response
        }
        catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }
    
    // MARK: - Accept Invite + Create Task (returns created TaskModel)
    func acceptInviteAndCreateTask(
        token: String,
        inviteId: String,
        title: String,
        due: Date?,
        repeatType: RepeatType?,
        categoryId: String
    ) async -> TaskModel? {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let created = try await CollabApi.acceptInviteAndCreateTask(
                inviteId: inviteId,
                title: title,
                due: due,
                repeatType: repeatType,
                categoryId: categoryId,
                token: token
            )
            return created
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
            return nil
        }
    }
    
    // MARK: - Accept Invite + Create Task (fire-and-forget convenience)
    func acceptInvite(
        token: String,
        inviteId: String,
        title: String,
        due: Date?,
        repeatType: RepeatType?,
        categoryId: String
    ) async {
        _ = await acceptInviteAndCreateTask(
            token: token,
            inviteId: inviteId,
            title: title,
            due: due,
            repeatType: repeatType,
            categoryId: categoryId
        )
    }
}

