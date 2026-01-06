import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var task: TaskStore
    @EnvironmentObject var auth: AuthStore
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var dueDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                }

                Section {
                    DatePicker(
                        "Due Date",
                        selection: $dueDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button{
                        Task {
                            if let token = auth.token {
                                await task.addTask(
                                    title: title,
                                    due: dueDate,
                                    token: token
                                )
                                dismiss()
                            }
                        }
                    }label: {
                        Text("Save")
                    }
                    .buttonStyle(.glassProminent)
                    .disabled(title.isEmpty || task.isLoading)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
