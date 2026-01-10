import Foundation
import Combine

@MainActor
class CategoryStore : ObservableObject{
    @Published var categories:[CategoryModel] = []
    @Published var isLoading:Bool = false
    @Published var errorMessage:String?
    @Published var showErrorAlert: Bool = false
    
    // MARK: - Fetch Categories
    func fetchCategories(token:String) async{
        isLoading = true
        errorMessage = nil
        
        do{
            let response = try await CategoryApi.fetchCategories(token: token)
            categories = response.sorted {
                           $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
        }catch{
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        isLoading = false
    }
}
