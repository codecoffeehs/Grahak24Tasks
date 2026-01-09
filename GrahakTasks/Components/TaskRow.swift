import SwiftUI

struct TaskRow: View {
    let title: String
    let due: String
    let isCompleted: Bool
    let repeatType: RepeatType

    var body: some View {
        HStack(alignment: .center, spacing: 16) {

            // 1. Completion Indicator
            Image(systemName: isCompleted ? "checkmark.seal.fill" : "xmark.seal")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isCompleted ? .green : .secondary.opacity(0.5))
                .symbolEffect(.bounce, value: isCompleted)

            VStack(alignment: .leading, spacing: 4) {

                // 2. Title
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .strikethrough(isCompleted, color: .secondary)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                // 3. Due Date (hidden when completed)
                if let dueInfo = DateParser.parseDueDate(from: due) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.caption2)

                        Text(dueInfo.text)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(dueInfo.isOverdue ? .red : .secondary)
                }
            }

            Spacer()

            // 4. Repeat Badge
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
                        .fill(repeatType.backgroundColor.opacity(0.15))
                )
                .foregroundColor(repeatType.color)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .opacity(isCompleted ? 0.7 : 1.0)
    }
}
