import Foundation
import Combine

@MainActor
class TaskStore: ObservableObject {

    // MARK: - Home Sections
    @Published var todayTasks: [TaskModel] = []
    @Published var upcomingTasks: [TaskModel] = []
    @Published var overdueTasks: [TaskModel] = []
    @Published var noDueTasks: [TaskModel] = []
    
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
    @Published var allTodayTasks: [TaskModel] = []
    @Published var allUpcomingTasks: [TaskModel] = []
    @Published var allOverdueTasks: [TaskModel] = []
    @Published var allNoDueTasks: [TaskModel] = []
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
        description:String,
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
                description:description,
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

    // MARK: - Toggle Task (Optimistic UI Update, keep position/section to avoid jitter)
    func toggleTask(
        id: String,
        token: String
    ) async {
        // 1) Optimistically flip isCompleted in place across all arrays, without moving items.
        func flipCompletionInPlace(for id: String) {
            func flip(in array: inout [TaskModel]) {
                if let idx = array.firstIndex(where: { $0.id == id }) {
                    array[idx].isCompleted.toggle()
                }
            }
            flip(in: &todayTasks)
            flip(in: &upcomingTasks)
            flip(in: &overdueTasks)
            flip(in: &noDueTasks)
            if let idx = tasks.firstIndex(where: { $0.id == id }) {
                tasks[idx].isCompleted.toggle()
            }
        }
        
        // Helper to replace an updated task in place (no reordering/moving)
        func updateInPlace(with updated: TaskModel) {
            func replace(in array: inout [TaskModel]) {
                if let idx = array.firstIndex(where: { $0.id == updated.id }) {
                    array[idx] = updated
                }
            }
            replace(in: &todayTasks)
            replace(in: &upcomingTasks)
            replace(in: &overdueTasks)
            replace(in: &noDueTasks)
            if let idx = tasks.firstIndex(where: { $0.id == updated.id }) {
                tasks[idx] = updated
            }
        }
        
        // Flip optimistically
        flipCompletionInPlace(for: id)
        // Recompute counts based on arrays currently displayed
        todayCount = todayTasks.count
        upcomingCount = upcomingTasks.count
        overdueCount = overdueTasks.count
        noDueCount = noDueTasks.count
        
        do {
            let updatedTask = try await TaskApi.toggleTask(taskId: id, token: token)
            
            // Notifications: cancel if completed, or reschedule if due exists and not completed
            NotificationManager.shared.cancelTaskNotification(id: id)
            if !updatedTask.isCompleted,
               let iso = updatedTask.due,
               let dueDate = ISO8601DateFormatter().date(from: iso) {
                NotificationManager.shared.scheduleTaskNotification(
                    id: updatedTask.id,
                    title: updatedTask.title,
                    dueDate: dueDate
                )
            }

            // 2) Update the task’s full data in place (still no moving)
            updateInPlace(with: updatedTask)

            // Keep counts aligned with visible arrays
            todayCount = todayTasks.count
            upcomingCount = upcomingTasks.count
            overdueCount = overdueTasks.count
            noDueCount = noDueTasks.count

            // Note: We intentionally do not reshuffle sections here to avoid jitter.
            // If you want to reconcile with backend sections later, call fetchRecentTasks
            // after a delay or on pull-to-refresh.

        } catch {
            // Rollback optimistic flip on error
            flipCompletionInPlace(for: id) // toggling again reverts
            todayCount = todayTasks.count
            upcomingCount = upcomingTasks.count
            overdueCount = overdueTasks.count
            noDueCount = noDueTasks.count
            
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    // Sectioning utility retained but no longer used by toggleTask to prevent jitter
    private enum TaskSection { case today, upcoming, overdue, noDue }
    private func getSection(for task: TaskModel) -> TaskSection {
        guard let dueString = task.due,
              let dueDate = ISO8601DateFormatter().date(from: dueString) else {
            return .noDue
        }
        let calendar = Calendar.current
        let now = Date()
        if dueDate < now {
            return .overdue
        } else if calendar.isDateInToday(dueDate) {
            return .today
        } else {
            return .upcoming
        }
    }
    
    // MARK: - Edit Task
    func editTask(
        taskId: String,
        title: String? = nil,
        description: String? = nil,
        due: Date? = nil,
        isCompleted: Bool? = nil,
        repeatType: RepeatType? = nil,
        taskCategoryId: String? = nil,
        token: String
    ) async throws -> TaskModel {
        isLoading = true
        errorMessage = nil
        
        // ✅ validate due date if provided
        if let due {
            let minimumDelay: TimeInterval = 180
            guard due.timeIntervalSinceNow > minimumDelay else {
                isLoading = false
                errorMessage = "Due time must be at least 3 minutes from now."
                showErrorAlert = true
                throw NSError(domain: "TaskStore", code: 400, userInfo: [NSLocalizedDescriptionKey: "Due time must be at least 3 minutes from now."])
            }
        }
        
        do {
            let updatedTask = try await TaskApi.editTask(
                taskId: taskId,
                title: title,
                description: description,
                due: due,
                isCompleted: isCompleted,
                repeatType: repeatType,
                taskCategoryId: taskCategoryId,
                token: token
            )
            
            // 🔔 Notifications handling (kept commented in original)
            // See SingleTaskView for notification handling after edit
            
            // ✅ refresh home sections
            await fetchRecentTasks(token: token)
            isLoading = false
            return updatedTask
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            showErrorAlert = true
            throw error
        }
    }

    // MARK: - Delete Task (Optimistic UI Update)
    func deleteTask(
        id: String,
        token: String
    ) async {
        // Optimistically remove task from UI
        todayTasks.removeAll { $0.id == id }
        upcomingTasks.removeAll { $0.id == id }
        overdueTasks.removeAll { $0.id == id }
        noDueTasks.removeAll { $0.id == id }
        tasks.removeAll { $0.id == id }
        
        todayCount = todayTasks.count
        upcomingCount = upcomingTasks.count
        overdueCount = overdueTasks.count
        noDueCount = noDueTasks.count

        NotificationManager.shared.cancelTaskNotification(id: id)
        
        do {
            try await TaskApi.deleteTask(taskId: id, token: token)
            // Success, nothing more to do.
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
            // Optionally re-fetch from backend if you want to revert the optimistic delete:
             await fetchRecentTasks(token: token)
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
    // MARK: - FETCH NODUE TASKS
    func fetchNoDueTasks(token:String) async{
        isLoading = true
        errorMessage = nil
        do{
            let response = try await TaskApi.fetchNoDueTasks(token: token)
            allNoDueTasks = response
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
