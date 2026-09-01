import Foundation
import SwiftUI

/// Source de vérité de l'application : le défi, les jours, les rappels.
/// Une journée court de minuit à minuit : chaque total est rangé sous la
/// clé "yyyy-MM-dd" du jour local, donc le compteur repart de zéro tout seul.
@MainActor
final class ChallengeStore: ObservableObject {

    @Published private(set) var state: ChallengeState
    /// Minuit du jour courant. Recalculé au retour au premier plan.
    @Published private(set) var today: Date
    /// Non nil quand l'objectif du jour vient d'être atteint.
    @Published var celebration: Celebration?

    private let storageKey = "pompes.challenge.state.v1"
    private let defaults: UserDefaults

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let startOfToday = Calendar.current.startOfDay(for: Date())
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(ChallengeState.self, from: data) {
            self.state = decoded
        } else {
            self.state = ChallengeState(startDate: startOfToday)
        }
        self.today = startOfToday
    }

    // MARK: - Clés de jour

    private func key(for date: Date) -> String {
        Self.dayFormatter.timeZone = TimeZone.current
        return Self.dayFormatter.string(from: date)
    }

    /// À appeler au lancement, au retour au premier plan et toutes les minutes :
    /// c'est ce qui fait basculer l'app sur le jour suivant à minuit.
    func refreshDate() {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        if startOfToday != today {
            today = startOfToday
        }
    }

    // MARK: - Lecture

    var goal: Int { state.dailyGoal }
    var durationDays: Int { state.durationDays }
    var reminders: [Reminder] { state.reminders }
    var tone: MotivationTone { state.tone }

    var todayCount: Int { state.logs[key(for: today)] ?? 0 }

    var todayProgress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(todayCount) / Double(goal))
    }

    var remainingToday: Int { max(0, goal - todayCount) }

    /// Numéro du jour courant dans le défi (1...30), borné aux deux extrémités.
    var dayIndex: Int {
        min(max(rawDayIndex, 1), state.durationDays)
    }

    /// Vrai quand les 30 jours sont écoulés.
    var isFinished: Bool { rawDayIndex > state.durationDays }

    private var rawDayIndex: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: state.startDate)
        let elapsed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return elapsed + 1
    }

    /// Les 30 cases du calendrier, dans l'ordre.
    var days: [DayCell] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: state.startDate)
        return (0..<state.durationDays).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            let count = state.logs[key(for: date)] ?? 0
            let status: DayStatus
            if count >= state.dailyGoal {
                status = .validated
            } else if calendar.isDate(date, inSameDayAs: today) {
                status = .today
            } else if date < today {
                status = .missed
            } else {
                status = .upcoming
            }
            let progress = state.dailyGoal > 0
                ? min(1.0, Double(count) / Double(state.dailyGoal))
                : 0
            return DayCell(id: offset + 1, date: date, count: count, status: status, progress: progress)
        }
    }

    var validatedCount: Int { days.filter { $0.status == .validated }.count }

    var monthProgress: Double {
        guard state.durationDays > 0 else { return 0 }
        return Double(validatedCount) / Double(state.durationDays)
    }

    var totalPushups: Int { days.reduce(0) { $0 + $1.count } }

    /// Jours validés d'affilée jusqu'à aujourd'hui. Un jour en cours mais pas
    /// encore terminé ne casse pas la série — il ne la prolonge pas non plus.
    var currentStreak: Int {
        var streak = 0
        for cell in days.reversed() {
            if cell.date > today { continue }
            switch cell.status {
            case .validated: streak += 1
            case .today: continue
            default: return streak
            }
        }
        return streak
    }

    var bestStreak: Int {
        var best = 0
        var run = 0
        for cell in days {
            switch cell.status {
            case .validated:
                run += 1
                best = max(best, run)
            case .today:
                continue
            default:
                run = 0
            }
        }
        return best
    }

    /// Les 7 derniers jours jusqu'à aujourd'hui (pour l'écran de célébration).
    var lastSevenDays: [DayCell] {
        let all = days
        let end = min(max(dayIndex, 1), all.count)
        let start = max(0, end - 7)
        return Array(all[start..<end])
    }

    func count(for date: Date) -> Int { state.logs[key(for: date)] ?? 0 }

    func index(for date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: state.startDate)
        let elapsed = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: date)).day ?? 0
        return elapsed + 1
    }

    // MARK: - Écriture

    func add(_ amount: Int) {
        setCount(todayCount + amount, for: today)
    }

    func setCount(_ amount: Int, for date: Date) {
        let dayKey = key(for: date)
        let previous = state.logs[dayKey] ?? 0
        let value = min(max(amount, 0), 999)
        state.logs[dayKey] = value
        save()

        let justCompleted = value >= state.dailyGoal && previous < state.dailyGoal
        if justCompleted && !state.celebrated.contains(dayKey) {
            state.celebrated.insert(dayKey)
            save()
            celebration = Celebration(
                dayIndex: index(for: date),
                count: value,
                streak: currentStreak,
                total: totalPushups,
                durationDays: state.durationDays
            )
        }
    }

    func resetToday() {
        setCount(0, for: today)
    }

    func setGoal(_ goal: Int) {
        state.dailyGoal = min(max(goal, 10), 500)
        rebalanceShares()
        save()
        syncNotifications()
    }

    func setTone(_ tone: MotivationTone) {
        state.tone = tone
        save()
        syncNotifications()
    }

    func update(_ reminder: Reminder) {
        guard let index = state.reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        state.reminders[index] = reminder
        save()
        syncNotifications()
    }

    /// Repart à zéro à la date du jour, en gardant rappels et réglages.
    func restart() {
        state.startDate = Calendar.current.startOfDay(for: Date())
        state.logs = [:]
        state.celebrated = []
        celebration = nil
        save()
    }

    /// Répartit l'objectif sur les trois créneaux (30 % / 35 % / 35 %).
    private func rebalanceShares() {
        let weights: [Double] = [0.30, 0.35, 0.35]
        guard state.reminders.count == weights.count else { return }
        var assigned = 0
        for index in state.reminders.indices {
            if index == state.reminders.count - 1 {
                state.reminders[index].share = max(0, state.dailyGoal - assigned)
            } else {
                let share = Int((Double(state.dailyGoal) * weights[index]).rounded())
                state.reminders[index].share = share
                assigned += share
            }
        }
    }

    // MARK: - Rappels système

    func syncNotifications() {
        let reminders = state.reminders
        let tone = state.tone
        let goal = state.dailyGoal
        Task {
            await NotificationManager.reschedule(reminders: reminders, tone: tone, goal: goal)
        }
    }

    // MARK: - Persistance

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
