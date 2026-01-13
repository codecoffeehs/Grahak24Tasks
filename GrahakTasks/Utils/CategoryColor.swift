import SwiftUI

// MARK: - Hex -> Color converter
extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        let int = Int(hex, radix: 16) ?? 0

        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Model
struct CategoryColorOption: Identifiable, Hashable {
    let hex: String
    var id: String { hex }

    // derived color (like computed style in JS)
    var color: Color {
        Color(hex: hex)
    }
}

// MARK: - Colors list
let categoryColors: [CategoryColorOption] = [
    CategoryColorOption(hex: "#FF3B30"),
    CategoryColorOption(hex: "#007AFF"),
    CategoryColorOption(hex: "#34C759"),
    CategoryColorOption(hex: "#FFCC00"),
    CategoryColorOption(hex: "#AF52DE")
]
