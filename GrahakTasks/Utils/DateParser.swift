import Foundation

public struct DateParser {

    /// Parses an ISO8601 due date string into relative text and overdue status.
    ///
    /// - Parameter dueString: ISO8601 formatted date string.
    /// - Returns: `(text: String, isOverdue: Bool)` or `nil` if parsing fails.
    public static func parseDueDate(
        from dueString: String,
        referenceDate: Date = Date()
    ) -> (text: String, isOverdue: Bool)? {

        let formatter = ISO8601DateFormatter()
        guard let dueDate = formatter.date(from: dueString) else {
            return nil
        }

        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full

        let relative = relativeFormatter.localizedString(
            for: dueDate,
            relativeTo: referenceDate
        )

        let isOverdue = dueDate < referenceDate
        let prefix = isOverdue ? "Overdue " : "Due "

        return (prefix + relative, isOverdue)
    }
    
    /// NEW: Converts an ISO8601 date string into "moments ago / 2 days ago / 3 days ago".
    public static func timeAgo(
            from isoString: String,
            referenceDate: Date = Date()
        ) -> String? {

            let formatter = ISO8601DateFormatter()
            guard let date = formatter.date(from: isoString) else {
                return nil
            }

            let relativeFormatter = RelativeDateTimeFormatter()
            relativeFormatter.unitsStyle = .full

            // For past dates => "2 days ago", for very recent => "moments ago"
            let relative = relativeFormatter.localizedString(
                for: date,
                relativeTo: referenceDate
            )

            return relative
        }
}
