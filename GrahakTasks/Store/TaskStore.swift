import Foundation
import Combine

@MainActor
class TaskStore: ObservableObject {

    @Published var tasks: [TaskModel] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showErrorAlert: Bool = false

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
    
    // MARK:- ADD TASK
    func addTask(
        title: String,
        due: Date,
        repeatType: RepeatType,
        token: String
    ) async {
        isLoading = true
        errorMessage = nil

        do {
            let newTask = try await TaskApi.createTask(
                title: title,
                due: due,
                repeatType: repeatType,
                token: token
            )

//            tasks.insert(newTask, at: 0)
            tasks.append(newTask)
//            sortTasksLikeBackend()

            // 🔔 schedule notification (later: repeating logic)
            NotificationManager.shared.scheduleTaskNotification(
                id: newTask.id,
                title: newTask.title,
                dueDate: due
            )

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
            NotificationManager.shared.cancelNotification(id: id)
//            sortTasksLikeBackend()
        } catch {
            // Revert on failure
            tasks[index].isCompleted.toggle()
            sortTasksLikeBackend()
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    // MARK: - Delete
    func deleteTask(
        id: String,
        token: String
    ) async {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }

        // Keep a backup for rollback
        let deletedTask = tasks[index]

        // ✅ Optimistic UI update
        tasks.remove(at: index)

        do {
            try await TaskApi.deleteTask(
                taskId: id,
                token: token
            )

            // cancel notification
            NotificationManager.shared.cancelNotification(id: id)

        } catch {
            // ❌ Rollback on failure
            tasks.insert(deletedTask, at: index)
            sortTasksLikeBackend()
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    private func sortTasksLikeBackend() {
        tasks.sort {
            if $0.isCompleted != $1.isCompleted {
                return !$0.isCompleted
            }
            if $0.due != $1.due {
                return $0.due < $1.due
            }
            if $0.repeatType != $1.repeatType {
                return $0.repeatType.rawValue < $1.repeatType.rawValue
            }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

}
