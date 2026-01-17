import SwiftUI

struct SingleTaskView: View {
    let task: TaskModel

    // Editing title
    @State private var isEditing = false
    @State private var newTaskTitle = ""

    // Share
    @State private var showShareSheet = false
    @State private var searchText = ""

    // Debounce
    @State private var lastSearchFiredAt: Date = .distantPast
    private let searchDebounceInterval: TimeInterval = 0.35

    // Toast
    @State private var showShareToast = false
    @State private var shareToastText = "Task Shared"

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
        .navigationTitle(isEditing ? "Editing" : "Task")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar { toolbarContent() }
        .onDisappear { isEditing = false }

        // Share Sheet
        .sheet(isPresented: $showShareSheet) {
            shareSheet()
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

        // Toast overlay
        .overlay(alignment: .top) {
            if showShareToast {
                toastView(text: shareToastText)
            }
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    isEditing = false
                }
                .foregroundStyle(.red)
            }
        }

        if !isEditing {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isEditing = true
                    newTaskTitle = task.title
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
    }

    // MARK: - Share Sheet

    @ViewBuilder
    private func shareSheet() -> some View {
        NavigationStack {
            Group {
                if collabStore.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 {
                            Section {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Start typing to search")
                                        .font(.callout.weight(.semibold))
                                    Text("Enter at least 3 characters to search for people.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                        }

                        if !collabStore.taskUsers.isEmpty {
                            Section("Results") {
                                ForEach(collabStore.taskUsers) { user in
                                    shareResultRow(user: user)
                                }
                            }
                        }

                        if searchText.count >= 3 && collabStore.taskUsers.isEmpty && !collabStore.isLoading {
                            Section {
                                ContentUnavailableView(
                                    "No results",
                                    systemImage: "person.crop.circle.badge.questionmark",
                                    description: Text("Try a different name or email")
                                )
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Share Task")
            .navigationBarTitleDisplayMode(.inline)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search people")
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .onChange(of: searchText) { _, newValue in
            handleSearchChange(newValue)
        }
        .alert("Error", isPresented: $collabStore.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(collabStore.errorMessage ?? "Something went wrong")
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func handleSearchChange(_ newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else {
            collabStore.taskUsers = []
            return
        }

        let now = Date()
        lastSearchFiredAt = now
        let token = auth.token

        Task { [lastSearchFiredAt] in
            try? await Task.sleep(nanoseconds: UInt64(searchDebounceInterval * 1_000_000_000))
            guard now == lastSearchFiredAt else { return }
            if let token {
                await collabStore.searchTaskUsers(token: token, search: trimmed)
            }
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

    private func shareResultRow(user: TaskUserModel) -> some View {
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
                sendInvite(to: user)
            } label: {
                if collabStore.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Share")
                        .font(.callout.weight(.semibold))
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .disabled(collabStore.isLoading)
        }
        .padding(.vertical, 4)
    }

    private func sendInvite(to user: TaskUserModel) {
        guard let token = auth.token else { return }
        Task {
            await collabStore.sendInviteForTaskCollab(
                token: token,
                taskId: task.id,
                invitedUserId: user.id
            )
            if collabStore.errorMessage == nil {
                shareToastText = "Task Shared"
                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                    showShareToast = true
                }
                #if os(iOS)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                #endif
                showShareSheet = false
                Task {
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.95)) {
                            showShareToast = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Avatar

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
            let first = parts[0].prefix(1)
            let second = parts[1].prefix(1)
            return String(first + second).uppercased()
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

    // MARK: - Toast View

    private func toastView(text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.green)
            Text(text)
                .font(.headline)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 520)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(
            Capsule().stroke(Color.primary.opacity(0.08))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 6)
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: showShareToast)
        .accessibilityAddTraits(.isStaticText)
        .accessibilityLabel(text)
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
