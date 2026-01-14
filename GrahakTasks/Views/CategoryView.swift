import SwiftUI

struct CategoryView: View {
    @State private var addCategoryOpen = false

    @EnvironmentObject var categoryStore: CategoryStore
    @EnvironmentObject var authStore: AuthStore

    var body: some View {
        NavigationStack {
            Group {
                if categoryStore.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if categoryStore.categories.isEmpty {
                    ContentUnavailableView(
                        "No Categories Yet",
                        systemImage: "tray",
                        description: Text("Create your first category to start organizing tasks.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    List {
                        ForEach(categoryStore.categories, id: \.id) { category in
                            NavigationLink {
                                CategoryTasksView(categoryId: category.id, categoryTitle: category.title)
                            } label: {
                                CategoryRow(
                                    title: category.title,
                                    icon: category.icon,
                                    colorHex: category.color,
                                    totalTasks: category.tasksCount
                                )
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addCategoryOpen = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Error", isPresented: $categoryStore.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(categoryStore.errorMessage ?? "Something went wrong")
            }
            .sheet(isPresented: $addCategoryOpen) {
                AddCategoryView()
            }
            .task {
                if let token = authStore.token {
                    await categoryStore.fetchCategories(token: token)
                }
            }
        }
    }
}
