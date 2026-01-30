import SwiftUI

struct SingleTaskView: View {
    let initialTask: TaskModel
    @State private var task: TaskModel

    // Editing
    @State private var isEditing = false
    @State private var newTaskTitle = ""
    @State private var newDescription = ""
    @State private var newDueDate = Date().addingTimeInterval(240)
    @State private var newRepeatOption: RepeatType = .none
    @State private var newCategoryId: String = ""
    @State private var setReminder = false
    @State private var notificationsAllowed = true

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
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var categoryStore: CategoryStore
    @Environment(\.dismiss) private var dismiss

    init(task: TaskModel) {
        self.initialTask = task
        self._task = State(initialValue: task)
    }

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

    private var minimumLeadTime: TimeInterval { 180 } // 3 minutes

    private var isDueValid: Bool {
        newDueDate.timeIntervalSinceNow > minimumLeadTime
    }

    private var canSave: Bool {
        guard isEditing else { return false }
        let hasTitle = !newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasRealCategory = !newCategoryId.isEmpty && newCategoryId != "__placeholder__"
        guard hasTitle, hasRealCategory, !taskStore.isLoading else { return false }

        if setReminder {
            return notificationsAllowed && isDueValid
        } else {
            return true
        }
    }

    var body: some View {
        List {
            if isEditing {
                editingSection()
            } else {
                headerSection()
                detailsSection()
                actionsSection()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(!canSave)
                } else {
                    Button("Edit") {
                        startEditing()
                    }
                }
            }
            
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
            }
        }
        .onAppear {
            checkNotificationPermission()
            fetchCategoriesIfNeeded()
        }

        // Share Sheet (with search requirement and debounce)
        .sheet(isPresented: $showShareSheet, onDismiss: {
            searchTask?.cancel()
            searchTask = nil
            searchTerm = ""
        }) {
            NavigationStack {
                Group {
                    if searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
                        ContentUnavailableView(
                            "Search to Share",
                            systemImage: "magnifyingglass",
                            description: Text("Type at least 3 characters to search for a user.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        if collabStore.isLoading && collabStore.taskUsers.isEmpty {
                            ProgressView("Searching…")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if !collabStore.taskUsers.isEmpty {
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
                                        .buttonStyle(.plain)
                                        .disabled(isSharing)
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                        } else {
                            // Treat errors as empty state for search to avoid jarring UX
                            ContentUnavailableView(
                                "No users found",
                                systemImage: "person.crop.circle.badge.exclam",
                                description: Text("Try a different name or email.")
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .onChange(of: searchTerm) { _, newValue in
                    let term = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                    searchTask?.cancel()

                    // Reset state immediately for new term
                    collabStore.taskUsers = []
                    collabStore.errorMessage = nil
                    collabStore.isLoading = false

                    if term.count < 3 {
                        return
                    }

                    searchTask = Task { [weak auth] in
                        try? await Task.sleep(nanoseconds: 400_000_000)
                        guard !Task.isCancelled else { return }
                        guard let token = auth?.token else { return }
                        await collabStore.searchTaskUsers(token: token, search: term)
                    }
                }
            }
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
                    await taskStore.deleteTask(id: task.id, token: token)
                    dismiss()
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

    // MARK: - Editing Section

    @ViewBuilder
    private func editingSection() -> some View {
        // Title
        Section {
            TextField("Title", text: $newTaskTitle)
                .textInputAutocapitalization(.sentences)
        }

        // Description
        Section("Description") {
            TextEditor(text: $newDescription)
                .frame(minHeight: 80)
                .lineLimit(6)
                .padding(.vertical, 2)
        }

        // Category
        Section {
            if !categoryStore.categories.isEmpty {
                Picker("Category", selection: $newCategoryId) {
                    ForEach(categoryStore.categories, id: \.id) { category in
                        Text(category.title)
                            .tag(category.id)
                    }
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Loading categories…")
                        .foregroundStyle(.secondary)
                }
            }
        }

        // Reminder Toggle
        Section {
            Toggle(isOn: $setReminder) {
                Label("Set Reminder", systemImage: "bell.badge")
            }
            .onChange(of: setReminder) { _, newValue in
                if newValue && !notificationsAllowed {
                    setReminder = false
                }
            }
        } footer: {
            if !notificationsAllowed {
                Text("Enable notifications in Settings to set reminders for tasks.")
                    .foregroundStyle(.red)
            } else {
                Text("Turn this on to choose a date and time and optional repeat.")
            }
        }

        // Due Date & Time (only when reminder is ON)
        if setReminder {
            dueDateSection()
            repeatSection()
        }
    }

    @ViewBuilder
    private func dueDateSection() -> some View {
        Section {
            DatePicker(
                "Due Date",
                selection: $newDueDate,
                in: Date().addingTimeInterval(minimumLeadTime)...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .disabled(!notificationsAllowed)
            
            if notificationsAllowed && !isDueValid {
                Text("Pick a time at least 3 minutes from now.")
                    .foregroundStyle(.red)
            }
        } footer: {
            if !notificationsAllowed {
                Text("Enable notifications to set reminders for tasks.")
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private func repeatSection() -> some View {
        Section {
            Picker("Repeat", selection: $newRepeatOption) {
                ForEach(RepeatType.allCases) { option in
                    Text(option.title)
                        .tag(option)
                }
            }
            .disabled(!notificationsAllowed)
        } footer: {
            if !notificationsAllowed {
                Text("Repeating tasks require notification permissions.")
                    .foregroundStyle(.red)
            } else {
                Text("Choose how often this reminder should repeat.")
            }
        }
    }

    // MARK: - View Mode Sections

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
                    Text(task.title)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted, color: .secondary.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)

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
        // Description section (if non-empty)
        if !task.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Section("Description") {
                Text(task.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private func actionsSection() -> some View {
        Section("Actions") {
            Button {
                showShareSheet = true
                shareMessage = nil
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

    // MARK: - Helper Functions

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAllowed = settings.authorizationStatus == .authorized
                if !notificationsAllowed {
                    setReminder = false
                }
            }
        }
    }

    private func fetchCategoriesIfNeeded() {
        Task {
            guard categoryStore.categories.isEmpty, let token = auth.token else { return }
            await categoryStore.fetchCategories(token: token)
        }
    }

    private func startEditing() {
        newTaskTitle = task.title
        newDescription = task.description
        newCategoryId = task.categoryId
        newRepeatOption = task.repeatType ?? .none

        // If task has a due date, enable reminder and parse it
        if let dueString = task.due,
           let parsedDate = ISO8601DateFormatter().date(from: dueString) {
            setReminder = true
            newDueDate = parsedDate
        } else {
            setReminder = false
            newDueDate = Date().addingTimeInterval(180)
        }

        isEditing = true
    }

    private func saveTask() {
        Task {
            guard let token = auth.token else {
                localErrorMessage = "You must be logged in."
                showLocalErrorAlert = true
                return
            }

            let finalDue: Date? = (setReminder && notificationsAllowed) ? newDueDate : nil
            let finalRepeat: RepeatType? = (setReminder && notificationsAllowed) ? newRepeatOption : nil

            do {
                // ✅ Call editTask and get the updated task back
                let updatedTask = try await taskStore.editTask(
                    taskId: task.id,
                    title: newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: newDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    due: finalDue,
                    isCompleted: nil,
                    repeatType: finalRepeat,
                    taskCategoryId: newCategoryId,
                    token: token
                )

                // 🔔 Update local notifications based on edited values
                if updatedTask.isCompleted || updatedTask.due == nil {
                    // Cancel if completed or due removed
                    NotificationManager.shared.cancelTaskNotification(id: updatedTask.id)
                } else if let iso = updatedTask.due,
                          let dueDate = ISO8601DateFormatter().date(from: iso) {
                    // Reschedule using updated title and due
                    NotificationManager.shared.scheduleTaskNotification(
                        id: updatedTask.id,
                        title: updatedTask.title,
                        dueDate: dueDate
                    )
                }

                // ✅ Update local task with fresh data from API
                task = updatedTask
                isEditing = false
            } catch {
                // Handle error
                localErrorMessage = error.localizedDescription
                showLocalErrorAlert = true
            }
        }
    }

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
