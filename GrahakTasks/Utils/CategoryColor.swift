import SwiftUI

enum CategoryColor: String, CaseIterable, Identifiable, Codable {
    case red
    case blue
    case green
    case orange
    case purple
    case pink
    case teal
    case yellow
    case brown
    case gray

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red:    return Color(red: 0.95, green: 0.26, blue: 0.21)
        case .blue:   return Color(red: 0.13, green: 0.48, blue: 0.95)
        case .green:  return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .orange: return Color(red: 1.00, green: 0.58, blue: 0.00)
        case .purple: return Color(red: 0.69, green: 0.32, blue: 0.87)
        case .pink:   return Color(red: 1.00, green: 0.18, blue: 0.58)
        case .teal:   return Color(red: 0.00, green: 0.72, blue: 0.78)
        case .yellow: return Color(red: 1.00, green: 0.84, blue: 0.00)
        case .brown:  return Color(red: 0.60, green: 0.40, blue: 0.20)
        case .gray:   return Color(red: 0.45, green: 0.45, blue: 0.50)
        }
    }
}
