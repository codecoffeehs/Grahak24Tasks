struct CategoryModel: Codable, Identifiable {
    let id: String
    var title: String
    var color: String
    var icon: String?
    var tasksCount: Int
}
