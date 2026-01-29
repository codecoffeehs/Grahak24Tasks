import Foundation
import UserNotifications

final class NotificationManager: NSObject {

    static let shared = NotificationManager()
    private override init() {
        super.init()
    }

    // Call this once (e.g., at app launch) if you want foreground presentation.
    // Example:
    // NotificationManager.shared.configureNotificationCenterDelegate()
    func configureNotificationCenterDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }

    // Permission (already done)
    func requestPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            // If you do not plan to use badges, remove .badge
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
        content.title = "Reminder ⏰"
        content.body = title
        content.sound = .default
        // If you intend to use badge counts, set content.badge here.
        // content.badge = NSNumber(value: 1)
        // Add category if you support actions:
        // content.categoryIdentifier = "TASK_REMINDER"

        var triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: dueDate
        )
        // Ensure seconds exist to avoid truncation edge cases
        if triggerDate.second == nil {
            triggerDate.second = 0
        }

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification \(id): \(error.localizedDescription)")
            } else {
                print("✅ Scheduled notification \(id) for \(dueDate)")
            }
        }
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

// MARK: - Foreground presentation (optional)
extension NotificationManager: UNUserNotificationCenterDelegate {
    // Show banners when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Customize as needed: [.banner, .list, .sound, .badge]
        return [.banner, .sound]
    }

    // Handle action taps or notification taps if you add categories/actions
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Example for future actions:
        // let id = response.notification.request.identifier
        // switch response.actionIdentifier {
        // case "MARK_COMPLETE":
        //     // Trigger toggle via your store/API
        //     break
        // default:
        //     break
        // }
    }
}
