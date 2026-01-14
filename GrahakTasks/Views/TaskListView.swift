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
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if taskStore.todayCount == 0 && taskStore.upcomingCount == 0 && taskStore.overdueCount == 0 {
                        ContentUnavailableView(
                            "Nothing Coming Up Your Way!",
                            systemImage: "sun.max",
                            description: Text("That’s either impressive… or you forgot to add them.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {

                        // MARK: - Overdue
                        if taskStore.overdueCount > 0 {
                            Section(
                                header: HStack {
                                    Text("Overdue (\(taskStore.overdueCount))")
                                        .font(.headline)

                                    Spacer()

                                    NavigationLink("See All") {
                                        OverdueTasksView()
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
                                    Text("Today (\(taskStore.todayCount))")
                                        .font(.headline)

                                    Spacer()

                                    NavigationLink("See All") {
                                        TodayTasksView()
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
                                    Text("Upcoming (\(taskStore.upcomingCount))")
                                        .font(.headline)

                                    Spacer()

                                    NavigationLink("See All") {
                                        UpcomingTasksView()
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
