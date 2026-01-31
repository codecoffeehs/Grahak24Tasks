import SwiftUI

struct CategoryView: View {
    @State private var addCategoryOpen = false
    @State private var selectedCategoryForDeletion: CategoryModel?
    @State private var showDeleteAlert = false
    @State private var categorySearch = ""

    @EnvironmentObject var categoryStore: CategoryStore
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var taskStore : TaskStore
    
    // MARK: - Helpers

    private var hasCategories: Bool {
        !categoryStore.categories.isEmpty
    }

    // Normalized search term (trimmed, lowercased, diacritics-insensitive)
    private var normalizedSearch: String {
        categorySearch
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
    }

    private func matchesSearch(_ category: CategoryModel) -> Bool {
        // If search is empty, everything matches
        guard !normalizedSearch.isEmpty else { return true }

        let title = category.title
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()

        return title.contains(normalizedSearch)
    }

    private var filteredCategories: [CategoryModel] {
        guard hasCategories else { return [] }
        return categoryStore.categories.filter(matchesSearch)
    }

    var body: some View {
        NavigationStack {
            Group {
                if categoryStore.isLoading {
                    // Keep loading full-screen (rare, short-lived state)
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if !hasCategories {
                    // Truly empty: keep a full-screen empty state
                    ContentUnavailableView(
                        "No Categories Yet",
                        systemImage: "tray",
                        description: Text("Create your first category to start organizing tasks.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    // Keep a List on screen at all times when we have categories
                    List {
                        if filteredCategories.isEmpty && !categorySearch.isEmpty {
                            // Inline empty state to avoid layout reflow
                            Section {
                                EmptyView()
                            } footer: {
                                VStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 28, weight: .regular))
                                        .foregroundStyle(.secondary)
                                    Text("No results found for your search.")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                            }
                        } else {
                            ForEach(filteredCategories, id: \.id) { category in
                                let isOthers = category.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "others"

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
                                // Do not allow swipe actions for "Others"
                                .modifier(ConditionalSwipeActionsModifier(
                                    isEnabled: !isOthers,
                                    onDelete: {
                                        selectedCategoryForDeletion = category
                                        showDeleteAlert = true
                                    }
                                ))
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
            // Simple searchable: always visible, no suggestions
            .searchable(text: $categorySearch, prompt: "Search categories")
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .submitLabel(.search)
            .task {
                if let token = authStore.token {
                    await categoryStore.fetchCategories(token: token)
                }
            }
        }
    }
}

// Small helper to conditionally add swipe actions
private struct ConditionalSwipeActionsModifier: ViewModifier {
    let isEnabled: Bool
    var onDelete: () -> Void

    func body(content: Content) -> some View {
        if isEnabled {
            content.swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete category")
            }
        } else {
            content
        }
    }
}
