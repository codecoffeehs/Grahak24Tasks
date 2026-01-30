import SwiftUI

struct TaskRow: View {
    let title: String
    let description: String
    let due: String?                  // optional
    let isCompleted: Bool
    let repeatType: RepeatType?       // optional
    let categoryTitle: String
    let colorHex: String
    let categoryIcon: String

    private var categoryColor: Color { Color(hex: colorHex) }

    private var repeatColor: Color {
        switch repeatType ?? .none {
        case .none: return .clear
        case .daily: return .blue
        case .everyOtherDay: return .purple
        case .weekly: return .green
        case .monthly: return .orange
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status indicator: non-interactive ring for incomplete, filled icon for complete
            statusIndicator
                .padding(.top, 2)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                // Title with subtle strike-through when completed
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted, color: .secondary.opacity(0.45))
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Description: single line with truncation
                if !description.isEmpty {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                // Metadata chips
                ViewThatFits(in: .horizontal) {
                    // Preferred single-line
                    HStack(spacing: 8) {
                        dueChip
                        repeatChip
                        categoryChip
                    }

                    // Wrapped fallback
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            dueChip
                            repeatChip
                        }
                        HStack(spacing: 8) {
                            categoryChip
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .opacity(isCompleted ? 0.55 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    // MARK: - Status Indicator

    private var statusIndicator: some View {
        Group {
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.green.opacity(0.92))
                    .shadow(color: .black.opacity(0.05), radius: 0.5, x: 0, y: 0)
            } else {
                // Non-tappable look: a thin ring with tertiary style
                Circle()
                    .strokeBorder(Color.secondary.opacity(0.35), lineWidth: 1.75)
                    .frame(width: 20, height: 20)
                    .overlay(
                        // Inner subtle fill to avoid reading as a button
                        Circle()
                            .fill(Color.secondary.opacity(0.06))
                    )
            }
        }
    }

    // MARK: - Minimal Chips

    @ViewBuilder
    private var dueChip: some View {
        if let due, let dueInfo = DateParser.parseDueDate(from: due) {
            HStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 11, weight: .semibold))
                Text(dueInfo.text)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(dueInfo.isOverdue ? .red : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(chipBackground(for: dueInfo.isOverdue ? .red : .secondary))
            )
            .overlay(
                Capsule()
                    .stroke(chipStroke(for: dueInfo.isOverdue ? .red : .secondary), lineWidth: 0.5)
            )
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel(dueInfo.isOverdue ? "Overdue, \(dueInfo.text)" : dueInfo.text)
        }
    }

    @ViewBuilder
    private var repeatChip: some View {
        if let repeatType, repeatType != .none {
            HStack(spacing: 4) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11, weight: .semibold))
                Text(repeatType.shortTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(repeatColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(chipBackground(for: repeatColor))
            )
            .overlay(
                Capsule()
                    .stroke(chipStroke(for: repeatColor), lineWidth: 0.5)
            )
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityLabel("Repeats \(repeatType.title)")
        }
    }

    private var categoryChip: some View {
        HStack(spacing: 4) {
            Image(systemName: categoryIcon)
                .font(.system(size: 11, weight: .semibold))
            Text(categoryTitle)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(categoryColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(chipBackground(for: categoryColor))
        )
        .overlay(
            Capsule()
                .stroke(chipStroke(for: categoryColor), lineWidth: 0.5)
        )
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("Category \(categoryTitle)")
    }

    // Shared chips (only used when sharedWithCount > 0)
    private var sharedChip: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("Shared")
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
        .foregroundStyle(categoryColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(chipBackground(for: categoryColor))
        )
        .overlay(
            Capsule()
                .stroke(chipStroke(for: categoryColor), lineWidth: 0.5)
        )
        .fixedSize(horizontal: true, vertical: false)
        .accessibilityLabel("Shared")
    }

    // MARK: - Chip styling helpers

    private func chipBackground(for color: Color) -> Color {
        // Soft, adaptive background using the color at low opacity
        color.opacity(0.10)
    }

    private func chipStroke(for color: Color) -> Color {
        // Very subtle outline to keep definition without heaviness
        color.opacity(0.18)
    }

    // MARK: - Accessibility Summary

    private var accessibilitySummary: String {
        var parts: [String] = []
        parts.append(isCompleted ? "Completed" : "Not completed")
        parts.append(title)

        if let due, let info = DateParser.parseDueDate(from: due) {
            parts.append(info.text)
        }

        if let repeatType, repeatType != .none {
            parts.append("Repeats \(repeatType.title)")
        }

        parts.append("Category \(categoryTitle)")
        return parts.joined(separator: ", ")
    }
}
