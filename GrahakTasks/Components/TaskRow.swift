import SwiftUI

struct TaskRow: View {
    let title: String
    let due: String
    let isCompleted: Bool
    let repeatType: RepeatType
    let categoryTitle: String
    let colorHex: String
    let categoryIcon: String
    
    private var categoryColor: Color { Color(hex: colorHex) }
    
    private var repeatColor: Color {
        switch repeatType {
        case .none: return .clear
        case .daily: return .blue
        case .everyOtherDay: return .purple
        case .weekly: return .green
        case .monthly: return .orange
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isCompleted ? .green : .secondary.opacity(0.4))
                .padding(.top, 1)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted, color: .secondary.opacity(0.5))
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack(spacing: 6) {
                    if let dueInfo = DateParser.parseDueDate(from: due) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .medium))
                            Text(dueInfo.text)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(dueInfo.isOverdue ? .red : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6), in: Capsule())
                    }
                    
                    if repeatType != .none {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .medium))
                            Text(repeatType.shortTitle)
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(repeatColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(repeatColor.opacity(0.12), in: Capsule())
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: categoryIcon)
                            .font(.system(size: 11, weight: .medium))
                        Text(categoryTitle)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundStyle(categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.12), in: Capsule())
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .opacity(isCompleted ? 0.55 : 1)
    }
}

#Preview("Minimal Flat") {
    List {
        TaskRow(
            title: "Pay electricity bill",
            due: "2026-01-10T10:30:00.000+00:00",
            isCompleted: false,
            repeatType: .monthly,
            categoryTitle: "Finance",
            colorHex: "orange",
            categoryIcon: "creditcard"
        )
        TaskRow(
            title: "Very very long task title that should not destroy the UI anymore",
            due: "2026-01-09T08:00:00.000+00:00",
            isCompleted: false,
            repeatType: .daily,
            categoryTitle: "Personal Errands",
            colorHex: "blue",
            categoryIcon: "person.fill"
        )
        TaskRow(
            title: "Completed task example",
            due: "2026-01-08T14:00:00.000+00:00",
            isCompleted: true,
            repeatType: .weekly,
            categoryTitle: "Work",
            colorHex: "purple",
            categoryIcon: "briefcase.fill"
        )
    }
    .listStyle(.insetGrouped)
}
