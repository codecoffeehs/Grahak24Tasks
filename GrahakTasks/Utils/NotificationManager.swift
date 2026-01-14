import Foundation
import UserNotifications

class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    // Permission (already done)
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("❌ Notification permission error:", error)
        }
    }

    // ✅ Schedule notification
    func scheduleTaskNotification(
        id: String,
        title: String,
        dueDate: Date
    ) {
        let center = UNUserNotificationCenter.current()

        // Don't schedule notifications in the past
        guard dueDate > Date() else {
            print("⏭️ Skipping notification — due date is in the past")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"
        content.body = title
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dueDate
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }
    
    // ✅ Cancel single task notification
    func cancelTaskNotification(id: String) {
        let center = UNUserNotificationCenter.current()

        // removes scheduled notifications
        center.removePendingNotificationRequests(withIdentifiers: [id])

        // also removes already delivered banner from notification center (optional but nice)
        center.removeDeliveredNotifications(withIdentifiers: [id])

        print("🛑 Cancelled notification for task:", id)
    }

}
