import Foundation
import UserNotifications

/// Programme les rappels quotidiens.
///
/// Plutôt qu'un rappel répété à l'infini — qui afficherait éternellement le
/// même texte — on programme une notification par jour sur une fenêtre
/// glissante. Chaque jour reçoit ainsi sa propre phrase, et la fenêtre est
/// repoussée à chaque lancement de l'app.
enum NotificationManager {

    /// iOS ne garde que 64 notifications en attente : 20 jours x 3 rappels
    /// laissent une marge confortable.
    private static let scheduledDays = 20

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

    /// Efface les rappels existants et reprogramme la fenêtre.
    /// `shares` donne, par rappel, le texte de ce qu'il y a à faire.
    static func reschedule(reminders: [Reminder], tone: MotivationTone, shares: [UUID: String]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

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

                // Un créneau déjà passé aujourd'hui n'est pas reprogrammé.
                guard let fireDate = calendar.date(from: components), fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = reminder.title
                content.body = Motivation.reminderBody(
                    tone: tone,
                    shares: shares[reminder.id] ?? "",
                    slot: slot,
                    seed: dayOffset &* 7 &+ slot
                )
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: "\(reminder.id.uuidString)-\(dayOffset)",
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                )
                try? await center.add(request)
            }
        }
    }
}
