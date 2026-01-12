struct TaskModel: Identifiable, Codable {
    let id: String
    var title: String
    var isCompleted: Bool
    var due: String

    var repeatType: RepeatType

    var categoryId: String
    var categoryTitle: String
    var categoryColor: String
    var categoryIcon: String
}
