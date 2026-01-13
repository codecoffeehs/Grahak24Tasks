import SwiftUI
import UIKit

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var auth: AuthStore

    @State private var openTaskAddSheet = false

    // MARK: - Row Builder
    @ViewBuilder
    private func taskRow(_ task: TaskModel) -> some View {
        NavigationLink {
            SingleTaskView(task: task)
        } label: {
            TaskRow(
                title: task.title,
                due: task.due,
                isCompleted: task.isCompleted,
                repeatType: task.repeatType,
                categoryTitle: task.categoryTitle,
                colorHex: task.color,
                categoryIcon: task.icon
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

    var body: some View {
        NavigationStack {
            Group {
                if taskStore.isLoading {
                    ProgressView("Loading tasks…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if taskStore.todayCount == 0 && taskStore.upcomingCount == 0 && taskStore.overdueCount == 0 {
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
                        if taskStore.overdueCount > 0 {
                            Section(
                                header: HStack {
                                    Text("Overdue")
                                        .font(.headline)

                                    Spacer()

                                    NavigationLink("See All") {
//                                        SectionTasksView(
//                                            title: "Overdue",
//                                            tasks: taskStore.overdueTasks
//                                        )
                                        Text("Overdue Tasks")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                            ) {
                                ForEach(taskStore.overdueTasks.prefix(3), id: \.id) { task in
                                    taskRow(task)
                                }
                            }
                        }

                        // MARK: - Today
                        if taskStore.todayCount > 0 {
                            Section(
                                header: HStack {
                                    Text("Today")
                                        .font(.headline)

                                    Spacer()

                                    NavigationLink("See All") {
//                                        SectionTasksView(
//                                            title: "Today",
//                                            tasks: taskStore.todayTasks
//                                        )
                                        Text("Today Tasks")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                            ) {
                                ForEach(taskStore.todayTasks.prefix(5), id: \.id) { task in
                                    taskRow(task)
                                }
                            }
                        }

                        // MARK: - Upcoming
                        if taskStore.upcomingCount > 0 {
                            Section(
                                header: HStack {
                                    Text("Upcoming")
                                        .font(.headline)

                                    Spacer()

                                    NavigationLink("See All") {
//                                        SectionTasksView(
//                                            title: "Upcoming",
//                                            tasks: taskStore.upcomingTasks
//                                        )
                                        Text("Upcoming Tasks")
                                    }
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                }
                            ) {
                                ForEach(taskStore.upcomingTasks.prefix(4), id: \.id) { task in
                                    taskRow(task)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Overview")
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
                await taskStore.fetchRecentTasks(token: token)
            }
        }
        .alert("Error", isPresented: $taskStore.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(taskStore.errorMessage ?? "Something went wrong")
        }
    }
}
