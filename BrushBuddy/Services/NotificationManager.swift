import Foundation
import UserNotifications

/// Schedules the twice-daily "time to brush" reminders.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()

    static let morningIdentifier = "brushbuddy.reminder.morning"
    static let nightIdentifier = "brushbuddy.reminder.night"

    private init() {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Ask for permission if we haven't yet. Returns whether notifications are allowed.
    @discardableResult
    func requestAuthorization() async -> Bool {
        let status = await authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    /// Bring scheduled reminders in line with the settings. Safe to call often.
    func sync(with settings: AppSettings) async {
        center.removePendingNotificationRequests(withIdentifiers: [NotificationManager.morningIdentifier, NotificationManager.nightIdentifier])
        guard settings.remindersEnabled else { return }
        guard await requestAuthorization() else { return }

        for slot in DaySlot.allCases {
            let minutes = settings.reminderMinutes(for: slot)
            var components = DateComponents()
            components.hour = minutes / 60
            components.minute = minutes % 60

            let content = UNMutableNotificationContent()
            content.title = slot == .morning ? "Good morning! Time to brush 🪥" : "Time for your night-time routine 🌙"
            // Advice in the copy: two minutes, spit don't rinse, clean between teeth — [NHS-clean] in DentalAdvice.swift.
            content.body = slot == .morning
                ? "Two minutes now sets your smile up for the whole day. Floss, brush, spit — don't rinse!"
                : "Clean between your teeth, brush for two minutes, and sleep with a fresh mouth."
            content.sound = .default
            content.interruptionLevel = .active

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let identifier = slot == .morning ? NotificationManager.morningIdentifier : NotificationManager.nightIdentifier
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
