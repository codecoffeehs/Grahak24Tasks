import SwiftUI

struct SingleTaskView: View {
    let task: TaskModel
    @State private var isEditing = false
    @State private var newTaskTitle = ""
    @State private var showCollaboratorSheet = false
    @State private var searchText = ""
    
    private var categoryColor: Color { Color(hex: task.color) }

    private var repeatColor: Color {
        switch task.repeatType {
        case .none: return .secondary
        case .daily: return .blue
        case .everyOtherDay: return .purple
        case .weekly: return .green
        case .monthly: return .orange
        }
    }

    private var dueText: String {
        if let result = DateParser.parseDueDate(from: task.due) {
            return result.text
        }
        return task.due
    }

    private var dueColor: Color {
        if let result = DateParser.parseDueDate(from: task.due) {
            return result.isOverdue ? .red : .secondary
        }
        return .secondary
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // MARK: - Header Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        if isEditing{
                            TextField("",text:$newTaskTitle)
                        }else{
                            Text(task.title)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(task.isCompleted ? .secondary : .primary)
                                .strikethrough(task.isCompleted, color: .secondary.opacity(0.6))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }

                    if task.isCompleted {
                        Text("Completed")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.green.opacity(0.12), in: Capsule())
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                // MARK: - Details Section
                VStack(alignment: .leading, spacing: 0) {

                    Text("Details")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)

                    VStack(spacing: 0) {
                        detailRow(icon: "calendar", title: "Due", value: dueText, valueColor: dueColor)

                        Divider().padding(.leading, 44)

                        detailRow(icon: "arrow.clockwise", title: "Repeat", value: task.repeatType.shortTitle, valueColor: repeatColor)

                        Divider().padding(.leading, 44)

                        detailRow(icon: task.icon, title: "Category", value: task.categoryTitle, valueColor: categoryColor)
                    }
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                // MARK: - Collaborators Section
                VStack(alignment: .leading, spacing: 0) {
                    Text("Collaborators")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 12) {
                            Image(systemName: "person.2")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 4) {
                                if task.isShared {
                                    let count = task.sharedWithCount
                                    let label = count == 1 ? "collaborator" : "collaborators"
                                    Text("Shared with \(count) \(label)")
                                        .font(.callout.weight(.semibold))
                                        .foregroundStyle(.primary)
                                } else {
                                    Text("Not shared")
                                        .font(.callout.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                }

                                if !task.isShared {
                                    Text("Share this task to collaborate with others.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)

                        // Button to open half-height sheet
                        HStack {
                            Spacer()
                            Button {
                                showCollaboratorSheet = true
                            } label: {
                                Label("Add Collaborator", systemImage: "plus.circle.fill")
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.blue)
                            }
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)
                        }
                    }
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Spacer(minLength: 10)
            }
            .padding(16)
        }
        .toolbar{
            if isEditing{
                ToolbarItem(placement: .topBarLeading){
                    Button("Cancel"){
                        isEditing = false
                    }
                    .foregroundStyle(.red)
                }
            }
            if !isEditing{
                ToolbarItem(placement: .topBarTrailing){
                    Button{
                        isEditing = true
                        newTaskTitle = task.title
                    } label:{
                        Image(systemName: "pencil")              }
                }
            }
        }
        .onDisappear{
            isEditing = false
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(isEditing ? "Editing" : "Task")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        // Sheet with dummy content and a search bar, half-height
        .sheet(isPresented: $showCollaboratorSheet) {
            NavigationStack {
                List {
                    Section("Suggestions") {
                        ForEach(0..<10, id: \.self) { idx in
                            HStack {
                                Image(systemName: "person.crop.circle")
                                    .foregroundStyle(.secondary)
                                Text("Dummy User \(idx + 1)")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Add Collaborator")
                .navigationBarTitleDisplayMode(.inline)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search people")
            .presentationDetents([.medium,.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Simple row (no extra view file)
    private func detailRow(icon: String, title: String, value: String, valueColor: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(title)
                .font(.callout.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
