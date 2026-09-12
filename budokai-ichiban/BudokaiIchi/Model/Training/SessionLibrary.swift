import Foundation

/// Les séances écrites par le préparateur physique, programme par programme.
///
/// Le coach livre une **semaine type** par couple (jalon, fréquence), plus une
/// règle de progression. Le moteur déroule : il répète la semaine, applique la
/// progression à mesure qu'on avance dans le jalon, et choisit la variante
/// selon l'échelon atteint.
enum SessionLibrary {

    // MARK: - Ce que le coach livre

    struct Pack: Codable, Equatable {
        var program: String
        var version: String
        var families: [Family]
        var calibration: [CalibrationTest]
        var weeks: [Week]
    }

    struct Family: Codable, Equatable, Identifiable {
        var id: String
        var name: String
        var function: String?
        /// L'échelon qui fait foi pour le combat final.
        var bossLevel: Int?
        var ladder: [Rung]

        struct Rung: Codable, Equatable, Identifiable {
            var id: String
            /// Le nom que lit le pratiquant : simple, en français.
            var name: String
            /// Le nom technique, en tout petit sous le nom simple. Il existe
            /// pour que celui qui connaît le mouvement le reconnaisse, pas
            /// pour que l'autre ait à le comprendre.
            var technical: String?
            var detail: String?
        }

        func rung(atLevel level: Int) -> Rung? {
            guard !ladder.isEmpty else { return nil }
            return ladder[min(max(level, 1), ladder.count) - 1]
        }
    }

    struct CalibrationTest: Codable, Equatable, Identifiable {
        var id: String
        var label: String
        var family: String?
        /// Les familles voisines que cette mesure renseigne aussi. Sans cela,
        /// un coureur de dix kilomètres se verrait prescrire des séances de
        /// récupération de débutant, faute de test sur cette famille-là.
        var alsoFamilies: [String]?
        /// L'échelon de repli, quand la mesure ne permet pas de trancher.
        var referenceLevel: Int?
        var unit: String
        var max: Int
        var cue: String
        /// La question posée en toutes lettres, quand elle vaut mieux qu'un
        /// libellé de champ.
        var question: String?
        /// Des réponses à choisir plutôt qu'un nombre à saisir.
        var choices: [Choice]?
        /// Ce que la mesure dit du point de départ : à quel échelon de la
        /// famille elle place le pratiquant.
        ///
        /// C'est la pièce qui manquait. Sans elle, tout le monde démarrait au
        /// même échelon quelle que soit sa réponse — celui qui fait trente
        /// pompes commençait comme celui qui en fait trois.
        var entry: [EntryRule]?

        struct Choice: Codable, Equatable, Identifiable {
            var label: String
            var value: Int
            var id: Int { value }
        }

        struct EntryRule: Codable, Equatable {
            /// Seuil à atteindre, pour ce qui se mesure vers le haut.
            var atLeast: Int?
            /// Seuil à ne pas dépasser, pour un chrono.
            var atMost: Int?
            var level: Int
        }

        var objectiveUnit: ObjectiveUnit { ObjectiveUnit(rawValue: unit) ?? .reps }

        /// L'échelon de départ que cette mesure désigne.
        ///
        /// Les règles « au moins » se lisent de la plus exigeante à la moins
        /// exigeante ; les règles « au plus » dans l'autre sens. À défaut de
        /// table, on retombe sur l'échelon de repli — l'ancien comportement.
        func entryLevel(for value: Int) -> Int? {
            guard let entry = entry, !entry.isEmpty else { return referenceLevel }
            if entry.contains(where: { $0.atMost != nil }) {
                let match = entry.filter { $0.atMost != nil }
                    .sorted { ($0.atMost ?? 0) < ($1.atMost ?? 0) }
                    .first { value <= ($0.atMost ?? 0) }
                return match?.level ?? referenceLevel
            }
            let match = entry.filter { $0.atLeast != nil }
                .sorted { ($0.atLeast ?? 0) > ($1.atLeast ?? 0) }
                .first { value >= ($0.atLeast ?? 0) }
            return match?.level ?? referenceLevel
        }
    }

