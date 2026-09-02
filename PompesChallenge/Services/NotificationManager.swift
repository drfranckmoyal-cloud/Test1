import Foundation
import UserNotifications

/// Programme les trois rappels quotidiens répétés tous les jours.
enum NotificationManager {

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    /// Efface les rappels existants et reprogramme ceux qui sont actifs.
    /// `shares` donne, par rappel, le texte de ce qu'il y a à faire.
    static func reschedule(reminders: [Reminder], tone: MotivationTone, shares: [UUID: String]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for slot in reminders.indices {
            let reminder = reminders[slot]
            guard reminder.isEnabled else { continue }

            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = Motivation.reminderBody(
                tone: tone,
                shares: shares[reminder.id] ?? "",
                slot: slot
            )
            content.sound = .default

            var components = DateComponents()
            components.hour = reminder.hour
            components.minute = reminder.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: reminder.id.uuidString,
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}
