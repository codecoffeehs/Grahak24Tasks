import SwiftUI

struct CategoryView: View {
    @EnvironmentObject var categoryStore: CategoryStore
    @EnvironmentObject var auth: AuthStore

    @State private var showAddCategorySheet = false

    var body: some View {
        NavigationStack {
            Group {
                if categoryStore.isLoading {
                    ProgressView("Loading categories…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if categoryStore.categories.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)

                        Text("No categories yet")
                            .font(.callout)
                            .foregroundColor(.secondary)

                        Button("Add Category") {
                            showAddCategorySheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    List {
                        ForEach(categoryStore.categories) { category in
                            CategoryRow(category: category)
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        Task {
                                            if let token = auth.token {
                                                await categoryStore.deleteCategory(
                                                    id: category.id,
                                                    token: token
                                                )
                                            }
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddCategorySheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddCategorySheet) {
                AddCategoryView()
            }
        }
        .task {
            if let token = auth.token, categoryStore.categories.isEmpty {
                await categoryStore.fetchCategories(token: token)
            }
        }
        .alert("Error", isPresented: $categoryStore.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(categoryStore.errorMessage ?? "Something went wrong")
        }
    }
}
