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
        // Clear previous error and results for a fresh search pass
        errorMessage = nil

        do {
            let response = try await CollabApi.searchTaskUsers(token: token, search: search)
            taskUsers = response
            // Clear any lingering error from previous attempts
            errorMessage = nil
        } catch {
            // For search UX: don't pop an alert; just record error and clear stale results
            taskUsers = []
            errorMessage = error.localizedDescription
            // Do NOT set showErrorAlert here (typing should not trigger alerts)
            // showErrorAlert = true
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
    

    
    // MARK: - Accept Invite + Create Task (fire-and-forget convenience)
    func acceptInvite(
        token: String,
        inviteId: String
    ) async {
        do {
            try await CollabApi.acceptInvite(
                inviteId: inviteId,
                token: token
            )
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reject Invite (refetch strategy)
    func rejectInvite(token: String, inviteId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await CollabApi.rejectInvite(inviteId: inviteId, token: token)
            // Refresh requests after rejecting
            let refreshed = try await CollabApi.fetchTaskRequests(token: token)
            taskRequests = refreshed
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    // MARK: - Reject Invite (optimistic update strategy)
    func rejectInviteLocally(token: String, inviteId: String) async {
        // Optimistically remove from local list
        let previous = taskRequests
        taskRequests.removeAll { $0.id == inviteId }
        
        do {
            try await CollabApi.rejectInvite(inviteId: inviteId, token: token)
        } catch {
            // Rollback on failure and surface error
            taskRequests = previous
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
