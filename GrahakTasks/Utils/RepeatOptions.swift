import Foundation

enum RepeatType: Int, Codable, CaseIterable, Identifiable {
    case none = 0
    case daily = 1
    case everyOtherDay = 2
    case weekly = 3
    case monthly = 4

    var id: Int { rawValue }

    // UI label
    var title: String {
        switch self {
        case .none: return "Never"
        case .daily: return "Every Day"
        case .everyOtherDay: return "Every Other Day"
        case .weekly: return "Every Week"
        case .monthly: return "Every Month"
        }
    }

    // short labels (optional)
    var shortTitle: String {
        switch self {
        case .none: return "Never"
        case .daily: return "Daily"
        case .everyOtherDay: return "Alt"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}
