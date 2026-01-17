import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var categoryStore : CategoryStore
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var dueDate = Date().addingTimeInterval(120)
    @State private var repeatOption: RepeatType = .none
    @State private var selectedCategoryId: String = ""
    @State private var notificationsAllowed = true
    @State private var setReminder = false

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAllowed = settings.authorizationStatus == .authorized
                // If user doesn’t have permission, turn off reminder toggle to avoid confusion.
                if !notificationsAllowed {
                    setReminder = false
                }
            }
        }
    }

    // Pick the best default category: "Others" if available, otherwise first category
    private func selectDefaultCategoryIfNeeded() {
        guard selectedCategoryId.isEmpty else { return }

        if let others = categoryStore.categories.first(where: {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "others"
        }) {
            selectedCategoryId = others.id
        } else if let first = categoryStore.categories.first {
            selectedCategoryId = first.id
        }
    }

    private var minimumLeadTime: TimeInterval { 60 } // keep in sync with TaskStore.addTask check

    private var isDueValid: Bool {
        dueDate.timeIntervalSinceNow > minimumLeadTime
    }

    private var canSave: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !selectedCategoryId.isEmpty,
              !taskStore.isLoading
        else { return false }

        if setReminder {
            // When reminders are on, require permission and a valid due date
            return notificationsAllowed && isDueValid
        } else {
            // When reminders are off, title + category are enough
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Title
                Section {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.sentences)
                }

                // MARK: - Category
                Section {
                    Picker("Category", selection: $selectedCategoryId) {
                        ForEach(categoryStore.categories, id: \.id) { category in
                            Text(category.title)
                                .tag(category.id)
                        }
                    }
                }

                // MARK: - Reminder Toggle
                Section {
                    Toggle(isOn: $setReminder) {
                        Label("Set Reminder", systemImage: "bell.badge")
                    }
                    .onChange(of: setReminder) { _, newValue in
                        // If user turns it on but notifications are not allowed, reset and advise.
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

                // MARK: - Due Date & Time (only when reminder is ON and notifications allowed)
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
                    } footer: {
                        if !notificationsAllowed {
                            Text("Enable notifications to set reminders for tasks.")
                                .foregroundStyle(.red)
                        }
                    }

                    // MARK: - Repeat
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
                            Text("Repeating tasks require notification permissions.")
                                .foregroundStyle(.red)
                        } else {
                            Text("Choose how often this reminder should repeat.")
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // Save
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            guard let token = auth.token else { return }

                            let finalDue: Date? = (setReminder && notificationsAllowed) ? dueDate : nil
                            let finalRepeat: RepeatType? = (setReminder && notificationsAllowed) ? repeatOption : nil

                            await taskStore.addTask(
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                due: finalDue,
                                repeatType: finalRepeat,
                                categoryId: selectedCategoryId,
                                token: token
                            )
                            if taskStore.errorMessage == nil {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!canSave)
                }

                // Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkNotificationPermission()
            Task {
                if categoryStore.categories.isEmpty, let token = auth.token {
                    await categoryStore.fetchCategories(token: token)
                }
                // After categories are available, pick default
                await MainActor.run {
                    selectDefaultCategoryIfNeeded()
                }
            }
        }
    }
}
