import Foundation

/// La description d'un programme, telle que sa spécification l'arrête.
///
/// Un programme n'est plus décrit dans du code Swift mais dans un fichier de
/// données. C'est ce qui permet d'en tenir neuf sans neuf moteurs, et de
/// corriger une valeur sans recompiler la logique.
struct ProgramDefinition: Codable, Equatable {
    var id: String
    var quality: String
    var scheduling: Scheduling
    var stages: [Stage]
    var boss: Boss?
    var superRank: SuperRank?
    var rewards: [RewardEntry]

    // MARK: Planification

    struct Scheduling: Codable, Equatable {
        var min: Int
        var recommended: Int
        var max: Int
        var recoveryHours: Int
        var requiresLongSession: Bool
        /// Ce qu'on nomme « séance clé » à l'écran de lancement.
        var keySessionLabel: String
        /// La semaine type, par fréquence.
        var templates: [String: [Slot]]

        struct Slot: Codable, Equatable {
            var type: String
            var title: String
            var priority: String
            var load: String
            var minutes: Int
        }
    }

    // MARK: Étapes

    struct Stage: Codable, Equatable, Identifiable {
        /// La clé employée par le pack narratif : c'est elle qui relie une
        /// étape à ses récits.
        var key: String
        var title: String
        var goal: String
        /// Le repère chiffré de fin d'étape, en clair, quand il existe.
        var benchmark: String?
        /// Les conditions de sortie, telles que la spécification les donne.
        var exit: [String]
        var weeksMin: Int
        var weeksMax: Int

        var id: String { key }
        var weeksLabel: String {
            weeksMin == weeksMax ? "\(weeksMin) semaines" : "\(weeksMin) à \(weeksMax) semaines"
        }
    }

    // MARK: Combat final

    struct Boss: Codable, Equatable {
        var title: String
        var summary: String
        var components: [Component]
        var requirements: [String]
        var rewardId: String?

        struct Component: Codable, Equatable, Identifiable {
            var id: String
            var name: String
            var value: Int
            var unit: String
            var policy: String

            var objectiveUnit: ObjectiveUnit { ObjectiveUnit(rawValue: unit) ?? .reps }
            var completionPolicy: CompletionPolicy {
                CompletionPolicy(rawValue: policy) ?? .structuredSession
            }
        }
    }

    struct SuperRank: Codable, Equatable {
        var name: String
        var rewardId: String?
    }

    struct RewardEntry: Codable, Equatable, Identifiable {
        var id: String
        /// La clé de l'étape qui la débloque, ou nul pour le combat final.
        var stage: String?
        var title: String
        var type: String
        var rarity: String

        var rewardType: RewardType { RewardType(rawValue: type) ?? .event }
        var rewardRarity: RewardRarity { RewardRarity(rawValue: rarity) ?? .rare }
    }
}

// MARK: - Le catalogue

/// Charge les définitions embarquées, une seule fois chacune.
enum ProgramLibrary {

    private static var cache: [String: ProgramDefinition] = [:]

    static func definition(_ id: ProgramID) -> ProgramDefinition? {
        if let cached = cache[id.rawValue] { return cached }
        guard let url = Bundle.main.url(forResource: "\(id.rawValue).def", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let definition = try? JSONDecoder().decode(ProgramDefinition.self, from: data)
        else { return nil }
        cache[id.rawValue] = definition
        return definition
    }

    /// Les étapes d'un programme.
    static func stages(_ id: ProgramID) -> [ProgramDefinition.Stage] {
        definition(id)?.stages ?? []
    }

    /// Les règles de planification, traduites pour le planificateur.
    static func schedulingRules(_ id: ProgramID) -> ProgramSchedulingRules? {
        guard let definition = definition(id) else { return nil }
        let scheduling = definition.scheduling

        var templates: [Int: [SessionSchedulingMetadata]] = [:]
        for (frequency, slots) in scheduling.templates {
            guard let count = Int(frequency) else { continue }
            templates[count] = slots.map { slot in
                SessionSchedulingMetadata(
                    type: SessionType(rawValue: slot.type) ?? .strength,
                    priority: SessionPriority(rawValue: slot.priority) ?? .important,
                    estimatedDurationMinutes: slot.minutes,
                    loadCategory: LoadCategory(rawValue: slot.load) ?? .moderate,
                    title: slot.title)
            }
        }

        let required = Set(templates.values.flatMap { $0 }.map(\.type))
        return ProgramSchedulingRules(
            programID: definition.id,
            minimumSessionsPerWeek: scheduling.min,
            recommendedSessionsPerWeek: scheduling.recommended,
            maximumStructuredSessionsPerWeek: scheduling.max,
            requiredSessionTypes: Array(required),
            keySessionsPerWeek: 1,
            requiresLongSession: scheduling.requiresLongSession,
            minimumRecoveryBetweenHardSessionsHours: scheduling.recoveryHours > 0 ? scheduling.recoveryHours : nil,
            weeklyTemplates: templates)
    }

    /// Le combat final, traduit dans le modèle de l'app.
    static func boss(_ id: ProgramID) -> ProgramStructures.BossFight? {
        guard let boss = definition(id)?.boss else { return nil }
        return ProgramStructures.BossFight(
            programID: id.rawValue,
            title: boss.title,
            components: boss.components.map {
                .init(id: $0.id, name: $0.name, targetValue: $0.value,
                      unit: $0.objectiveUnit, policy: $0.completionPolicy)
            },
            entryRequirements: boss.requirements,
            rewardId: boss.rewardId)
    }

    static func bossSummary(_ id: ProgramID) -> String? { definition(id)?.boss?.summary }

    static func superRankName(_ id: ProgramID) -> String? { definition(id)?.superRank?.name }

    /// Toutes les vignettes déclarées, tous programmes confondus.
    static func rewards(_ id: ProgramID) -> [Reward] {
        guard let definition = definition(id) else { return [] }
        let program = Catalog.program(id)
        return definition.rewards.enumerated().map { index, entry in
            let stageTitle = definition.stages.first { $0.key == entry.stage }?.title
            let condition: UnlockCondition = entry.stage.map { .blockCompleted(blockId: "\(id.rawValue).\($0)") }
                ?? .bossDefeated(programId: id.rawValue)
            return Reward(rewardId: entry.id,
                          anime: program.universe,
                          programId: id.rawValue,
                          arc: stageTitle ?? definition.boss?.title ?? program.name,
                          blockId: entry.stage,
                          rewardType: entry.rewardType,
                          title: entry.title,
                          subtitle: stageTitle,
                          description: "Obtenue en franchissant « \(stageTitle ?? definition.boss?.title ?? program.name) ».",
                          rarity: entry.rewardRarity,
                          chronologyIndex: index + 1,
                          unlockCondition: condition)
        }
    }
}
