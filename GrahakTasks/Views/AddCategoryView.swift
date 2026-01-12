import SwiftUI
import UIKit

struct AddCategoryView: View {
    @EnvironmentObject var categoryStore: CategoryStore
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) var dismiss

    // MARK: - State
    @State private var title: String = ""
    @State private var selectedColor: CategoryColorOption = categoryColors[1] // default blue
    @State private var selectedIcon: String = "folder"

    // MARK: - Icon options (SF Symbols)
    private let icons = [
        "folder", "tag", "bookmark", "star", "flag",
        "briefcase", "calendar", "checklist", "clock", "bell",
        "house", "bed.double", "lamp.table", "key",
        "heart", "cross.case", "pills", "dumbbell", "figure.walk",
        "cart", "bag", "creditcard", "fork.knife", "cup.and.saucer",
        "book", "graduationcap", "pencil", "doc.text",
        "airplane", "car", "map", "camera", "sun.max",
        "person", "person.2", "message", "phone",
        "bolt", "wifi", "laptopcomputer", "paintpalette", "music.note"
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

                // MARK: - Title
                Section("Title") {
                    TextField("Category name", text: $title)
                        .textInputAutocapitalization(.sentences)
                }

                // MARK: - Color (SELECTABLE)
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 30) {
                            ForEach(categoryColors) { option in
                                ZStack {
                                    if option.hex == selectedColor.hex {
                                        Circle()
                                            .stroke(option.color, lineWidth: 3)
                                            .frame(width: 60, height: 60)
                                    }

                                    // Inner fill circle
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 50, height: 50)
                                }
                                .contentShape(Circle())
                                .onTapGesture {
                                    let generator = UISelectionFeedbackGenerator()
                                    generator.selectionChanged()
                                    selectedColor = option
                                }
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 4)
                    }
                }


                // MARK: - Icon
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(icons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(
                                        selectedIcon == icon ? selectedColor.color : .secondary
                                    )
                                    .frame(width: 44, height: 44)
                                    .background(.ultraThinMaterial, in: Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedIcon == icon ? selectedColor.color : .clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .contentShape(Circle())
                                    .onTapGesture {
                                        let generator = UISelectionFeedbackGenerator()
                                        generator.selectionChanged()
                                        selectedIcon = icon
                                    }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                // MARK: - Preview
                Section("Preview") {
                    CategoryRow(
                        title: trimmedTitle.isEmpty ? "Category" : trimmedTitle,
                        icon: selectedIcon,
                        colorHex: selectedColor.hex,
                        totalTasks: 0
                    )
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // Save
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            if let token = auth.token {
                                await categoryStore.createCategory(
                                    title: trimmedTitle,
                                    color: selectedColor.hex,   // ✅ send HEX to backend
                                    icon: selectedIcon,
                                    token: token
                                )
                                dismiss()
                            }
                        }
                    }
                    .disabled(!isTitleValid || categoryStore.isLoading)
                }

                // Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddCategoryView()
        .environmentObject(CategoryStore())
        .environmentObject(AuthStore())
}
