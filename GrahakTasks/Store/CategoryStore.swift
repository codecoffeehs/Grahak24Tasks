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
    
    // MARK: - Create Categories
    func createCategory(title:String,color:String,icon:String,token:String) async{
        isLoading = true
        errorMessage = nil
        
        do{
            let newCategory = try await CategoryApi.createCategory(
                            title: title,
                            color: color,
                            icon: icon,
                            token: token
                        )

                        categories.append(newCategory)
            
        }catch{
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
        isLoading = false
    }
    
    // MARK: - DELETE CATEGORY
    func deleteCategory(categoryId:String,token:String) async{
        do {
            try await CategoryApi.deleteCategory(categoryId: categoryId, token: token)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
