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
    func sendInviteForTaskCollab(token: String, taskId: String, invitedUserId: String) async {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await CollabApi.sendInviteForTaskCollab(token: token, taskId: taskId, invitedUserId: invitedUserId)
            // On success: no state change needed; UI can present its own success message.
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

}
