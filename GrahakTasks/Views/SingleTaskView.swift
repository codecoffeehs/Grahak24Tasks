import SwiftUI

struct SingleTaskView: View {
    let task: TaskModel  // passed from list

    var body: some View {
        Form {

            // MARK: - Title
            Section {
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            // MARK: - Status
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    Label(
                        task.isCompleted ? "Completed" : "Pending",
                        systemImage: task.isCompleted
                            ? "checkmark.circle.fill"
                            : "circle"
                    )
                    .foregroundColor(task.isCompleted ? .green : .secondary)
                }
            }

            // MARK: - Due Date
            Section {
                HStack {
                    Text("Due")
                    Spacer()
                    if let result = DateParser.parseDueDate(from: task.due) {
                        Text(result.text)
                            .foregroundStyle(result.isOverdue ? .red : .secondary)
                    } else {
                        Text(task.due)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // MARK: - Repeat
            Section {
                HStack {
                    Text("Repeat")
                    Spacer()
                    Text(task.repeatType.title)
                        .foregroundColor(
                            task.repeatType == .none ? .secondary : .primary
                        )
                }
            }
        }
        .navigationTitle(task.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
