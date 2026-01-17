import Foundation
import Combine

@MainActor
class TaskStore: ObservableObject {

    // MARK: - Home Sections
    @Published var todayTasks: [TaskModel] = []
    @Published var upcomingTasks: [TaskModel] = []
    @Published var overdueTasks: [TaskModel] = []
    @Published var noDueTasks : [TaskModel] = []
    
    @Published var todayCount: Int = 0
    @Published var upcomingCount: Int = 0
    @Published var overdueCount: Int = 0
    @Published var noDueCount: Int = 0
    
    // MARK: - Full Tasks (optional screen)
    @Published var tasks: [TaskModel] = []

    // MARK: - UI State
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false

    // MARK: - Separate Task Page
    @Published var allTodayTasks : [TaskModel] = []
    @Published var allUpcomingTasks : [TaskModel] = []
    @Published var allOverdueTasks : [TaskModel] = []
    
    // MARK: - Tasks For Category
    @Published var categoryTasks: [TaskModel] = []
    // MARK: - Fetch Recent Tasks (Home)
    func fetchRecentTasks(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await TaskApi.fetchRecentTasks(token: token)
            todayTasks = response.today.tasks
            upcomingTasks = response.upcoming.tasks
            overdueTasks = response.overdue.tasks
            noDueTasks = response.noDue.tasks

            todayCount = response.today.count
            upcomingCount = response.upcoming.count
            overdueCount = response.overdue.count
            noDueCount = response.noDue.count

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
        due: Date?,                 // optional
        repeatType: RepeatType?,    // optional
        categoryId: String,
        token: String
    ) async {
        isLoading = true
        errorMessage = nil

        if let due {
            let minimumDelay: TimeInterval = 60
            guard due.timeIntervalSinceNow > minimumDelay else {
                isLoading = false
                errorMessage = "Due time must be at least 1 minute from now."
                showErrorAlert = true
                return
            }
        }

        do {
            let newTask = try await TaskApi.createTask(
                title: title,
                due: due,
                repeatType: repeatType,
                categoryId: categoryId,
                token: token
            )

            // 🔔 schedule notification only if due exists
            if let due {
                NotificationManager.shared.scheduleTaskNotification(
                    id: newTask.id,
                    title: newTask.title,
                    dueDate: due
                )
            }

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
    
    // MARK: - FETCH TODAY TASKS
    func fetchTodayTasks(token:String) async{
        isLoading = true
        errorMessage = nil
        do{
            let response = try await TaskApi.fetchTodayTasks(token: token)
            allTodayTasks = response
        }catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }

            isLoading = false
            
        }
    
    // MARK: - FETCH UPCOMING TASKS
    func fetchUpcomingTasks(token:String) async{
        isLoading = true
        errorMessage = nil
        do{
            let response = try await TaskApi.fetchUpcomingTasks(token: token)
            allUpcomingTasks = response
        }catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }

            isLoading = false
            
        }
    
    // MARK: - FETCH OVERDUE TASKS
    func fetchOverdueTasks(token:String) async{
        isLoading = true
        errorMessage = nil
        do{
            let response = try await TaskApi.fetchOverdueTasks(token: token)
            allOverdueTasks = response
        }catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }

            isLoading = false
            
        }
    // MARK: - Fetch Tasks For Category
    func fetchTasksForCategory(token:String,categoryId:String) async{
        isLoading = true
        errorMessage = nil
        do{
            let response = try await TaskApi.fetchTasksForCategory(token: token, categoryId: categoryId)
            categoryTasks = response
        }catch {
                errorMessage = error.localizedDescription
                showErrorAlert = true
        }

            isLoading = false
    }
}
