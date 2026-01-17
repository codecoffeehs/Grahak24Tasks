import Foundation

struct RecentTasksResponse: Codable {
    let today: TaskSection
    let upcoming: TaskSection
    let overdue: TaskSection
    let noDue : TaskSection
}

struct TaskSection: Codable {
    let count: Int
    let tasks: [TaskModel]
}
