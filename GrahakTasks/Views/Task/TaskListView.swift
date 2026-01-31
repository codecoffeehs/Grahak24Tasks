import SwiftUI
import UIKit

struct TaskListView: View {
    @EnvironmentObject var taskStore: TaskStore
    @EnvironmentObject var auth: AuthStore

    @State private var openTaskAddSheet = false
    @State private var pendingDeleteTaskID = ""
    @State private var pendingDeleteTaskTitle = ""
    @State private var showDeleteAlert = false

    @State private var taskSearch = ""

    // MARK: - Filtering helpers
    private var isSearching: Bool {
        !taskSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func matchesSearch(_ task: TaskModel) -> Bool {
        let q = taskSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return true }
        if task.title.lowercased().contains(q) { return true }
        if task.description.lowercased().contains(q) { return true }
        if task.categoryTitle.lowercased().contains(q) { return true }
        return false
    }

    private var filteredOverdue: [TaskModel] {
        taskStore.overdueTasks.filter(matchesSearch)
    }

    private var filteredToday: [TaskModel] {
        taskStore.todayTasks.filter(matchesSearch)
    }

    private var filteredUpcoming: [TaskModel] {
        taskStore.upcomingTasks.filter(matchesSearch)
    }

    private var filteredNoDue: [TaskModel] {
        taskStore.noDueTasks.filter(matchesSearch)
    }

    private var filteredOverdueCount: Int { filteredOverdue.count }
    private var filteredTodayCount: Int { filteredToday.count }
    private var filteredUpcomingCount: Int { filteredUpcoming.count }
    private var filteredNoDueCount: Int { filteredNoDue.count }

    // MARK: - Row Builder
    @ViewBuilder
    private func taskRow(_ task: TaskModel) -> some View {
        NavigationLink {
            SingleTaskView(task: task)
        } label: {
            TaskRow(
                title: task.title,
                description: task.description,
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
                // Stage for confirmation
                pendingDeleteTaskID = task.id
                pendingDeleteTaskTitle = task.title
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel("Delete task")
            .accessibilityHint("Opens confirmation alert to permanently delete this task")
            .accessibilityIdentifier("delete_task_button")
        }

        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
            .accessibilityLabel("Complete task")
            .accessibilityHint("Marks this task as completed")
            .accessibilityIdentifier("complete_task_button")

        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if taskStore.isLoading {
                    ProgressView("Loading tasks…")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if !isSearching &&
                            taskStore.todayCount == 0 &&
                            taskStore.upcomingCount == 0 &&
                            taskStore.overdueCount == 0 &&
                            taskStore.noDueCount == 0 {
                    ContentUnavailableView(
                        "Nothing Coming Up Your Way!",
                        systemImage: "sun.max",
                        description: Text("That’s either impressive… or you forgot to add them.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if isSearching &&
                            filteredTodayCount == 0 &&
                            filteredUpcomingCount == 0 &&
                            filteredOverdueCount == 0 &&
                            filteredNoDueCount == 0 {
                    ContentUnavailableView(
                        "No results",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different keyword.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {

                        // MARK: - Overdue
                        let overdueCountToShow = isSearching ? filteredOverdueCount : taskStore.overdueCount
                        if overdueCountToShow > 0 {
                            Section(
                                header: HStack {
                                    Text("Overdue (\(overdueCountToShow))")
                                        .font(.headline)

                                    Spacer()

                                    if !isSearching {
                                        NavigationLink("See All") {
                                            OverdueTasksView()
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .simultaneousGesture(
                                            TapGesture().onEnded{
                                                let generator = UIImpactFeedbackGenerator(style: .soft)
                                                generator.impactOccurred()
                                            }
                                        )
                                    }
                                }
                            ) {
                                ForEach(isSearching ? filteredOverdue : taskStore.overdueTasks, id: \.id) { task in
                                    taskRow(task)
                                }
                            }
                        }

                        // MARK: - Today
                        let todayCountToShow = isSearching ? filteredTodayCount : taskStore.todayCount
                        if todayCountToShow > 0 {
                            Section(
                                header: HStack {
                                    Text("Today (\(todayCountToShow))")
                                        .font(.headline)

                                    Spacer()

                                    if !isSearching {
                                        NavigationLink("See All") {
                                            TodayTasksView()
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .simultaneousGesture(
                                            TapGesture().onEnded{
                                                let generator = UIImpactFeedbackGenerator(style: .soft)
                                                generator.impactOccurred()
                                            }
                                        )
                                    }
                                }
                            ) {
                                ForEach(isSearching ? filteredToday : taskStore.todayTasks, id: \.id) { task in
                                    taskRow(task)
                                }
                            }
                        }

                        // MARK: - Upcoming
                        let upcomingCountToShow = isSearching ? filteredUpcomingCount : taskStore.upcomingCount
                        if upcomingCountToShow > 0 {
                            Section(
                                header: HStack {
                                    Text("Upcoming (\(upcomingCountToShow))")
                                        .font(.headline)

                                    Spacer()

                                    if !isSearching {
                                        NavigationLink("See All") {
                                            UpcomingTasksView()
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .simultaneousGesture(
                                            TapGesture().onEnded{
                                                let generator = UIImpactFeedbackGenerator(style: .soft)
                                                generator.impactOccurred()
                                            }
                                        )
                                    }
                                }
                            ) {
                                if isSearching {
                                    ForEach(filteredUpcoming, id: \.id) { task in
                                        taskRow(task)
                                    }
                                } else {
                                    ForEach(taskStore.upcomingTasks.prefix(4), id: \.id) { task in
                                        taskRow(task)
                                    }
                                }
                            }
                        }

                        // MARK: - No Due
                        let noDueCountToShow = isSearching ? filteredNoDueCount : taskStore.noDueCount
                        if noDueCountToShow > 0 {
                            Section(
                                header: HStack {
                                    Text("No Due (\(noDueCountToShow))")
                                        .font(.headline)

                                    Spacer()

                                    if !isSearching {
                                        NavigationLink("See All") {
                                            NoDueTasksView()
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .simultaneousGesture(
                                            TapGesture().onEnded{
                                                let generator = UIImpactFeedbackGenerator(style: .soft)
                                                generator.impactOccurred()
                                            }
                                        )
                                    }
                                }
                            ) {
                                ForEach(isSearching ? filteredNoDue : taskStore.noDueTasks, id: \.id) { task in
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
        .alert("Delete Task?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                pendingDeleteTaskID = ""
                pendingDeleteTaskTitle = ""
            }

            Button("Delete", role: .destructive) {
                let taskId = pendingDeleteTaskID
                pendingDeleteTaskID = ""
                pendingDeleteTaskTitle = ""
                showDeleteAlert = false

                Task {
                    if let token = auth.token {
                        await taskStore.deleteTask(id: taskId, token: token)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete “\(pendingDeleteTaskTitle)”? This action cannot be undone.")
        }
        .alert("Error", isPresented: $taskStore.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(taskStore.errorMessage ?? "Something went wrong")
        }
        .searchable(text: $taskSearch, prompt: "Search tasks")
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
    }
}