    struct Week: Codable, Equatable {
        var stage: String
        var frequency: Int
        var progression: Progression?
        var sessions: [Session]

        struct Progression: Codable, Equatable {
            var rule: String
            var perWeek: Double?
            var note: String?
        }
    }

    struct Session: Codable, Equatable {
        var slot: Int
        var title: String
        var type: String
        var exercises: [Exercise]

        var sessionType: SessionType { SessionType(rawValue: type) ?? .strength }
    }

    struct Exercise: Codable, Equatable {
        var role: String
        var name: String
        var detail: String?
        var family: String?
        var unit: String
        /// Soit une valeur unique…
        var value: Int?
        /// …soit des séries.
        var sets: Int?
        var perSet: Int?
        var restSeconds: Int?
        var rir: Int?
        var rpe: Int?
        var tempo: String?
        var policy: String?
        var characteristic: String?

        var objectiveUnit: ObjectiveUnit { ObjectiveUnit(rawValue: unit) ?? .reps }
        var completionPolicy: CompletionPolicy {
            CompletionPolicy(rawValue: policy ?? "") ?? .structuredSession
        }
        var trainingCharacteristic: TrainingCharacteristic {
            TrainingCharacteristic(rawValue: characteristic ?? "") ?? .force
        }
        var isWarmup: Bool { role == "warmup" }
        var isCooldown: Bool { role == "cooldown" }
        /// Seul le travail compte dans l'adaptation et dans la validation.
        var isWork: Bool { role == "work" }

        var total: Int {
            if let value = value { return value }
            return (sets ?? 1) * (perSet ?? 0)
        }
    }

    // MARK: - Chargement

    private static var cache: [String: Pack] = [:]

    static func pack(_ id: ProgramID) -> Pack? {
        if let cached = cache[id.rawValue] { return cached }
        guard let url = Bundle.main.url(forResource: "\(id.rawValue).sessions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder().decode(Pack.self, from: data)
        else { return nil }
        cache[id.rawValue] = pack
        return pack
    }

    static func hasSessions(_ id: ProgramID) -> Bool { pack(id) != nil }

    static func family(_ id: ProgramID, _ familyId: String) -> Family? {
        pack(id)?.families.first { $0.id == familyId }
    }

    static func calibration(_ id: ProgramID) -> [CalibrationTest] {
        pack(id)?.calibration ?? []
    }

    /// La semaine type d'un jalon à une fréquence donnée.
    ///
    /// À défaut de la fréquence exacte, on retient la plus proche : mieux vaut
    /// une semaine voisine qu'aucune séance.
    static func week(_ id: ProgramID, stage: String, frequency: Int) -> Week? {
        guard let pack = pack(id) else { return nil }
        let candidates = pack.weeks.filter { $0.stage == stage }
        guard !candidates.isEmpty else { return nil }
        return candidates.first { $0.frequency == frequency }
            ?? candidates.min { abs($0.frequency - frequency) < abs($1.frequency - frequency) }
    }
}

// MARK: - Le générateur

/// Fabrique la séance du jour d'un programme décrit par le coach.
enum CoachEngine {

    /// Ce qu'il faut savoir pour fabriquer une séance.
    struct Context {
        var program: ProgramID
        var stageKey: String
        var stageIndex: Int
        var frequency: Int
        var slot: Int
        /// Semaine à l'intérieur du jalon, à partir de 0.
        var weekInStage: Int
        var sessionIndex: Int
        /// Échelon atteint par famille.
        var levels: [String: Int]
        var isDeload: Bool
        var narrativeId: String?
        var scheduling: SessionSchedulingMetadata?
    }

    /// Réduction de volume d'une semaine allégée.
    private static let deloadFactor = 0.70

