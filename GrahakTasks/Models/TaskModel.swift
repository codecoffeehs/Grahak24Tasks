struct TaskModel: Codable, Identifiable {
    let id: String
    var title: String
    var isCompleted: Bool
    let due: String
    let repeatType: RepeatType

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case isCompleted
        case due
        case repeatType   
    }
}
