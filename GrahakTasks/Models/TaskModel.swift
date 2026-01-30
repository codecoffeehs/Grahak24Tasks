struct TaskModel: Identifiable, Codable {
    let id: String
    var title: String
    var description:String
    var isCompleted: Bool
    var due: String?            // now optional
    var repeatType: RepeatType? // now optional

    var categoryId: String
    var categoryTitle: String
    var color: String
    var icon: String
    
    var isCreator: Bool
}
