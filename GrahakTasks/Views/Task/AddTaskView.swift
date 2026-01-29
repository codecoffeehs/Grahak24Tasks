import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var categoryStore: CategoryStore
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date().addingTimeInterval(120)
    @State private var repeatOption: RepeatType = .none
    @State private var selectedCategoryId: String = "__placeholder__"
    @State private var notificationsAllowed = true
    @State private var setReminder = false

    private let descriptionLimit = 250

    // MARK: - Notification Permission
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

    // MARK: - Category Defaults
    private func selectDefaultCategoryIfNeeded() {
        guard selectedCategoryId == "__placeholder__" || selectedCategoryId.isEmpty else { return }

        if let others = categoryStore.categories.first(where: {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "others"
        }) {
            selectedCategoryId = others.id
        } else if let first = categoryStore.categories.first {
            selectedCategoryId = first.id
        }
    }

    private var categoriesAvailable: Bool {
        !categoryStore.categories.isEmpty
    }

    private var minimumLeadTime: TimeInterval { 60 }

    private var isDueValid: Bool {
        dueDate.timeIntervalSinceNow > minimumLeadTime
    }

    private var canSave: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasCategory = categoriesAvailable && selectedCategoryId != "__placeholder__"
        guard hasTitle, hasCategory, !taskStore.isLoading else { return false }

        return setReminder ? notificationsAllowed && isDueValid : true
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Title
                Section {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.sentences)
                }

                // MARK: - Description
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Add a description...") // Subtle placeholder
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 10)
                            }
                            TextEditor(text: $description)
                                .frame(minHeight: 88, maxHeight: 120)
                                .padding(.horizontal, -5)
                                .background(Color(.clear))
                                .onChange(of: description) { _, newValue in
                                    if newValue.count > descriptionLimit {
                                        description = String(newValue.prefix(descriptionLimit))
                                    }
                                }
                                .font(.body)
                        }
                        // Progress + Counter Row
                        HStack {
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color(.systemGray5))
                                        .frame(height: 8)
                                    Capsule()
                                        .fill(
                                            description.count < descriptionLimit
                                            ? Color.accentColor
                                            : Color.red
                                        )
                                        .frame(
                                            width: CGFloat(description.count) / CGFloat(descriptionLimit) * geometry.size.width,
                                            height: 8
                                        )
                                }
                            }
                            .frame(height: 8)
                            .padding(.trailing, 8)

                            // Character Counter
                            Text("\(description.count)/\(descriptionLimit)")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(description.count == descriptionLimit ? .red : .secondary)
                                .frame(minWidth: 56, alignment: .trailing)
                        }
                        .padding(.top, 2)
                        .padding(.horizontal, 2)
                    }
                    .padding(.vertical, 2)
                }

                // MARK: - Category
                Section {
                    if categoriesAvailable {
                        Picker("Category", selection: $selectedCategoryId) {
                            if selectedCategoryId == "__placeholder__" {
                                Text("Select a category").tag("__placeholder__")
                            }
                            ForEach(categoryStore.categories, id: \.id) { category in
                                Text(category.title).tag(category.id)
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

                // MARK: - Reminder Toggle
                Section {
                    Toggle(isOn: $setReminder) {
                        Label("Set Reminder", systemImage: "bell.badge")
                    }
                    .onChange(of: setReminder) { _, newValue in
                        if newValue && !notificationsAllowed {
                            setReminder = false
                        }
                    }
                }

                // MARK: - Due Date & Repeat
                if setReminder {
                    Section {
                        DatePicker(
                            "Due Date",
                            selection: $dueDate,
                            in: Date().addingTimeInterval(minimumLeadTime)...,
                            displayedComponents: [.date, .hourAndMinute]
                        )

                        if notificationsAllowed && !isDueValid {
                            Text("Pick a time at least 1 minute from now.")
                                .foregroundStyle(.red)
                        }
                    }

                    Section {
                        Picker("Repeat", selection: $repeatOption) {
                            ForEach(RepeatType.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                // Save
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            guard let token = auth.token else { return }

                            let finalDue = setReminder && notificationsAllowed ? dueDate : nil
                            let finalRepeat = setReminder && notificationsAllowed ? repeatOption : nil

                            await taskStore.addTask(
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
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
            }
        }
        .onAppear {
            checkNotificationPermission()
            Task {
                if categoryStore.categories.isEmpty, let token = auth.token {
                    await categoryStore.fetchCategories(token: token)
                }
                await MainActor.run {
                    selectDefaultCategoryIfNeeded()
                }
            }
        }
        .onChange(of: categoryStore.categories.count) { _, _ in
            selectDefaultCategoryIfNeeded()
        }
    }
}
