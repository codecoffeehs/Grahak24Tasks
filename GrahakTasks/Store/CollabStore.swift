import Foundation
import Combine

@MainActor
class CollabStore : ObservableObject{
    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false
    
    @Published var taskUsers : [TaskUserModel] = []
    
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

}
