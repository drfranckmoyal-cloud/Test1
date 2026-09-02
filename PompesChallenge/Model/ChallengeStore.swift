import Foundation
import SwiftUI

/// Source de vérité de l'application : le défi, ses exercices, les jours,
/// les rappels. Une journée court de minuit à minuit : chaque total est rangé
/// sous la clé "yyyy-MM-dd" du jour local, donc le compteur repart de zéro
/// tout seul. Un jour est validé quand TOUS les exercices ont atteint
/// leur objectif.
@MainActor
final class ChallengeStore: ObservableObject {

    @Published private(set) var state: ChallengeState
    /// Minuit du jour courant. Recalculé au retour au premier plan.
    @Published private(set) var today: Date
    /// Non nil quand la journée vient d'être bouclée.
    @Published var celebration: Celebration?

    private let storageKey = "pompes.challenge.state.v2"
    private let legacyKey = "pompes.challenge.state.v1"
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
        } else if let data = defaults.data(forKey: legacyKey),
                  let legacy = try? JSONDecoder().decode(LegacyState.self, from: data) {
            self.state = legacy.migrated()
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

    var exercises: [Exercise] { state.exercises }
    var durationDays: Int { state.durationDays }
    var reminders: [Reminder] { state.reminders }
    var tone: MotivationTone { state.tone }
    var appearance: Appearance { state.appearance }

    func count(_ kind: ExerciseKind, on date: Date) -> Int {
        state.logs[key(for: date)]?[kind.rawValue] ?? 0
    }

    func todayCount(_ kind: ExerciseKind) -> Int { count(kind, on: today) }

    func remaining(_ exercise: Exercise, on date: Date) -> Int {
        max(0, exercise.dailyGoal - count(exercise.kind, on: date))
    }

    func progress(_ exercise: Exercise, on date: Date) -> Double {
        guard exercise.dailyGoal > 0 else { return 1 }
        return min(1.0, Double(count(exercise.kind, on: date)) / Double(exercise.dailyGoal))
    }

    /// Avancement de la journée : moyenne des exercices du défi.
    func dayProgress(on date: Date) -> Double {
        guard !state.exercises.isEmpty else { return 0 }
        let sum = state.exercises.reduce(0.0) { $0 + progress($1, on: date) }
        return sum / Double(state.exercises.count)
    }

    func isValidated(on date: Date) -> Bool {
        guard !state.exercises.isEmpty else { return false }
        return state.exercises.allSatisfy { count($0.kind, on: date) >= $0.dailyGoal }
    }

    func totalReps(on date: Date) -> Int {
        state.exercises.reduce(0) { $0 + count($1.kind, on: date) }
    }

    var todayProgress: Double { dayProgress(on: today) }

    /// L'exercice le plus en retard aujourd'hui, pour le message de motivation.
    var focusExercise: Exercise? {
        state.exercises
            .filter { remaining($0, on: today) > 0 }
            .max { remaining($0, on: today) < remaining($1, on: today) }
    }

    /// Numéro du jour courant dans le défi (1...durée), borné aux deux extrémités.
    var dayIndex: Int { min(max(rawDayIndex, 1), state.durationDays) }

    /// Vrai quand tous les jours du défi sont écoulés.
    var isFinished: Bool { rawDayIndex > state.durationDays }

    private var rawDayIndex: Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: state.startDate)
        let elapsed = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return elapsed + 1
    }

    /// Les cases du calendrier, dans l'ordre.
    var days: [DayCell] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: state.startDate)
        return (0..<state.durationDays).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start) ?? start
            let status: DayStatus
            if isValidated(on: date) {
                status = .validated
            } else if calendar.isDate(date, inSameDayAs: today) {
                status = .today
            } else if date < today {
                status = .missed
            } else {
                status = .upcoming
            }
            return DayCell(id: offset + 1, date: date, totalReps: totalReps(on: date),
                           status: status, progress: dayProgress(on: date))
        }
    }

    var validatedCount: Int { days.filter { $0.status == .validated }.count }

    var challengeProgress: Double {
        guard state.durationDays > 0 else { return 0 }
        return Double(validatedCount) / Double(state.durationDays)
    }

    var totalReps: Int { days.reduce(0) { $0 + $1.totalReps } }

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

    /// Les 7 derniers jours jusqu'à aujourd'hui (écran de célébration).
    var lastSevenDays: [DayCell] {
        let all = days
        let end = min(max(dayIndex, 1), all.count)
        let start = max(0, end - 7)
        return Array(all[start..<end])
    }

    func index(for date: Date) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: state.startDate)
        let elapsed = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: date)).day ?? 0
        return elapsed + 1
    }

    /// « 30 pompes, 6 tractions, 45 abdos » pour un créneau donné.
    func shareText(for reminder: Reminder) -> String {
        state.exercises.map { exercise in
            let share = max(1, Int((Double(exercise.dailyGoal) * reminder.weight).rounded()))
            return "\(share) \(exercise.kind.unit)"
        }
        .joined(separator: ", ")
    }

    // MARK: - Écriture

    func add(_ amount: Int, to kind: ExerciseKind) {
        setCount(count(kind, on: today) + amount, kind: kind, for: today)
    }

    func setCount(_ amount: Int, kind: ExerciseKind, for date: Date) {
        let dayKey = key(for: date)
        let wasValidated = isValidated(on: date)

        var dayLog = state.logs[dayKey] ?? [:]
        dayLog[kind.rawValue] = min(max(amount, 0), 9999)
        state.logs[dayKey] = dayLog
        save()

        if isValidated(on: date), !wasValidated, !state.celebrated.contains(dayKey) {
            state.celebrated.insert(dayKey)
            save()
            celebration = Celebration(
                dayIndex: index(for: date),
                durationDays: state.durationDays,
                streak: currentStreak,
                total: totalReps,
                summary: state.exercises.map { "\(count($0.kind, on: date)) \($0.kind.unit)" }
            )
        }
    }

    func resetToday() {
        for exercise in state.exercises {
            setCount(0, kind: exercise.kind, for: today)
        }
    }

    func setGoal(_ goal: Int, for kind: ExerciseKind) {
        guard let index = state.exercises.firstIndex(where: { $0.kind == kind }) else { return }
        state.exercises[index].dailyGoal = min(max(goal, 1), kind.maxGoal)
        save()
        syncNotifications()
    }

    func setTone(_ tone: MotivationTone) {
        state.tone = tone
        save()
        syncNotifications()
    }

    func setAppearance(_ appearance: Appearance) {
        state.appearance = appearance
        save()
    }

    func update(_ reminder: Reminder) {
        guard let index = state.reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        state.reminders[index] = reminder
        save()
        syncNotifications()
    }

    /// Démarre un nouveau défi aujourd'hui. L'historique précédent est effacé.
    func startChallenge(durationDays: Int, exercises: [Exercise]) {
        guard !exercises.isEmpty else { return }
        state.startDate = Calendar.current.startOfDay(for: Date())
        state.durationDays = min(max(durationDays, 1), 365)
        state.exercises = exercises
        state.logs = [:]
        state.celebrated = []
        celebration = nil
        save()
        syncNotifications()
    }

    // MARK: - Rappels système

    func syncNotifications() {
        let reminders = state.reminders
        let tone = state.tone
        let shares = state.reminders.reduce(into: [UUID: String]()) { result, reminder in
            result[reminder.id] = shareText(for: reminder)
        }
        Task {
            await NotificationManager.reschedule(reminders: reminders, tone: tone, shares: shares)
        }
    }

    // MARK: - Persistance

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