    static func session(_ context: Context) -> PlannedSession? {
        guard let week = SessionLibrary.week(context.program, stage: context.stageKey,
                                             frequency: context.frequency),
              let template = week.sessions.first(where: { $0.slot == context.slot })
                  ?? week.sessions.first
        else { return nil }

        let growth = factor(week.progression, week: context.weekInStage)
        let prescriptions = template.exercises.map {
            prescription($0, context: context, growth: growth, rule: week.progression?.rule)
        }

        return PlannedSession(
            id: "\(context.program.rawValue)-\(context.sessionIndex + 1)",
            programID: context.program,
            index: context.sessionIndex + 1,
            stageIndex: context.stageIndex,
            title: context.isDeload ? "\(template.title) · décharge" : template.title,
            steps: [],
            prescribed: prescriptions,
            scheduling: context.scheduling ?? SessionSchedulingMetadata(
                type: template.sessionType,
                priority: .important,
                estimatedDurationMinutes: estimate(prescriptions),
                loadCategory: .moderate,
                title: template.title),
            narrativeId: context.narrativeId)
    }

    /// Le facteur de progression appliqué à la semaine en cours du jalon.
    private static func factor(_ progression: SessionLibrary.Week.Progression?, week: Int) -> Double {
        guard let progression = progression, let perWeek = progression.perWeek, week > 0 else { return 1 }
        return pow(1 + perWeek, Double(week))
    }

    /// Traduit un exercice du coach en prescription de l'app.
    private static func prescription(_ exercise: SessionLibrary.Exercise,
                                     context: Context, growth: Double,
                                     rule: String?) -> ExercisePrescription {
        // la variante suit l'échelon atteint dans la famille
        var name = exercise.name
        var technical: String?
        var detail = exercise.detail
        var level: Int?
        var easier: String?
        var harder: String?

        if let familyId = exercise.family,
           let family = SessionLibrary.family(context.program, familyId) {
            let current = context.levels[familyId] ?? family.bossLevel ?? 1
            if let rung = family.rung(atLevel: current) {
                name = rung.name
                technical = rung.technical
                detail = rung.detail ?? exercise.detail
                level = current
                easier = family.rung(atLevel: current - 1)?.id
                harder = family.rung(atLevel: current + 1)?.id
            }
        }

        // la progression ne touche que la variable désignée par le coach
        var scale = 1.0
        if exercise.isWork {
            switch rule {
            case "volume", "duration", "distance": scale = growth
            default: scale = 1
            }
        }
        if context.isDeload && exercise.isWork { scale *= deloadFactor }

        func grow(_ value: Int) -> Int {
            guard scale != 1 else { return value }
            switch exercise.objectiveUnit {
            case .seconds: return max(10, Int((Double(value) * scale / 30).rounded()) * 30)
            case .meters: return max(100, Int((Double(value) * scale / 100).rounded()) * 100)
            default: return max(1, Int((Double(value) * scale).rounded()))
            }
        }

        var item = ExercisePrescription(
            exerciseId: exercise.family,
            name: name,
            detail: detail,
            targetValue: grow(exercise.total),
            unit: exercise.objectiveUnit,
            sets: exercise.sets,
            targetPerSet: exercise.perSet.map(grow),
            restSeconds: exercise.restSeconds,
            characteristic: exercise.trainingCharacteristic,
            targetRPE: exercise.rpe,
            targetRIR: exercise.rir,
            tempo: exercise.tempo,
            completionPolicy: exercise.completionPolicy)

        item.technicalName = technical
        item.id = "\(context.program.rawValue).\(context.stageKey).\(context.slot).\(exercise.name)"
        item.exerciseLevel = level
        item.variantId = exercise.family
        item.easierVariantId = easier
        item.harderVariantId = harder
        item.isWarmup = exercise.isWarmup
        item.isCooldown = exercise.isCooldown
        item.countsTowardAdaptation = exercise.isWork
        return item
    }

    private static func estimate(_ items: [ExercisePrescription]) -> Int {
        let work = items.reduce(0) { partial, item in
            switch item.unit {
            case .reps: return partial + item.targetValue * 3
            case .seconds: return partial + item.targetValue
            case .meters: return partial + item.targetValue / 3
            case .kg, .centimeters, .degrees, .centiseconds: return partial
            }
        }
        let rest = items.reduce(0) { $0 + (($1.restSeconds ?? 0) * max(0, ($1.sets ?? 1) - 1)) }
        return max(1, (work + rest) / 60)
    }
}
