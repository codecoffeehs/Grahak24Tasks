import SwiftUI

enum CategoryColor: String, CaseIterable, Identifiable {
    case blue
    case green
    case orange
    case red
    case purple
    case gray

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .gray: return .gray
        }
    }
}
