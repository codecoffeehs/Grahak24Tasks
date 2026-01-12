import SwiftUI

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var auth: AuthStore

    @State private var openTaskAddSheet = false

    // MARK: - Helpers
    private func parseDate(_ iso: String) -> Date? {
        ISO8601DateFormatter().date(from: iso)
    }

    private var now: Date { Date() }
    private var calendar: Calendar { .current }

    private var overdueTasks: [TaskModel] {
        taskStore.tasks.filter { task in
            guard let date = parseDate(task.due) else { return false }
            return date < now
        }
    }

    private var todayTasks: [TaskModel] {
        taskStore.tasks.filter { task in
            guard let date = parseDate(task.due) else { return false }
            return calendar.isDateInToday(date)
        }
    }

    private var upcomingTasks: [TaskModel] {
        taskStore.tasks.filter { task in
            guard let date = parseDate(task.due) else { return false }
            return date > now && !calendar.isDateInToday(date)
        }
    }

    var body: some View {
        //        NavigationStack {
                    Group {
                        if taskStore.isLoading {
                            ProgressView("Loading tasks…")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
        
                        } else if taskStore.tasks.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 44))
                                    .foregroundColor(.secondary)
        
                                Text("Nothing scheduled")
                                    .font(.callout)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
        
                        } else {
                            List {
        
                                // MARK: - Overdue
                                if !overdueTasks.isEmpty {
                                    
                                }
        
                                // MARK: - Today
                                if !todayTasks.isEmpty {
                                    Section("Today") {
                                        ForEach(todayTasks, id: \.id) { task in
                                            NavigationLink {
                                                SingleTaskView(task: task)
                                            } label: {
                                                TaskRow(
                                                    title: task.title,
                                                    due: task.due,
                                                    isCompleted: task.isCompleted,
                                                )
                                            }
                                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                                Button(role: .destructive) {
                                                    Task {
                                                        if let token = auth.token {
                                                            await taskStore.deleteTask(id: task.id, token: token)
                                                        }
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button {
                                                    Task {
                                                        if let token = auth.token {
                                                            await taskStore.toggleTask(id: task.id, token: token)
                                                        }
                                                    }
                                                } label: {
                                                    Image(systemName: "checkmark")
                                                }
                                                .tint(.green)
        
                                                Button {
                                                    // edit later
                                                } label: {
                                                    Image(systemName: "pencil")
                                                }
                                                .tint(.blue)
                                            }
                                        }
                                    }
                                }
        
                                // MARK: - Upcoming
                                if !upcomingTasks.isEmpty {
                                    Section("Upcoming") {
                                        ForEach(upcomingTasks, id: \.id) { task in
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
                                                            await taskStore.deleteTask(id: task.id, token: token)
                                                        }
                                                    }
                                                } label: {
                                                    Label("Delete", systemImage: "trash")
                                                }
                                            }
                                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                Button {
                                                    Task {
                                                        if let token = auth.token {
                                                            await taskStore.toggleTask(id: task.id, token: token)
                                                        }
                                                    }
                                                } label: {
                                                    Image(systemName: "checkmark")
                                                }
                                                .tint(.green)
        
                                                Button {
                                                    // edit later
                                                } label: {
                                                    Image(systemName: "pencil")
                                                }
                                                .tint(.blue)
                                            }
                                        }
                                    }
                                }
                            }
                            .listStyle(.insetGrouped)
                        }
                    }
                    .navigationTitle("Today")
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
                                    // later
                                } label: {
                                    Label("Mark All As Done", systemImage: "checkmark.circle")
                                }
        
                                Button(role: .destructive) {
                                    // later
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
                        // Ideally: fetchRecentTasks here (home focused)
                        await taskStore.fetchRecentTasks(token: token)
                    }
                }
                .alert("Error", isPresented: $taskStore.showErrorAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text(taskStore.errorMessage ?? "Something went wrong")
                }
            }
        Text("Hello")
    }
}
