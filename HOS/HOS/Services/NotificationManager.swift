import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    @Published private(set) var isAuthorized = false
    @Published private(set) var lastError: String?

    func refresh() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            isAuthorized = true
        default:
            isAuthorized = false
        }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            lastError = granted ? nil : "Notification permission denied."
            return granted
        } catch {
            lastError = error.localizedDescription
            isAuthorized = false
            return false
        }
    }

    func scheduleLocalSmokeTest() async {
        guard isAuthorized else {
            lastError = "Notifications are not authorized."
            return
        }
        let content = UNMutableNotificationContent()
        content.title = "HOS"
        content.body = "Local notification test — data stays on device."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        do {
            try await UNUserNotificationCenter.current().add(request)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
