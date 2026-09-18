import Foundation
import SwiftUI

/// La mémoire de l'app entre deux ouvertures.
///
/// Elle vit dans un fichier JSON du dossier Application Support, pas dans les
/// réglages : l'état apprenant grossit avec les séances et n'a rien à faire
/// dans `UserDefaults`. Une sauvegarde illisible n'efface rien — elle est mise
/// de côté sous un autre nom, et on repart d'un état vierge (A04).
@MainActor
final class LearnerStore: ObservableObject {

    @Published private(set) var state: LearnerState

    private let fileURL: URL
    private let library: ContentLibrary

    init(library: ContentLibrary = .shared, fileURL: URL? = nil) {
        self.library = library
        self.fileURL = fileURL ?? Self.defaultFileURL()
        self.state = Self.loadState(from: self.fileURL)
    }

    private static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = base.appendingPathComponent("Shuo", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("learner-state-v2.json")
    }

    private static func loadState(from url: URL) -> LearnerState {
        guard let data = try? Data(contentsOf: url) else { return LearnerState() }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode(LearnerState.self, from: data) {
            return decoded
        }
        // Illisible : on garde le fichier sous le coude plutôt que de l'écraser.
        let backup = url.deletingPathExtension().appendingPathExtension("corrupt.json")
        try? FileManager.default.removeItem(at: backup)
        try? FileManager.default.moveItem(at: url, to: backup)
        return LearnerState()
    }

    /// Écrit l'état sur le disque. Appelée après chaque changement qui compte.
    func save() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.withoutEscapingSlashes]
        guard let data = try? encoder.encode(state) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Modifie l'état et sauvegarde dans la foulée.
    func mutate(_ change: (inout LearnerState) -> Void) {
        change(&state)
        save()
    }

    // MARK: - Lecture

    func item(_ id: String) -> ItemState? { state.items[id] }

    func status(_ id: String) -> MasteryStatus { state.items[id]?.status ?? .red }

    /// Le décompte par statut, pour l'accueil et le mode développeur.
    var statusCounts: (red: Int, orange: Int, green: Int) {
        var red = 0, orange = 0, green = 0
        for item in state.items.values {
            switch item.status {
            case .red: red += 1
            case .orange: orange += 1
            case .green: green += 1
            }
        }
        return (red, orange, green)
    }

    /// Le vocabulaire actif : ce que l'apprenant produit, pas seulement ce
    /// qu'il reconnaît.
    var activeVocabCount: Int {
        state.items.values.filter { $0.score(.spontaneousProduction) >= MasteryEngine.successThreshold }.count
    }

    var passiveVocabCount: Int {
        state.items.values.filter { $0.score(.listeningRecognition) >= MasteryEngine.successThreshold }.count
    }

    /// Les mots dus aujourd'hui.
    func dueItems(at date: Date = Date()) -> [String] {
        ReviewScheduler.dueItems(in: state, at: date)
    }

    /// Vrai après trois jours sans séance : l'accueil propose alors un test de
    /// retour, court et facultatif (A11).
    func shouldOfferReturnTest(now: Date = Date()) -> Bool {
        guard !state.items.isEmpty else { return false }
        guard let days = state.daysSinceLastSession(now: now) else { return false }
        return days >= 3
    }

    /// La dernière séance terminée, pour « revoir la leçon précédente ».
    var lastSession: SessionRecord? { state.lastFinishedSession }

    /// La séance laissée en plan, s'il y en a une à reprendre.
    var interruptedSession: SessionRecord? {
        guard let id = state.interruptedSessionID else { return nil }
        return state.sessions.first { $0.id == id && !$0.isFinished }
    }

    /// Le coût cumulé de toutes les séances, en euros.
    var cumulativeCostEUR: Double {
        state.sessions.reduce(0) { $0 + $1.estimatedCostEUR }
    }

    /// Le temps de séance cumulé, en heures, pour ramener le coût à l'heure.
    var cumulativeHours: Double {
        state.sessions.reduce(0) { total, session in
            guard let end = session.endedAt else { return total }
            return total + end.timeIntervalSince(session.startedAt) / 3600
        }
    }

    // MARK: - Écriture

    /// Range une observation et renvoie le motif d'erreur à reprendre, s'il
    /// vient d'atteindre le seuil.
    @discardableResult
    func record(_ evidence: Evidence) -> String? {
        var remediation: String?
        mutate { state in
            remediation = MasteryEngine.record(evidence, into: &state)
        }
        return remediation
    }

    /// À appeler en fin de séance de révision : c'est là, et seulement là, que
    /// des échecs répétés peuvent faire redescendre un statut.
    func applyDowngrades(for itemIDs: [String]) {
        mutate { state in
            for id in itemIDs {
                MasteryEngine.applyDowngradeIfWarranted(itemID: id, in: &state)
            }
        }
    }

    func beginSession(_ record: SessionRecord) {
        mutate { state in
            state.sessions.append(record)
            state.interruptedSessionID = record.id
            state.lastTutorID = record.tutorID
        }
    }

    func updateSession(_ record: SessionRecord) {
        mutate { state in
            if let index = state.sessions.firstIndex(where: { $0.id == record.id }) {
                state.sessions[index] = record
            }
        }
    }

    func finishSession(_ record: SessionRecord, cursor: CurriculumCursor?, clearedRemediations: [String]) {
        mutate { state in
            var finished = record
            finished.endedAt = Date()
            if let index = state.sessions.firstIndex(where: { $0.id == record.id }) {
                state.sessions[index] = finished
            } else {
                state.sessions.append(finished)
            }
            if let cursor { state.cursor = cursor }
            state.interruptedSessionID = nil
            state.pendingRemediations.removeAll { clearedRemediations.contains($0) }
        }
    }

    /// Efface tout. Réservé au mode développeur, et confirmé avant.
    func reset() {
        mutate { $0 = LearnerState() }
    }
}
