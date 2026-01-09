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
                Section {
                    TextField("Category name", text: $title)
                        .textInputAutocapitalization(.sentences)
                } footer: {
                    Text("Give your category a short, clear name.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Color
                Section("Color") {
                    HStack(spacing: 16) {
                        ForEach(CategoryColor.allCases) { color in
                            Circle()
                                .fill(color.color)
                                .frame(width: 28, height: 28)
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
                    .padding(.vertical, 4)
                }

                // MARK: - Icon
                Section("Icon") {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 5),
                        spacing: 16
                    ) {
                        ForEach(icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .foregroundColor(
                                    icon == selectedIcon
                                    ? selectedColor.color
                                    : .secondary
                                )
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(
                                            icon == selectedIcon
                                            ? selectedColor.color.opacity(0.15)
                                            : Color.clear
                                        )
                                )
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // MARK: - Save
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            if let token = auth.token {
                                await categoryStore.createCategory(
                                    title: trimmedTitle,
                                    color: selectedColor.rawValue, // 👈 string ID
                                    icon: selectedIcon,
                                    token: token
                                )
                                dismiss()
                            }
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
