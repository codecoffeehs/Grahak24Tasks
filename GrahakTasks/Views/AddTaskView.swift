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

    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAllowed = settings.authorizationStatus == .authorized
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Title
                Section {
                    TextField("Title", text: $title)
                }
                
                // MARK: - Category
                Section {
                    Picker("Category", selection: $selectedCategoryId) {

                        // Optional "None" option
                        Text("None")
                            .tag("")

                        ForEach(categoryStore.categories, id: \.id) { category in
                            Text(category.title)
                                .tag(category.id)  // ✅ This is the important part
                        }
                    }
                }

                // MARK: - Due Date & Time
                Section {
                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        in: Date().addingTimeInterval(120)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .disabled(!notificationsAllowed)
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
                            if let token = auth.token {
                                await taskStore.addTask(
                                    title: title,
                                    due: dueDate,
                                    repeatType: repeatOption,
                                    categoryId: selectedCategoryId,
                                    token: token
                                )
                                dismiss()
                            }
                        }
                    }
                    .disabled(title.isEmpty || taskStore.isLoading)
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
                }
        }
    }
}
