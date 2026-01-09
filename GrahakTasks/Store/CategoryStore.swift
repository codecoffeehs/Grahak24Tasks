import Foundation
import Combine

@MainActor
class CategoryStore: ObservableObject {

    // MARK: - State
    @Published var categories: [CategoryModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false

    // MARK: - Fetch (called once or rarely)
    func fetchCategories(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await CategoryAPI.fetchCategories(token: token)
            categories = response.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }

    // MARK: - Create
    func createCategory(
        title: String,
        color: String,
        icon: String,
        token: String
    ) async {

        errorMessage = nil

        do {
            let newCategory = try await CategoryAPI.createCategory(
                title: title,
                color: color,
                icon: icon,
                token: token
            )

            categories.append(newCategory)
            

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    // MARK: - Update
    func updateCategory(
        id: String,
        title: String,
        color: String,
        icon: String,
        token: String
    ) async {

        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }

        do {
            let updated = try await CategoryAPI.updateCategory(
                id: id,
                title: title,
                color: color,
                icon: icon,
                token: token
            )

            categories[index] = updated
            

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    // MARK: - Delete (Optimistic)
    func deleteCategory(
        id: String,
        token: String
    ) async {

        guard let index = categories.firstIndex(where: { $0.id == id }) else { return }
        let deleted = categories[index]

        categories.remove(at: index)

        do {
            try await CategoryAPI.deleteCategory(
                id: id,
                token: token
            )
        } catch {
            categories.insert(deleted, at: index)
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

   
}

