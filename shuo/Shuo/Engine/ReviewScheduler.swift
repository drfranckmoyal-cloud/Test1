import Foundation

/// La mémoire et son oubli.
///
/// La force mémoire décroît toute seule avec le temps : un mot vert peut
/// redevenir fragile sans qu'on y touche, et ressortir en révision. Chaque
/// rappel différé réussi allonge l'intervalle ; un échec le raccourcit.
enum ReviewScheduler {

    /// Demi-vie de départ, en jours : sans rappel, un mot neuf perd la moitié
    /// de sa force en une journée.
    static let baseHalfLifeDays = 1.0
    /// Chaque rappel réussi multiplie la demi-vie par ce facteur.
    static let growthFactor = 1.9
    /// Plafond : au-delà de six mois, l'app ne fait plus de promesses.
    static let maxHalfLifeDays = 180.0
    /// On reprogramme un mot quand sa force descend sous ce seuil.
    static let reviewAtStrength = 0.7

    /// La demi-vie courante d'un item, en jours.
    static func halfLife(for item: ItemState) -> Double {
        let successes = Double(item.delayedRecallSessions.count)
        let penalty = Double(item.failedReviewSessions.count)
        let exponent = max(0, successes - penalty)
        let value = baseHalfLifeDays * pow(growthFactor, exponent)
        return min(value, maxHalfLifeDays)
    }

    /// La force mémoire à une date donnée, après décroissance.
    static func strength(of item: ItemState, at date: Date) -> Double {
        let days = date.timeIntervalSince(item.lastSeenAt) / 86_400
        guard days > 0 else { return item.memoryStrength }
        let decayed = item.memoryStrength * pow(0.5, days / halfLife(for: item))
        return min(max(decayed, 0), 1)
    }

    /// La force juste après une observation.
    static func updatedStrength(for item: ItemState, after evidence: Evidence, succeeded: Bool) -> Double {
        if succeeded {
            // Une réussite sans aide remet la force presque à plein ; avec aide,
            // moins.
            let ceiling = evidence.helpLevel == .none ? 1.0 : 0.8
            return min(ceiling, max(item.memoryStrength, 0.55) + 0.25)
        }
        return max(0, item.memoryStrength * 0.55)
    }

    /// La prochaine échéance de révision.
    static func nextReview(for item: ItemState, from date: Date) -> Date {
        // Temps nécessaire pour retomber au seuil : t = H · log2(force / seuil).
        let ratio = max(item.memoryStrength, 0.01) / reviewAtStrength
        let periods = max(0.15, log2(max(ratio, 1.0001)))
        let days = halfLife(for: item) * periods
        return date.addingTimeInterval(min(days, maxHalfLifeDays) * 86_400)
    }

    /// Les mots dus à une date donnée, les plus urgents d'abord.
    static func dueItems(in state: LearnerState, at date: Date = Date(), limit: Int = .max) -> [String] {
        state.items.values
            .filter { $0.nextReviewAt <= date }
            .sorted { strength(of: $0, at: date) < strength(of: $1, at: date) }
            .prefix(limit)
            .map(\.itemID)
    }

    // MARK: - Sélection du pool de révision

    /// Les cinq familles de priorité que le dossier demande de mélanger.
    enum Priority: String, CaseIterable {
        case fragile = "fragiles"
        case stale = "non revus depuis longtemps"
        case recentGreen = "acquis récents à confirmer"
        case structural = "éléments structurants"
        case oldGreen = "acquis anciens"
    }

    /// Compose un pool de révision puisé dans *tout* l'historique, pas seulement
    /// dans la dernière leçon.
    ///
    /// La sélection n'est pas une file d'attente : elle prend des mots dans
    /// chaque famille, dans l'ordre de priorité, et complète avec les plus
    /// faibles s'il en manque.
    static func reviewPool(
        from state: LearnerState,
        library: ContentLibrary,
        count: Int,
        at date: Date = Date()
    ) -> [String] {
        let all = Array(state.items.values)
        guard !all.isEmpty else { return [] }

        func take(_ n: Int, _ candidates: [ItemState]) -> [String] {
            candidates.prefix(n).map(\.itemID)
        }

        // Les quotas suivent l'ordre du dossier : le fragile d'abord, un peu
        // d'ancien acquis à la fin pour vérifier que ça tient.
        let quotas: [(Priority, Int)] = [
            (.fragile, max(1, count * 35 / 100)),
            (.stale, max(1, count * 25 / 100)),
            (.recentGreen, max(1, count * 15 / 100)),
            (.structural, max(1, count * 15 / 100)),
            (.oldGreen, max(1, count * 10 / 100)),
        ]

        var chosen: [String] = []
        var remaining = Set(all.map(\.itemID))

        for (priority, quota) in quotas {
            let pool = candidates(for: priority, among: all, library: library, at: date)
                .filter { remaining.contains($0.itemID) }
            let picked = take(quota, pool)
            chosen.append(contentsOf: picked)
            picked.forEach { remaining.remove($0) }
        }

        // Complément : les plus faibles d'abord, pour ne jamais rendre un pool
        // plus court que demandé quand il reste de la matière.
        if chosen.count < count {
            let filler = all
                .filter { remaining.contains($0.itemID) }
                .sorted { strength(of: $0, at: date) < strength(of: $1, at: date) }
            chosen.append(contentsOf: take(count - chosen.count, filler))
        }

        return Array(chosen.prefix(count))
    }

    private static func candidates(
        for priority: Priority,
        among all: [ItemState],
        library: ContentLibrary,
        at date: Date
    ) -> [ItemState] {
        switch priority {
        case .fragile:
            return all
                .filter { $0.isFragile || $0.status != .green }
                .sorted { strength(of: $0, at: date) < strength(of: $1, at: date) }
        case .stale:
            return all.sorted { $0.lastSeenAt < $1.lastSeenAt }
        case .recentGreen:
            return all
                .filter { $0.status == .green && $0.delayedRecallSessions.count <= MasteryEngine.requiredDelayedRecalls }
                .sorted { $0.lastSeenAt > $1.lastSeenAt }
        case .structural:
            return all
                .filter { library.item(id: $0.itemID)?.isStructural == true }
                .sorted { strength(of: $0, at: date) < strength(of: $1, at: date) }
        case .oldGreen:
            return all
                .filter { $0.status == .green }
                .sorted { $0.lastSeenAt < $1.lastSeenAt }
        }
    }
}
