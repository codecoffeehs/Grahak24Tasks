import SwiftUI

struct CategoryView: View {
    @State private var addCategoryOpen = false
    @State private var selectedCategoryForDeletion: CategoryModel?
    @State private var showDeleteAlert = false
    @State private var categorySearch = ""
    @EnvironmentObject var categoryStore: CategoryStore
    @EnvironmentObject var authStore: AuthStore

    private var hasCategories: Bool {
        !categoryStore.categories.isEmpty
    }

    private var filteredCategories: [CategoryModel] {
        let search = categorySearch.trimmingCharacters(in: .whitespacesAndNewlines)
        guard hasCategories else { return [] }
        guard !search.isEmpty else { return categoryStore.categories }

        return categoryStore.categories.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if categoryStore.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if !hasCategories {
                    // No categories at all
                    ContentUnavailableView(
                        "No Categories Yet",
                        systemImage: "tray",
                        description: Text("Create your first category to start organizing tasks.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if filteredCategories.isEmpty && !categorySearch.isEmpty {
                    // We have categories, but search returned no matches
                    ContentUnavailableView(
                        "No Results",
                        systemImage: "magnifyingglass",
                        description: Text("No results found for your search.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    // We have categories, and either not searching or we have matches
                    List {
                        ForEach(filteredCategories, id: \.id) { category in
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
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    selectedCategoryForDeletion = category
                                    showDeleteAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .accessibilityLabel("Delete category")
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
            .alert("Delete Category?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    selectedCategoryForDeletion = nil
                }
                Button("Delete", role: .destructive) {
                    guard let category = selectedCategoryForDeletion,
                          let token = authStore.token else {
                        selectedCategoryForDeletion = nil
                        return
                    }
                    // Close the alert first
                    showDeleteAlert = false

                    Task {
                        await categoryStore.deleteCategory(categoryId: category.id, token: token)
                        await categoryStore.fetchCategories(token: token)
                        await MainActor.run {
                            selectedCategoryForDeletion = nil
                        }
                    }
                }
            } message: {
                if let category = selectedCategoryForDeletion {
                    Text("“\(category.title)” and all tasks within this category will be permanently deleted. This action cannot be undone.")
                } else {
                    Text("This action cannot be undone.")
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
            // Only show the search bar when we actually have categories
            .modifier(ConditionalSearchModifier(
                isEnabled: hasCategories,
                text: $categorySearch,
                prompt: "Search for a category"
            ))
            .task {
                if let token = authStore.token {
                    await categoryStore.fetchCategories(token: token)
                }
            }
        }
    }
}

// Small helper to conditionally apply .searchable
private struct ConditionalSearchModifier: ViewModifier {
    let isEnabled: Bool
    @Binding var text: String
    let prompt: String

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $text, prompt: prompt)
        } else {
            content
        }
    }
}
