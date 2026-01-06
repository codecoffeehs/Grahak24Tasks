import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var auth: AuthStore

    @State private var openTaskAddSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if taskStore.isLoading {
                    ProgressView("Loading tasks…")
                } else if taskStore.tasks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checklist")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)

                        Text("No tasks yet")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(taskStore.tasks, id: \.id) { task in
                            TaskRow(
                                title: task.title,
                                due: task.due,
                                isCompleted: task.isCompleted
                            )
                            .swipeActions(edge: .leading) {
                                Button(role: .destructive) {
                                    // Action for delete
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    // Use Swift.Task and corrected name: toggleTask
                                        Task {
                                        if let token = auth.token {
                                            await taskStore.toggleTask(id: task.id, token: token)
                                        }
                                    }
                                } label: {
                                    Image(systemName: task.isCompleted ? "arrow.uturn.left" : "checkmark")
                                }
                                .tint(.green)
                                
                                Button {
                                    // Action for edit
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .refreshable {
                        if let token = auth.token {
                            // Corrected name: fetchTasks
                            await taskStore.fetchTasks(token: token)
                        }
                    }
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openTaskAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            // Mark all done logic
                        } label: {
                            Label("Mark All As Done", systemImage: "checkmark.circle")
                        }

                        Button(role: .destructive) {
                            // Delete all logic
                        } label: {
                            Label("Delete All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .sheet(isPresented: $openTaskAddSheet) {
                AddTaskView()
            }
        }
        .task {
            if let token = auth.token {
                await taskStore.fetchTasks(token: token)
            }
        }
        .alert("Error", isPresented: $taskStore.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(taskStore.errorMessage ?? "Something went wrong")
        }
    }
}
