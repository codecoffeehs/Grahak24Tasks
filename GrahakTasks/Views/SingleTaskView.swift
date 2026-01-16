import SwiftUI

struct SingleTaskView: View {
    let task: TaskModel
    @State private var isEditing = false
    @State private var newTaskTitle = ""
    @State private var showCollaboratorSheet = false
    @State private var searchText = ""
    
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var collabStore: CollabStore
    
    @State private var lastSearchFiredAt: Date = .distantPast
    private let searchDebounceInterval: TimeInterval = 0.35
    
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
        // Sheet wired to CollabStore with search
        .sheet(isPresented: $showCollaboratorSheet) {
            NavigationStack {
                Group {
                    if collabStore.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if searchText.count >= 3 && collabStore.taskUsers.isEmpty {
                        ContentUnavailableView("No results", systemImage: "person.crop.circle.badge.questionmark", description: Text("Try a different name or email"))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            if searchText.count < 3 {
                                Section {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Start typing to search")
                                            .font(.callout.weight(.semibold))
                                        Text("Enter at least 3 characters to search for collaborators.")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 6)
                                }
                            }
                            
                            if !collabStore.taskUsers.isEmpty {
                                Section("Results") {
                                    ForEach(collabStore.taskUsers) { user in
                                        HStack(spacing: 12) {
                                            avatarView(for: user.fullName)
                                                .frame(width: 36, height: 36)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(user.fullName)
                                                    .font(.callout.weight(.semibold))
                                                Text(user.email)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Button {
                                                // TODO: Hook up invite API when available
                                                // e.g., await CollabApi.inviteUserToTask(taskId: task.id, userId: user.id, token: token)
                                            } label: {
                                                Text("Invite")
                                                    .font(.callout.weight(.semibold))
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(.blue)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                    }
                }
                .navigationTitle("Add Collaborator")
                .navigationBarTitleDisplayMode(.inline)
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search people").textInputAutocapitalization(.never).autocorrectionDisabled(true)
            .onChange(of: searchText) { _, newValue in
                // Debounce and require at least 3 characters
                guard newValue.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
                    // Clear old results when search is too short
                    collabStore.taskUsers = []
                    return
                }
                
                // Simple debounce using timestamp
                let now = Date()
                lastSearchFiredAt = now
                let token = auth.token
                
                Task { [lastSearchFiredAt] in
                    try? await Task.sleep(nanoseconds: UInt64(searchDebounceInterval * 1_000_000_000))
                    // Only fire if no newer change occurred
                    guard now == lastSearchFiredAt else { return }
                    if let token {
                        await collabStore.searchTaskUsers(token: token, search: newValue)
                    }
                }
            }
            .alert("Error", isPresented: $collabStore.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(collabStore.errorMessage ?? "Something went wrong")
            }
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
    
    // MARK: - Avatar from initials
    @ViewBuilder
    private func avatarView(for name: String) -> some View {
        let initials = initialsFromName(name)
        let bg = colorFromString(name)
        ZStack {
            Circle()
                .fill(bg.opacity(0.2))
            Text(initials)
                .font(.caption.weight(.bold))
                .foregroundStyle(bg)
        }
        .accessibilityHidden(true)
    }
    
    private func initialsFromName(_ name: String) -> String {
        let parts = name.split(separator: " ").map { String($0) }
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        } else {
            return "?"
        }
    }
    
    private func colorFromString(_ string: String) -> Color {
        var hasher = Hasher()
        hasher.combine(string)
        let hash = hasher.finalize()
        let r = Double((hash & 0xFF0000) >> 16) / 255.0
        let g = Double((hash & 0x00FF00) >> 8) / 255.0
        let b = Double(hash & 0x0000FF) / 255.0
        return Color(red: abs(r), green: abs(g), blue: abs(b))
    }
}

