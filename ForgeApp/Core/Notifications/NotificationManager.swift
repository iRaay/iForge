import UserNotifications
import UIKit

final class NotificationManager: NSObject {
    static let shared = NotificationManager()
    static let enabledKey = "notificationsEnabled"

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: Self.enabledKey) == nil
            ? true
            : UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func notifyBuildFinished(repository: String, branch: String, succeeded: Bool, runId: Int) {
        guard isEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = succeeded ? String(localized: "Build Succeeded") : String(localized: "Build Failed")
        content.body = String(format: String(localized: "%@ · branch %@"), repository, branch)
        content.sound = .default
        let request = UNNotificationRequest(identifier: "build-\(runId)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
