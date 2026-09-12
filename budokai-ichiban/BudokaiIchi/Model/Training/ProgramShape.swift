import Foundation

/// La forme réelle d'un programme : ses étapes, leur longueur, sa durée.
///
/// L'ancien catalogue décrivait chaque programme par une liste d'étapes et un
/// nombre de séances écrits à la main. Les spécifications ont remplacé tout
/// cela : une étape dure un nombre de **semaines**, et sa longueur en séances
/// dépend donc de la fréquence choisie par le joueur. Goku ne fait pas
/// quarante séances pour tout le monde : il en fait autant que huit jalons de
/// deux à cinq semaines à la fréquence retenue.
///
/// Cette structure est le seul endroit qui répond à « combien de séances »,
/// « quelle étape » et « comment elle s'appelle ». Tout ce qui décrit un
/// programme à l'écran passe par elle.
struct ProgramShape: Equatable {

    /// Les titres des étapes, dans l'ordre.
    var stageTitles: [String]
    /// Le nombre de séances de chaque étape, à la fréquence retenue.
    var sessionsPerStage: [Int]
    /// Les clés d'étape du pack narratif, quand elles existent.
    var stageKeys: [String]
    /// La fréquence sur laquelle la forme a été calculée.
    var sessionsPerWeek: Int

    var totalSessions: Int { sessionsPerStage.reduce(0, +) }
    var stageCount: Int { stageTitles.count }

    /// L'étape d'une séance, en numérotation à partir de zéro.
    func stageIndex(forSession session: Int) -> Int {
        var remaining = session
        for (index, count) in sessionsPerStage.enumerated() {
            if remaining < count { return index }
            remaining -= count
        }
        return max(sessionsPerStage.count - 1, 0)
    }

    /// La première séance d'une étape, en numérotation à partir de zéro.
    func firstSession(ofStage stage: Int) -> Int {
        sessionsPerStage.prefix(max(0, stage)).reduce(0, +)
    }

    /// Le titre d'une étape, sans risque de déborder.
    func title(ofStage stage: Int) -> String {
        guard stage >= 0, stage < stageTitles.count else { return "" }
        return stageTitles[stage]
    }

    /// Combien de semaines dure une étape à cette fréquence.
    func weeks(ofStage stage: Int) -> Int {
        guard stage >= 0, stage < sessionsPerStage.count, sessionsPerWeek > 0 else { return 0 }
        return max(1, sessionsPerStage[stage] / sessionsPerWeek)
    }
}

extension ProgramShape {

    /// La forme d'un programme décrit par une spécification.
    static func make(_ id: ProgramID, sessionsPerWeek: Int) -> ProgramShape? {
        let stages = ProgramLibrary.stages(id)
        guard !stages.isEmpty else { return nil }
        let perWeek = max(1, sessionsPerWeek)
        return ProgramShape(
            stageTitles: stages.map(\.title),
            sessionsPerStage: stages.map { max(1, $0.weeksMin * perWeek) },
            stageKeys: stages.map(\.key),
            sessionsPerWeek: perWeek)
    }

    /// La forme héritée de l'ancien catalogue, pour ce qui n'a pas encore de
    /// spécification.
    static func legacy(_ program: Program) -> ProgramShape {
        ProgramShape(stageTitles: program.stages,
                     sessionsPerStage: program.sessionsPerStage,
                     stageKeys: [],
                     sessionsPerWeek: 0)
    }

    /// La forme de Saitama quand son plan est calculé : ce sont ses blocs qui
    /// font foi, pas les jalons de sa définition.
    static func saitama(blocks: [SaitamaBlockSpec], sessionsPerWeek: Int) -> ProgramShape {
        let perWeek = max(1, sessionsPerWeek)
        return ProgramShape(
            stageTitles: blocks.map(\.title),
            sessionsPerStage: blocks.map { max(1, SaitamaPlan.weeks(inBlock: $0.index) * perWeek) },
            stageKeys: [],
            sessionsPerWeek: perWeek)
    }
}
