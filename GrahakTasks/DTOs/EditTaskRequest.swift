import Foundation

struct EditTaskRequestBody: Encodable {
    let title: String?
    let due: Date?
    let isCompleted: Bool?
    let repeatType: RepeatType?

    enum CodingKeys: String, CodingKey {
        case title
        case due
        case isCompleted
        case repeatType
    }
}
