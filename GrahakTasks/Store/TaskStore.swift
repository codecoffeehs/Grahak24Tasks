import Foundation
import Combine

@MainActor
class TaskStore: ObservableObject {

    @Published var tasks: [TaskModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false

    // MARK: - Fetch Recent Tasks
    func fetchRecentTasks(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await TaskApi.fetchRecentTasks(token: token)
            tasks = response
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }
    
    // MARK: - Fetch
    func fetchTasks(token: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await TaskApi.fetchTasks(token: token)
            tasks = response
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }

    // MARK: - Create
    func addTask(
        title: String,
        due: Date,
        repeatType:RepeatType,
        categoryId:String,
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

            // Insert at top (feels instant)
            tasks.insert(newTask, at: 0)
            
            // Schedule Notification
            NotificationManager.shared.scheduleTaskNotification(id: newTask.id, title: newTask.title, dueDate: due)

        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }

        isLoading = false
    }
    
    // MARK: - Toggle
    func toggleTask(
        id: String,
        token: String
    ) async {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }

        // Optimistic update
        tasks[index].isCompleted.toggle()

        do {
            let updated = try await TaskApi.toggleTask(
                taskId: id,
                token: token
            )
            tasks[index] = updated
        } catch {
            // Revert on failure
            tasks[index].isCompleted.toggle()
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
}
