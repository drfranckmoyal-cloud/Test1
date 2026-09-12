import Foundation
import UserNotifications

/// Une notification par jour sur une fenêtre glissante, plutôt qu'un rappel
/// répété : c'est ce qui permet à chaque jour d'avoir son propre texte.
enum NotificationManager {

    private static let scheduledDays = 20   // 20 jours x 3 rappels, sous la limite de 64 d'iOS

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

    static func reschedule(reminders: [Reminder], tone: MotivationTone, sessionLabel: String) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard !sessionLabel.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)

        for dayOffset in 0..<scheduledDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: startOfToday) else { continue }
            let ymd = calendar.dateComponents([.year, .month, .day], from: day)

            for slot in reminders.indices {
                let reminder = reminders[slot]
                guard reminder.isEnabled else { continue }

                var components = DateComponents()
                components.year = ymd.year
                components.month = ymd.month
                components.day = ymd.day
                components.hour = reminder.hour
                components.minute = reminder.minute
                guard let fireDate = calendar.date(from: components), fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = reminder.title
                content.body = Motivation.reminderBody(tone: tone, sessionLabel: sessionLabel,
                                                       slot: slot, seed: dayOffset &* 7 &+ slot)
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: "\(reminder.id.uuidString)-\(dayOffset)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
                try? await center.add(request)
            }
        }
    }
}
