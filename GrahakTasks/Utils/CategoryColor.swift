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

    // Derived SwiftUI Color from hex
    var color: Color {
        Color(hex: hex)
    }

    // Optional: map to Apple semantic colors for consistent use elsewhere
    // If no close match, fall back to the hex color.
    var semanticColor: Color {
        switch hex.uppercased() {
        case "#FF3B30": return .red            // System Red
        case "#FF453A": return .red            // iOS 13+ variant
        case "#FF9500": return .orange         // System Orange
        case "#FF9F0A": return .orange
        case "#FFCC00": return .yellow         // System Yellow
        case "#FFD60A": return .yellow
        case "#34C759": return .green          // System Green
        case "#30D158": return .green
        case "#007AFF": return .blue           // System Blue
        case "#0A84FF": return .blue
        case "#5856D6": return .indigo         // System Indigo (approx)
        case "#5E5CE6": return .indigo
        case "#AF52DE": return .purple         // System Purple
        case "#BF5AF2": return .purple
        case "#FF2D55": return .pink           // System Pink
        case "#FF375F": return .pink
        case "#64D2FF": return .cyan           // System Cyan (approx)
        case "#32ADE6": return .teal           // System Teal (approx)
        case "#8E8E93": return .gray           // System Gray
        case "#6D6D72": return .gray
        case "#AC8E68": return .brown          // System Brown (approx)
        default:
            return color
        }
    }
}

// MARK: - Colors list
// Expanded Apple-like palette with common system tones and close hex equivalents.
// You can reorder to your preference.
let categoryColors: [CategoryColorOption] = [
    // Reds / Oranges / Yellows
    CategoryColorOption(hex: "#FF3B30"), // System Red
    CategoryColorOption(hex: "#FF9500"), // System Orange
    CategoryColorOption(hex: "#FFCC00"), // System Yellow

    // Greens
    CategoryColorOption(hex: "#34C759"), // System Green

    // Blues
    CategoryColorOption(hex: "#007AFF"), // System Blue
    CategoryColorOption(hex: "#0A84FF"), // System Blue (alt)
    CategoryColorOption(hex: "#64D2FF"), // System Cyan (light)

    // Teal / Indigo
    CategoryColorOption(hex: "#32ADE6"), // System Teal (approx)
    CategoryColorOption(hex: "#5856D6"), // System Indigo

    // Purples / Pinks
    CategoryColorOption(hex: "#AF52DE"), // System Purple
    CategoryColorOption(hex: "#FF2D55"), // System Pink


    // Neutrals / Browns
    CategoryColorOption(hex: "#8E8E93"), // System Gray
    CategoryColorOption(hex: "#6D6D72"), // System Gray (dark)
    CategoryColorOption(hex: "#AC8E68")  // System Brown (approx)
]
