import SwiftUI
import UserNotifications

struct AddTaskView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) var dismiss

    // MARK: - Form State
    @State private var title: String = ""
    @State private var dueDate: Date = Date().addingTimeInterval(120)
    @State private var repeatOption: RepeatType = .none
    @State private var notificationsAllowed: Bool = true
    // MARK: - Notification Permission
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsAllowed = settings.authorizationStatus == .authorized
            }
        }
    }
    var isTitleValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Title
                Section {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.sentences)
                } footer: {
                    Text("Keep It Short and Clear").foregroundStyle(.primary)
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
                    }else{
                        Text("Select when you want to be reminded")
                            .foregroundStyle(.primary)
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
                    }else{
                        Text("Select the repeating frequency")
                            .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                // MARK: - Save
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        Task {
                            if let token = auth.token {
                                await taskStore.addTask(
                                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                    due: dueDate,
                                    repeatType: repeatOption,
                                    token: token
                                )
                                dismiss()
                            }
                        }
                    }
                    .disabled(!isTitleValid || taskStore.isLoading)
                }

                // MARK: - Cancel
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            checkNotificationPermission()
        }
    }
}
