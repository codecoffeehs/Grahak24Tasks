enum RepeatOption: String, CaseIterable, Identifiable {
    case none = "Never"
    case daily = "Every Day"
    case alternate = "Every Other Day"
    case weekly = "Every Week"
    case monthly = "Every Month"

    var id: String { rawValue }
}
