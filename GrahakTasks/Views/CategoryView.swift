import SwiftUI

struct CategoryView: View {
    @State private var addCategoryOpen = false
    @EnvironmentObject var categoryStore: CategoryStore

    var body: some View {
        NavigationStack {
            Group {
                if categoryStore.isLoading {
                    ProgressView()
                } else if categoryStore.categories.isEmpty {
                    ContentUnavailableView(
                        "No Categories Yet",
                        systemImage: "tray",
                        description: Text("Create your first category to start organizing tasks.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("Hello")
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
            .sheet(isPresented: $addCategoryOpen) {
                AddCategoryView()
            }
        }
    }
}