// MARK: - Reprise de l'ancien format (défi à un seul exercice)

private struct LegacyReminder: Codable {
    var id: UUID
    var title: String
    var hour: Int
    var minute: Int
    var share: Int
    var isEnabled: Bool
}

private struct LegacyState: Codable {
    var startDate: Date
    var dailyGoal: Int
    var durationDays: Int
    var logs: [String: Int]
    var reminders: [LegacyReminder]
    var tone: MotivationTone
    var celebrated: Set<String>

    func migrated() -> ChallengeState {
        let weights: [Double] = [0.30, 0.35, 0.35]
        let fallbackWeight = 1.0 / Double(max(reminders.count, 1))
        var converted: [Reminder] = []
        for index in reminders.indices {
            let reminder = reminders[index]
            converted.append(
                Reminder(id: reminder.id, title: reminder.title, hour: reminder.hour,
                         minute: reminder.minute,
                         weight: index < weights.count ? weights[index] : fallbackWeight,
                         isEnabled: reminder.isEnabled)
            )
        }
        let convertedLogs = logs.mapValues { [ExerciseKind.pushups.rawValue: $0] }
        return ChallengeState(
            startDate: startDate,
            durationDays: durationDays,
            exercises: [Exercise(kind: .pushups, dailyGoal: dailyGoal)],
            logs: convertedLogs,
            reminders: converted.isEmpty ? Reminder.defaults : converted,
            tone: tone,
            appearance: .light,
            celebrated: celebrated
        )
    }
}
