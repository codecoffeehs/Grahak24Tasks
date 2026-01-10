import SwiftUI

struct AddCategoryView: View {
    @EnvironmentObject var categoryStore: CategoryStore
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) var dismiss

    // MARK: - State
    @State private var title: String = ""
    @State private var selectedColor: CategoryColor = .blue
    @State private var selectedIcon: String = "folder"

    // MARK: - Icon options
    private let icons = [
        "folder",
        "briefcase",
        "house",
        "heart",
        "cart",
        "book",
        "graduationcap",
        "bolt",
        "person.2",
        "star"
    ]

    // MARK: - Validation
    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isTitleValid: Bool {
        !trimmedTitle.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Name
                Section("Title"){
                    TextField("Category name", text: $title)
                        .textInputAutocapitalization(.sentences)
                }
                
                // MARK: - Color
                Section("Color"){
                    HStack{
                        ForEach(CategoryColor.allCases){
                            color in
                            Circle()
                                .fill(color.color)
                                .frame(width:45,height: 45)
                                .overlay(
                                                                    Circle()
                                                                        .strokeBorder(
                                                                            color == selectedColor ? Color.primary : Color.clear,
                                                                            lineWidth: 2
                                                                        )
                                                                )
                                                                .onTapGesture {
                                                                    selectedColor = color
                                                                }
                        }
                    }
                }
                // MARK: - Icon
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(icons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(selectedIcon == icon ? selectedColor.color : .secondary)
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(selectedIcon == icon ? selectedColor.color : .clear, lineWidth: 2)
                                    )
                                    .onTapGesture {
                                        selectedIcon = icon
                                    }
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                    }
                }
                // MARK: - Category Preview
                Section("Preview"){
                    CategoryRow(
                        title: title.isEmpty ? "Category" : title,
                        icon: selectedIcon,
                        color: selectedColor.rawValue,
                        totalTasks: 10
                    )

                }
                
                
                
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // MARK: - Save
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
//                            if let token = auth.token {
////                                await categoryStore.createCategory(
////                                    title: trimmedTitle,
////                                    color: selectedColor.rawValue, // 👈 string ID
////                                    icon: selectedIcon,
////                                    token: token
////                                )
//                                dismiss()
//                            }
                        }
                    }
                    .disabled(!isTitleValid)
                }

                // MARK: - Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview{
    AddCategoryView()
        .environmentObject(CategoryStore())
        .environmentObject(AuthStore())
}
