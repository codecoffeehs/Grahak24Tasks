import SwiftUI

struct TaskRow: View {
    let title: String
    let due: String
    let isCompleted: Bool

    let repeatType: RepeatType

    let categoryTitle: String
    let categoryColor: String   // e.g. "blue", "green"
    let categoryIcon: String    // e.g. "folder"

    var body: some View {
        HStack(alignment: .center, spacing: 14) {

            // MARK: - Completion Indicator
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isCompleted ? .green : .secondary.opacity(0.5))
                .symbolEffect(.bounce, value: isCompleted)

            VStack(alignment: .leading, spacing: 6) {

                // MARK: - Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .strikethrough(isCompleted, color: .secondary)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                // MARK: - Meta Row (Due + Repeat + Category)
                HStack(spacing: 8) {

                    // Due
                    if let dueInfo = DateParser.parseDueDate(from: due) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)

                            Text(dueInfo.text)
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(dueInfo.isOverdue ? .red : .secondary)
                    }

                    // Repeat Badge (inline logic, no RepeatType extensions)
                    if repeatType != .none {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.clockwise")
                                .font(.caption2)

                            Text(repeatType.shortTitle)
                            .font(.caption2)
                            .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    ({
                                        switch repeatType {
                                        case .none: return Color.clear
                                        case .daily: return Color.blue.opacity(0.15)
                                        case .everyOtherDay: return Color.purple.opacity(0.15)
                                        case .weekly: return Color.green.opacity(0.15)
                                        case .monthly: return Color.orange.opacity(0.15)
                                        }
                                    }())
                                )
                        )
                        .foregroundColor(
                            ({
                                switch repeatType {
                                case .none: return .secondary
                                case .daily: return .blue
                                case .everyOtherDay: return .purple
                                case .weekly: return .green
                                case .monthly: return .orange
                                }
                            }())
                        )
                    }

                    // Category Chip (inline color mapping, no helper var)
                    HStack(spacing: 5) {
                        Image(systemName: categoryIcon)
                            .font(.caption2)

                        Text(categoryTitle)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
//                    .background(
//                        Capsule()
//                            .fill(CategoryColor(from: categoryColor).color)
//                    )
//                    .foregroundColor(
//                        CategoryColor(from: categoryColor).color
//                    )
                }
            }

            Spacer()
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .opacity(isCompleted ? 0.65 : 1.0)
    }
}
#Preview("TaskRow Variants") {
    List {
        TaskRow(
            title: "Pay electricity bill",
            due: "2026-01-10T10:30:00.000+00:00",
            isCompleted: false,
            repeatType: .monthly,
            categoryTitle: "Finance",
            categoryColor: "orange",
            categoryIcon: "creditcard"
        )

        TaskRow(
            title: "Gym Workout",
            due: "2026-01-10T17:00:00.000+00:00",
            isCompleted: false,
            repeatType: .daily,
            categoryTitle: "Health",
            categoryColor: "green",
            categoryIcon: "heart.fill"
        )

        TaskRow(
            title: "Call mom",
            due: "2026-01-09T08:00:00.000+00:00", // overdue
            isCompleted: false,
            repeatType: .none,
            categoryTitle: "Personal",
            categoryColor: "blue",
            categoryIcon: "person.fill"
        )

        TaskRow(
            title: "Submit assignment",
            due: "2026-01-12T12:00:00.000+00:00",
            isCompleted: true,
            repeatType: .weekly,
            categoryTitle: "Study",
            categoryColor: "purple",
            categoryIcon: "book.fill"
        )
    }
    .listStyle(.insetGrouped)
}

