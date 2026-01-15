import SwiftUI
import UIKit

struct AddCategoryView: View {
    @EnvironmentObject var categoryStore: CategoryStore
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) var dismiss

    // MARK: - State
    // Default title set to "Others"
    @State private var title: String = "Others"
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

    // Disallow empty and the literal "none" (case-insensitive)
    private var isTitleValid: Bool {
        guard !trimmedTitle.isEmpty else { return false }
        return trimmedTitle.lowercased() != "none"
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Title
                Section("Title") {
                    TextField("Category name", text: $title)
                        .textInputAutocapitalization(.sentences)

                    if trimmedTitle.lowercased() == "none" {
                        Text("The name “None” is not allowed.")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                // MARK: - Color (Minimal Apple-like)
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categoryColors) { option in
                                let isSelected = option.hex == selectedColor.hex

                                ZStack {
                                    // Hit target 44x44, visually smaller chip inside
                                    Circle()
                                        .fill(.clear)
                                        .frame(width: 44, height: 44)

                                    // Visual chip
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 28, height: 28)
                                        // subtle inner hairline stroke to keep contrast on light/dark colors
                                        .overlay(
                                            Circle()
                                                .stroke(.white.opacity(0.65), lineWidth: 0.5)
                                                .blendMode(.overlay)
                                        )
                                        // selection ring
                                        .overlay(
                                            Circle()
                                                .stroke(isSelected ? option.color : .clear, lineWidth: 2)
                                                .frame(width: 36, height: 36)
                                        )
                                        // soft shadow only when selected for hierarchy
                                        .shadow(color: isSelected ? option.color.opacity(0.25) : .clear, radius: 6, x: 0, y: 3)
                                        .scaleEffect(isSelected ? 1.06 : 1.0)
                                        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isSelected)
                                }
                                .contentShape(Circle())
                                .onTapGesture {
                                    let generator = UISelectionFeedbackGenerator()
                                    generator.selectionChanged()
                                    selectedColor = option
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(Text("Color"))
                                .accessibilityValue(Text(option.hex))
                                .accessibilityAddTraits(isSelected ? .isSelected : [])
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 2)
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
                                    color: selectedColor.hex,   // send HEX to backend
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
