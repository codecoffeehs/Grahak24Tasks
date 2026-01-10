import SwiftUI
import UIKit

struct AddCategoryView: View {
    @EnvironmentObject var categoryStore: CategoryStore
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) var dismiss

    // MARK: - State
    @State private var title: String = ""
    @State private var selectedColor: CategoryColor = .blue
    @State private var selectedIcon: String = "folder"

    // MARK: - Icon options
    // MARK: - Icon options (SF Symbols)
    private let icons = [
        // General
        "folder",
        "tag",
        "bookmark",
        "star",
        "flag",
        
        // Work / Productivity
        "briefcase",
        "calendar",
        "checklist",
        "clock",
        "bell",
        
        // Home / Personal
        "house",
        "bed.double",
        "lamp.table",
        "key",
        
        // Health / Fitness
        "heart",
        "cross.case",
        "pills",
        "dumbbell",
        "figure.walk",
        
        // Shopping / Food
        "cart",
        "bag",
        "creditcard",
        "fork.knife",
        "cup.and.saucer",
        
        // Study / Learning
        "book",
        "graduationcap",
        "pencil",
        "doc.text",
        
        // Travel / Outdoor
        "airplane",
        "car",
        "map",
        "camera",
        "sun.max",
        
        // Social / People
        "person",
        "person.2",
        "message",
        "phone",
        
        // Tech / Creative
        "bolt",
        "wifi",
        "laptopcomputer",
        "paintpalette",
        "music.note"
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
                    ScrollView(.horizontal,showsIndicators: false){
                        HStack{
                            ForEach(CategoryColor.allCases){
                                color in
                                Circle()
                                    .fill(color.color)
                                    .frame(width:45,height: 45)
                                    .padding(4)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(
                                                color == selectedColor ? selectedColor.color : Color.clear,
                                                lineWidth: 2
                                            )
                                    )
                                    .onTapGesture {
                                        let generator = UISelectionFeedbackGenerator()
                                                        generator.selectionChanged()
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
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
                            if let token = auth.token {
                                await categoryStore.createCategory(
                                    title: trimmedTitle,
                                    color: selectedColor.rawValue,
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

#Preview{
    AddCategoryView()
        .environmentObject(CategoryStore())
        .environmentObject(AuthStore())
}
