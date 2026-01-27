import SwiftUI

struct RequestView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var collabStore: CollabStore
    @EnvironmentObject private var categoryStore: CategoryStore
    @EnvironmentObject private var taskStore: TaskStore

    @State private var isInitialLoad = true
    @State private var showAlert = false
    @State private var alertMessage: String?

    // Accept flow
    @State private var selectedRequest: TaskRequests?
    @State private var showAcceptSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                Group {
                    if collabStore.isLoading && collabStore.taskRequests.isEmpty {
                        loadingState()
                    } else if let err = collabStore.errorMessage,
                              collabStore.taskRequests.isEmpty {
                        errorState(message: err)
                    } else if collabStore.taskRequests.isEmpty {
                        emptyState()
                    } else {
                        requestsList()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Requests")
            .navigationBarTitleDisplayMode(.large)
            .task {
                guard isInitialLoad else { return }
                isInitialLoad = false
                await reload()
                // Preload categories for accept sheet UX
                if categoryStore.categories.isEmpty, let token = auth.token {
                    await categoryStore.fetchCategories(token: token)
                }
            }
            .alert("Message", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage ?? "")
            }
            .sheet(isPresented: $showAcceptSheet, onDismiss: {
                selectedRequest = nil
            }) {
                if let request = selectedRequest {
                    AcceptRequestSheet(
                        title: request.title,
                        onCancel: { showAcceptSheet = false },
                        onSave: { categoryId, due, repeatType in
                            Task {
                                guard let token = auth.token else { return }

                                // Call Collab API: accept invite and create task in one go
                                let created = await collabStore.acceptInviteAndCreateTask(
                                    token: token,
                                    inviteId: request.id,
                                    title: request.title,
                                    due: due,
                                    repeatType: repeatType,
                                    categoryId: categoryId
                                )

                                if let created {
                                    // Optional: schedule notification locally if due exists
                                    if let due {
                                        NotificationManager.shared.scheduleTaskNotification(
                                            id: created.id,
                                            title: created.title,
                                            dueDate: due
                                        )
                                    }
                                    // Refresh requests and home sections
                                    await collabStore.fetchTaskRequest(token: token)
                                    await taskStore.fetchRecentTasks(token: token)

                                    showAcceptSheet = false
                                    alertMessage = "Share accepted and task created."
                                    showAlert = true
                                } else if let err = collabStore.errorMessage {
                                    alertMessage = err
                                    showAlert = true
                                } else {
                                    alertMessage = "Something went wrong while accepting the request."
                                    showAlert = true
                                }
                            }
                        }
                    )
                    .environmentObject(categoryStore)
                    .environmentObject(auth)
                }
            }
        }
    }

    // MARK: - List

    @ViewBuilder
    private func requestsList() -> some View {
        List {
            ForEach(collabStore.taskRequests) { request in
                RequestRow(
                    request: request,
                    onAccept: { handleAccept(request) },
                    onReject: { handleReject(request) }
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(uiColor: .systemGroupedBackground))
        .refreshable { await reload() }
    }

    // MARK: - States

    @ViewBuilder
    private func loadingState() -> some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Loading requests…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)

            Text("Failed to load")
                .font(.headline)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await reload() }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private func emptyState() -> some View {
        VStack(spacing: 18) {
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(.secondary)

            Text("No Requests Yet")
                .font(.headline)

            Text("When someone shares a task with you, their request will appear here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Button {
                Task { await reload() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue, in: Capsule())
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Actions

    private func handleAccept(_ request: TaskRequests) {
        Task {
            // Ensure categories are available before presenting the sheet
            if categoryStore.categories.isEmpty, let token = auth.token {
                await categoryStore.fetchCategories(token: token)
            }
            await MainActor.run {
                selectedRequest = request
                showAcceptSheet = true
            }
        }
    }

    private func handleReject(_ request: TaskRequests) {
        Task {
            guard let token = auth.token else {
                alertMessage = "You must be logged in."
                showAlert = true
                return
            }
            // Call store to reject, then refresh list
            await collabStore.rejectInvite(token: token, inviteId: request.id)

            if let err = collabStore.errorMessage {
                alertMessage = err
                showAlert = true
            } else {
                alertMessage = "Request rejected."
                showAlert = true
            }
        }
    }

    @MainActor
    private func reload() async {
        guard let token = auth.token else {
            collabStore.errorMessage = "You must be logged in."
            return
        }
        await collabStore.fetchTaskRequest(token: token)
    }
}

//
// MARK: - Custom Stocks Style Row
//

private struct RequestRow: View {
    let request: TaskRequests
    let onAccept: () -> Void
    let onReject: () -> Void

    private var requestedText: String {
        if let ago = DateParser.timeAgo(from: request.sharedOn) {
            return ago
        }
        if let date = ISODateHelper.parseISO(request.sharedOn) {
            return ISODateHelper.relativeOrAbsolute(date)
        }
        return request.sharedOn
    }

    var body: some View {
        VStack(spacing: 0) {

            // MAIN CONTENT
            HStack(alignment: .top, spacing: 12) {
                // icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.opacity(0.12))

                    Image(systemName: "person.2.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 6) {
                    Text(request.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(request.invitedByUserEmail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    Text("Requested \(requestedText)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)

            // DIVIDER
            Divider()
                .opacity(0.35)
                .padding(.leading, 68)

            // BUTTONS
            HStack(spacing: 10) {
                Button(action: onReject) {
                    Text("Reject")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.red.opacity(0.12), in: Capsule())
                }
                .foregroundStyle(.red)
                .buttonStyle(.borderless)

                Button(action: onAccept) {
                    Text("Accept")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.blue, in: Capsule())
                }
                .foregroundStyle(.white)
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .padding(.vertical, 8)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(request.title), from \(request.invitedByUserEmail), requested \(requestedText)")
    }
}

//
// MARK: - Accept Request Sheet (read-only title, AddTask-like UX)
//

private struct AcceptRequestSheet: View {
    @EnvironmentObject private var categoryStore: CategoryStore
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onCancel: () -> Void
    let onSave: (_ categoryId: String, _ due: Date?, _ repeatType: RepeatType?) -> Void

    @State private var selectedCategoryId: String = "__placeholder__"
    @State private var notificationsAllowed = true
    @State private var setReminder = false
    @State private var dueDate = Date().addingTimeInterval(120)
    @State private var repeatOption: RepeatType = .none

    private var minimumLeadTime: TimeInterval { 60 }
    private var isDueValid: Bool { dueDate.timeIntervalSinceNow > minimumLeadTime }

    private var categoriesAvailable: Bool {
        !categoryStore.categories.isEmpty
    }

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

    private func selectDefaultCategoryIfNeeded() {
        // Only pick a real ID if we currently have a placeholder or empty
        guard selectedCategoryId == "__placeholder__" || selectedCategoryId.isEmpty else { return }

        if let others = categoryStore.categories.first(where: {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "others"
        }) {
            selectedCategoryId = others.id
        } else if let first = categoryStore.categories.first {
            selectedCategoryId = first.id
        }
    }

    private var canSave: Bool {
        // Must not be placeholder and must be a real category ID
        guard categoriesAvailable, selectedCategoryId != "__placeholder__", !selectedCategoryId.isEmpty else { return false }
        if setReminder {
            return notificationsAllowed && isDueValid
        } else {
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title (read-only)
                Section {
                    HStack {
                        Text("Title")
                        Spacer()
                        Text(title)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                    }
                } footer: {
                    Text("This title comes from the shared task and can’t be changed.")
                }

                // Category
                Section {
                    if categoriesAvailable {
                        Picker("Category", selection: $selectedCategoryId) {
                            // Optional placeholder hidden when we already have a real selection
                            if selectedCategoryId == "__placeholder__" {
                                Text("Select a category").tag("__placeholder__")
                            }
                            ForEach(categoryStore.categories, id: \.id) { category in
                                Text(category.title).tag(category.id)
                            }
                        }
                        // Ensure the selection is valid whenever categories change
                        .onChange(of: categoryStore.categories.count) { _, _ in
                            selectDefaultCategoryIfNeeded()
                        }
                        // Also ensure we have a valid selection at first render
                        .task {
                            selectDefaultCategoryIfNeeded()
                        }
                    } else {
                        HStack {
                            ProgressView()
                            Text("Loading categories…")
                                .foregroundStyle(.secondary)
                        }
                    }
                } footer: {
                    if !categoriesAvailable {
                        Text("We’re loading your categories. This usually takes a moment.")
                    }
                }

                // Reminder toggle
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
                        Text("Enable notifications in Settings to set reminders.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Turn this on to choose a due date, time and optional repeat.")
                    }
                }

                // Due + Repeat
                if setReminder {
                    Section {
                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            in: Date().addingTimeInterval(minimumLeadTime)...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .disabled(!notificationsAllowed)

                        if notificationsAllowed && !isDueValid {
                            Text("Pick a time at least 1 minute from now.")
                                .foregroundStyle(.red)
                        }
                    }

                    Section {
                        Picker("Repeat", selection: $repeatOption) {
                            ForEach(RepeatType.allCases) { option in
                                Text(option.title)
                                    .tag(option)
                            }
                        }
                        .disabled(!notificationsAllowed)
                    } footer: {
                        if !notificationsAllowed {
                            Text("Repeating requires notification permissions.")
                                .foregroundStyle(.red)
                        } else {
                            Text("Choose how often this reminder should repeat.")
                        }
                    }
                }
            }
            .navigationTitle("Accept & Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { onCancel(); dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") {
                        let finalDue = (setReminder && notificationsAllowed) ? dueDate : nil
                        let finalRepeat = (setReminder && notificationsAllowed) ? repeatOption : nil
                        onSave(selectedCategoryId, finalDue, finalRepeat)
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            checkNotificationPermission()
            Task {
                if categoryStore.categories.isEmpty, let token = auth.token {
                    await categoryStore.fetchCategories(token: token)
                }
                await MainActor.run { selectDefaultCategoryIfNeeded() }
            }
        }
    }
}

//
// MARK: - Robust ISO Helper
//

private enum ISODateHelper {

    static func parseISO(_ iso: String) -> Date? {
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f1.date(from: iso) { return d }

        let f2 = ISO8601DateFormatter()
        f2.formatOptions = [.withInternetDateTime]
        if let d = f2.date(from: iso) { return d }

        let manualFormats = [
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm",
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm"
        ]

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current

        for fmt in manualFormats {
            df.dateFormat = fmt
            if let d = df.date(from: iso) { return d }
        }

        return nil
    }

    static func relativeOrAbsolute(_ date: Date, reference: Date = Date()) -> String {
        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .full

        let diff = abs(reference.timeIntervalSince(date))
        let sevenDays: TimeInterval = 7 * 24 * 60 * 60

        if diff <= sevenDays {
            return rel.localizedString(for: date, relativeTo: reference)
        }

        let df = DateFormatter()
        df.dateFormat = "d MMM yyyy, HH:mm"
        return df.string(from: date)
    }
}
