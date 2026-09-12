import Foundation

// MARK: - Une contribution

/// Ce que l'utilisateur a réellement fait, à un moment donné.
///
/// Une prescription peut en recevoir plusieurs : c'est le fractionnement.
/// Chaque contribution est horodatée, modifiable et supprimable.
struct ProgressEntry: Identifiable, Codable, Equatable {
    enum Source: String, Codable {
        case manual, timer, healthKit, workout

        var label: String {
            switch self {
            case .manual: return "Saisi"
            case .timer: return "Minuteur"
            case .healthKit: return "Santé"
            case .workout: return "Séance"
            }
        }
    }

    var id: UUID = UUID()
    var prescriptionId: String

    var value: Int
    var unit: ObjectiveUnit

    var timestamp: Date = Date()

    var durationSeconds: Int?
    var distanceMeters: Int?
    var externalLoadKg: Int?

    var source: Source = .manual
    var note: String?

    /// « 08:12 — 20 répétitions »
    var label: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: timestamp)) — \(unit.format(value))"
    }
}

// MARK: - État d'un objectif

/// Où en est un objectif. Une séance fractionnable reste ouverte toute la
/// journée : elle n'est donc ni simplement « à faire » ni « faite ».
enum ObjectiveStatus: String, Codable, CaseIterable {
    case notStarted, inProgress, completed, partiallyCompleted, expired

    var label: String {
        switch self {
        case .notStarted: return "À faire"
        case .inProgress: return "En cours"
        case .completed: return "Terminé"
        case .partiallyCompleted: return "Partiel"
        case .expired: return "Journée passée"
        }
    }

    var isDone: Bool { self == .completed }
}

// MARK: - L'avancement d'un objectif dans la journée

/// Le cumul d'un objectif : sa cible, ce qui a été fait, et par quelles
/// contributions.
struct DailyObjectiveProgress: Identifiable, Codable, Equatable {
    var id: String { prescriptionId }

    var prescriptionId: String
    /// Le jour auquel ce cumul appartient, au format « yyyy-MM-dd ».
    var day: String

    var targetValue: Int
    var unit: ObjectiveUnit
    var completionPolicy: CompletionPolicy

    var entries: [ProgressEntry] = []
    /// Posé quand l'utilisateur déclare l'objectif atteint sans détailler.
    var declaredComplete: Bool = false

    /// Ce qui compte comme réalisé.
    ///
    /// Un objectif `continuous` ne s'additionne pas : c'est la meilleure
    /// contribution unique qui compte. Trois kilomètres puis sept ne font pas
    /// dix kilomètres d'une traite.
    var completedValue: Int {
        guard !entries.isEmpty else { return 0 }
        switch completionPolicy {
        case .continuous:
            return entries.map(\.value).max() ?? 0
        case .structuredSession, .dayCumulative:
            return entries.reduce(0) { $0 + $1.value }
        }
    }

    var remaining: Int { max(0, targetValue - completedValue) }

    var ratio: Double {
        guard targetValue > 0 else { return declaredComplete ? 1 : 0 }
        return min(1, Double(completedValue) / Double(targetValue))
    }

    var status: ObjectiveStatus {
        if declaredComplete || (targetValue > 0 && completedValue >= targetValue) { return .completed }
        if entries.isEmpty { return .notStarted }
        return .inProgress
    }

    /// « 40 / 60 », en unité lisible.
    var counterLabel: String {
        "\(unit.short(completedValue)) / \(unit.format(targetValue))"
    }

    mutating func add(_ entry: ProgressEntry) {
        entries.append(entry)
        entries.sort { $0.timestamp < $1.timestamp }
    }

    mutating func remove(_ id: UUID) {
        entries.removeAll { $0.id == id }
        if entries.isEmpty { declaredComplete = false }
    }

    mutating func update(_ id: UUID, to value: Int) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        entries[index].value = max(0, value)
    }
}

// MARK: - L'état d'une séance ouverte

/// Une séance en cours, qui peut rester ouverte plusieurs heures et survivre
/// à la fermeture de l'app.
struct OpenSession: Codable, Equatable {
    var programID: String
    var sessionIndex: Int
    var day: String
    var startedAt: Date = Date()

    /// L'avancement de chaque objectif, par identifiant de prescription.
    var objectives: [String: DailyObjectiveProgress] = [:]

    /// Vrai quand tout ce qui compte pour l'adaptation est atteint.
    func isComplete(against prescriptions: [ExercisePrescription]) -> Bool {
        let required = prescriptions.filter(\.countsTowardAdaptation)
        guard !required.isEmpty else { return false }
        return required.allSatisfy { objectives[$0.id]?.status.isDone ?? false }
    }

    /// Part du travail accompli, échauffement exclu.
    func ratio(against prescriptions: [ExercisePrescription]) -> Double {
        let required = prescriptions.filter(\.countsTowardAdaptation)
        guard !required.isEmpty else { return 0 }
        let total = required.reduce(0.0) { $0 + (objectives[$1.id]?.ratio ?? 0) }
        return total / Double(required.count)
    }
}
