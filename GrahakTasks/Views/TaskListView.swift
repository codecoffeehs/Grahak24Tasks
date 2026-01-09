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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if taskStore.tasks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checklist")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)

                        Text("Your day is clear. Add a task to get started.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    List {
                        ForEach(taskStore.tasks) { task in
                            NavigationLink {
                                SingleTaskView(task: task)
                            } label: {
                                TaskRow(
                                    title: task.title,
                                    due: task.due,
                                    isCompleted: task.isCompleted,
                                    repeatType: task.repeatType
                                )
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task {
                                        if let token = auth.token {
                                            await taskStore.deleteTask(
                                                id: task.id,
                                                token: token
                                            )
                                        }
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    Task {
                                        if let token = auth.token {
                                            await taskStore.toggleTask(
                                                id: task.id,
                                                token: token
                                            )
                                        }
                                    }
                                } label: {
                                    Image(systemName: task.isCompleted
                                          ? "arrow.uturn.left"
                                          : "checkmark")
                                }
                                .tint(.green)

                                Button {
                                    // Edit later
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
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
                if taskStore.tasks.count > 3{
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Button {
                                // Mark all done (later)
                            } label: {
                                Label("Mark All As Done", systemImage: "checkmark.circle")
                            }

                            Button(role: .destructive) {
                                // Delete all (later)
                            } label: {
                                Label("Delete All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
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

#Preview{
    TaskListView()
        .environmentObject(TaskStore())
        .environmentObject(AuthStore())
}
