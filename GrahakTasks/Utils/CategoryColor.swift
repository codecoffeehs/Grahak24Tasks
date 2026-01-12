import SwiftUI

struct CategoryColorOption : Identifiable,Hashable {
    let hex: String
    let color: Color
    
    var id : String {hex}
}
let categoryColors: [CategoryColorOption] = [
    CategoryColorOption(hex: "#FF3B30", color: .red),
    CategoryColorOption(hex: "#007AFF", color: .blue),
    CategoryColorOption(hex: "#34C759", color: .green),
    CategoryColorOption(hex: "#FFCC00", color: .yellow),
    CategoryColorOption(hex: "#AF52DE", color: .purple)
]
