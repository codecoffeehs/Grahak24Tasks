import SwiftUI

struct SingleTaskView: View {
    let task: TaskModel

    // Editing
    @State private var isEditing = false
    @State private var newTaskTitle = ""

    // Share (simplified: pick a user from taskUsers)
    @State private var showShareSheet = false
    @State private var isSharing = false
    @State private var shareMessage: String?
    @State private var showShareAlert = false

    // Search for share
    @State private var searchTerm: String = ""
    @State private var searchTask: Task<Void, Never>?

    // Delete
    @State private var showDeleteConfirm = false
    @State private var localErrorMessage: String?
    @State private var showLocalErrorAlert = false

    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var collabStore: CollabStore
    @Environment(\.dismiss) private var dismiss

    private var categoryColor: Color {
        Color(hex: task.color)
    }

    private var repeatColor: Color {
        switch task.repeatType ?? .none {
        case .none: return .secondary
        case .daily: return .blue
        case .everyOtherDay: return .purple
        case .weekly: return .green
        case .monthly: return .orange
        }
    }

    private var dueText: String {
        guard let dueString = task.due else {
            return "None"
        }
        if let result = DateParser.parseDueDate(from: dueString) {
            return result.text
        }
        return dueString
    }

    private var dueColor: Color {
        guard let dueString = task.due else {
            return .secondary
        }
        if let result = DateParser.parseDueDate(from: dueString) {
            return result.isOverdue ? .red : .secondary
        }
        return .secondary
    }

    var body: some View {
        List {
            headerSection()
            detailsSection()
            actionsSection()
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if isEditing {
                        isEditing = false
                    } else {
                        newTaskTitle = task.title
                        isEditing = true
                    }
                } label: {
                    Text(isEditing ? "Done" : "Edit")
                }
            }
        }
        .onDisappear { isEditing = false }

        // Share Sheet (with search requirement and debounce)
        .sheet(isPresented: $showShareSheet, onDismiss: {
            // Reset search on close
            searchTask?.cancel()
            searchTask = nil
            searchTerm = ""
        }) {
            NavigationStack {
                Group {
                    if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
                        // Guidance until user types at least 3 characters
                        ContentUnavailableView(
                            "Search to Share",
                            systemImage: "magnifyingglass",
                            description: Text("Type at least 3 characters to search for a user.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Show loading, error, empty or results based on store state
                        if collabStore.isLoading && collabStore.taskUsers.isEmpty {
                            ProgressView("Searching…")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let err = collabStore.errorMessage {
                            ContentUnavailableView(
                                "Error Occured",
                                systemImage: "exclamationmark.triangle",
                                description: Text(err)
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if collabStore.taskUsers.isEmpty {
                            ContentUnavailableView(
                                "No users found",
                                systemImage: "person.crop.circle.badge.exclam",
                                description: Text("Try a different name or email.")
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                Section("Tap to share with") {
                                    ForEach(collabStore.taskUsers) { user in
                                        Button {
                                            shareNow(selectedUser: user)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(user.fullName)
                                                        .font(.body.weight(.semibold))
                                                    Text(user.email)
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                if isSharing {
                                                    ProgressView()
                                                } else {
                                                    Image(systemName: "square.and.arrow.up")
                                                        .foregroundStyle(.blue)
                                                }
                                            }
                                        }
                                        .disabled(isSharing)
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                }
                .navigationTitle("Share Task")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { showShareSheet = false }
                    }
                }
                // Debounced search trigger
                .onChange(of: searchTerm) { _, newValue in
                    let term = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    // Cancel prior debounce task
                    searchTask?.cancel()

                    // If fewer than 3 chars, clear results and stop
                    if term.count < 3 {
                        collabStore.taskUsers = []
                        collabStore.errorMessage = nil
                        collabStore.isLoading = false
                        return
                    }

                    // Debounce
                    searchTask = Task { [weak auth] in
                        // 400ms debounce
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        guard !Task.isCancelled else { return }
                        guard let token = auth?.token else { return }
                        await collabStore.searchTaskUsers(token: token, search: term)
                    }
                }
            }
            // Use platform search UI
            .searchable(text: $searchTerm, prompt: "Search by name or email")
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .presentationDetents([.medium, .large])
            .alert("Share", isPresented: $showShareAlert) {
                Button("OK", role: .cancel) {
                    if shareMessage == "Task shared" {
                        showShareSheet = false
                    }
                }
            } message: {
                Text(shareMessage ?? "")
            }
        }

        // Delete confirmation
        .alert("Delete Task?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    guard let token = auth.token else {
                        localErrorMessage = "You must be logged in to delete a task."
                        showLocalErrorAlert = true
                        return
                    }
                    do {
                        try await TaskApi.deleteTask(taskId: task.id, token: token)
                        dismiss()
                    } catch {
                        localErrorMessage = error.localizedDescription
                        showLocalErrorAlert = true
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }

        // Local error alert
        .alert("Error", isPresented: $showLocalErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(localErrorMessage ?? "Something went wrong")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func headerSection() -> some View {
        Section {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(categoryColor.opacity(0.18))
                    .frame(width: 46, height: 46)
                    .overlay(
                        Image(systemName: task.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(categoryColor)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    if isEditing {
                        TextField("Task title", text: $newTaskTitle)
                            .font(.title3.weight(.semibold))
                    } else {
                        Text(task.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)
                            .strikethrough(task.isCompleted, color: .secondary.opacity(0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 8) {
                        Chip(text: task.categoryTitle, color: categoryColor)
                        if task.isCompleted {
                            Chip(text: "Completed", color: .green)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private func detailsSection() -> some View {
        Section("Details") {
            detailRow(icon: "calendar", title: "Due", value: dueText, valueColor: dueColor)
            detailRow(icon: "arrow.clockwise", title: "Repeat", value: (task.repeatType ?? .none).shortTitle, valueColor: repeatColor)
            detailRow(icon: task.icon, title: "Category", value: task.categoryTitle, valueColor: categoryColor)
        }
    }

    @ViewBuilder
    private func actionsSection() -> some View {
        Section("Actions") {
            Button {
                showShareSheet = true
                shareMessage = nil
                // Reset state for a fresh search session
                searchTask?.cancel()
                searchTask = nil
                searchTerm = ""
                collabStore.taskUsers = []
                collabStore.errorMessage = nil
                collabStore.isLoading = false
            } label: {
                Label("Share Task", systemImage: "square.and.arrow.up")
                    .font(.callout.weight(.semibold))
            }

            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete Task", systemImage: "trash")
                    .font(.callout.weight(.semibold))
            }
        }
    }

    // MARK: - Simplified Share

    private func shareNow(selectedUser: TaskUserModel) {
        guard let token = auth.token else {
            shareMessage = "You must be logged in."
            showShareAlert = true
            return
        }

        isSharing = true
        shareMessage = nil

        Task {
            await collabStore.shareTask(token: token, taskId: task.id, sharedWithUserId: selectedUser.id)

            if let error = collabStore.errorMessage {
                shareMessage = error
            } else {
                shareMessage = "Task shared"
            }

            isSharing = false
            showShareAlert = true
        }
    }

    // MARK: - Rows and Helpers

    private func detailRow(icon: String, title: String, value: String, valueColor: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 22)

            Text(title)
                .font(.callout)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Chip

private struct Chip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12), in: Capsule())
    }
}
