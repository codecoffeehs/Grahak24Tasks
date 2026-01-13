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

                // Pills row: try single-line first, otherwise wrap.
                ViewThatFits(in: .horizontal) {

                    // ✅ 1-line layout (preferred)
                    HStack(spacing: 6) {
                        duePill
                        repeatPill
                        categoryPill
                    }

                    // ✅ Wrapped layout fallback
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            duePill
                            repeatPill
                        }

                        // if due/repeat are huge, category still stays clean
                        HStack(spacing: 6) {
                            categoryPill
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .opacity(isCompleted ? 0.55 : 1)
    }

    // MARK: - Pills (still inside same component)

    @ViewBuilder
    private var duePill: some View {
        if let dueInfo = DateParser.parseDueDate(from: due) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .medium))
                Text(dueInfo.text)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(dueInfo.isOverdue ? .red : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6), in: Capsule())
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    @ViewBuilder
    private var repeatPill: some View {
        if repeatType != .none {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .medium))
                Text(repeatType.shortTitle)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(repeatColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(repeatColor.opacity(0.12), in: Capsule())
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var categoryPill: some View {
        HStack(spacing: 4) {
            Image(systemName: categoryIcon)
                .font(.system(size: 11, weight: .medium))
            Text(categoryTitle)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
        .foregroundStyle(categoryColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(categoryColor.opacity(0.12), in: Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }
}
