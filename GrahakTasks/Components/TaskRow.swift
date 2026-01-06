import SwiftUI

struct TaskRow: View {
    let title: String
    let due: String
    let isCompleted: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // 1. Completion Indicator
            Image(systemName: isCompleted ? "checkmark.circle" : "circle")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(isCompleted ? .green : .secondary.opacity(0.5))
                .symbolEffect(.bounce, value: isCompleted) // Animates when toggled
            
            VStack(alignment: .leading, spacing: 4) {
                // 2. Title with Strike-through logic
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .strikethrough(isCompleted, color: .secondary)
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .lineLimit(1)

                // 3. Status/Date Row
                HStack(spacing: 6) {
                    if let dueInfo = parseDueDate(from: due) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        
                        Text(dueInfo.text)
                    }
                }
                .font(.caption)
                .fontWeight(.medium)
                // Color logic: Completed = Gray, Overdue = Red, Upcoming = Secondary
                .foregroundColor(statusColor(for: due))
            }
            
            Spacer()
            
            // 4. Subtle Chevron to indicate it's a list item
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.accentColor)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Makes the whole row tappable
        .opacity(isCompleted ? 0.7 : 1.0)
    }

    // MARK: - Helper Logic
    
    private func statusColor(for dueString: String) -> Color {
        if isCompleted { return .secondary }
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dueString) else { return .secondary }
        return date < Date() ? .red : .secondary
    }

    private func parseDueDate(from dueString: String) -> (text: String, isOverdue: Bool)? {
        let formatter = ISO8601DateFormatter()
        guard let dueDate = formatter.date(from: dueString) else { return nil }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full
        let relative = relativeFormatter.localizedString(for: dueDate, relativeTo: Date())

        let isOverdue = dueDate < Date()
        let prefix = isOverdue ? "Overdue " : "Due "
        
        return (prefix + relative, isOverdue)
    }
}
