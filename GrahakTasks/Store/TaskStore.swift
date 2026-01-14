import Foundation
import Combine

@MainActor
class TaskStore: ObservableObject {

    // MARK: - Home Sections
    @Published var todayTasks: [TaskModel] = []
    @Published var upcomingTasks: [TaskModel] = []
    @Published var overdueTasks: [TaskModel] = []

    @Published var todayCount: Int = 0
    @Published var upcomingCount: Int = 0
    @Published var overdueCount: Int = 0

    // MARK: - Full Tasks (optional screen)
    @Published var tasks: [TaskModel] = []

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false

    // MARK: - Fetch Recent Tasks (Home)
    func fetchRecentTasks(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await TaskApi.fetchRecentTasks(token: token)
            todayTasks = response.today.tasks
            upcomingTasks = response.upcoming.tasks
            overdueTasks = response.overdue.tasks

            todayCount = response.today.count
            upcomingCount = response.upcoming.count
            overdueCount = response.overdue.count

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }

    // MARK: - Fetch All Tasks
    func fetchTasks(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            tasks = try await TaskApi.fetchTasks(token: token)
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }

    // MARK: - Add Task
    func addTask(
        title: String,
        due: Date,
        repeatType: RepeatType,
        categoryId: String,
        token: String
    ) async {
        isLoading = true
        errorMessage = nil

        let minimumDelay: TimeInterval = 60
        guard due.timeIntervalSinceNow > minimumDelay else {
            isLoading = false
            errorMessage = "Due time must be at least 1 minute from now."
            showErrorAlert = true
            return
        }

        do {
            let newTask = try await TaskApi.createTask(
                title: title,
                due: due,
                repeatType: repeatType,
                categoryId: categoryId,
                token: token
            )

            // 🔔 schedule notification
            NotificationManager.shared.scheduleTaskNotification(
                id: newTask.id,
                title: newTask.title,
                dueDate: due
            )

            // ✅ refresh home sections from backend (no conflicts / no bugs)
            await fetchRecentTasks(token: token)

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }

    // MARK: - Toggle Task
    func toggleTask(
        id: String,
        token: String
    ) async {
        do {
            _ = try await TaskApi.toggleTask(taskId: id, token: token)
            
            NotificationManager.shared.cancelTaskNotification(id: id)
            // ✅ Refresh Home sections (keeps ordering + sections accurate)
            await fetchRecentTasks(token: token)

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    // MARK: - Delete Task
    func deleteTask(
        id: String,
        token: String
    ) async {
        do {
            try await TaskApi.deleteTask(taskId: id, token: token)

            // cancel notification
            NotificationManager.shared.cancelTaskNotification(id: id)

            // ✅ Refresh Home sections
            await fetchRecentTasks(token: token)

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
