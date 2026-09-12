import Foundation

// MARK: - Ce qu'un bloc prescrit

/// Les chiffres d'un bloc, repris des chapitres 11 à 18 de la spécification.
/// Rien ici n'est inventé : chaque valeur vient du document.
struct SaitamaBlockSpec: Identifiable, Equatable {
    var id: String
    var index: Int
    var title: String
    var arc: String
    /// Le benchmark de la routine : 20/20/20, 30/30/30…
    var routineVolume: Int
    /// La distance de référence du bloc, en mètres.
    var benchmarkMeters: Int
    /// Politique dominante de la Routine B dans ce bloc.
    var routinePolicy: CompletionPolicy
    /// Répétitions gardées en réserve sur le travail principal.
    var workingRIR: Int
    /// Nombre de séries de la Routine B.
    var routineSets: Int

    // Force A — plages données par la spécification
    var pushSets: ClosedRange<Int>
    var pushTotalReps: ClosedRange<Int>
    var squatSets: Int
    var squatReps: ClosedRange<Int>
    var coreSets: Int
    var coreReps: ClosedRange<Int>

    // Course
    var easyMinutes: ClosedRange<Int>
    var longMeters: ClosedRange<Int>
    /// La séance de développement, décrite telle quelle.
    var developmentTitle: String
    var developmentReps: Int
    var developmentWorkSeconds: Int
    var developmentRestSeconds: Int
    var developmentRPE: Int

    var rewardId: String

    /// Le repère du bloc, en clair : « 20 / 20 / 20 + 2 km ».
    var benchmark: String {
        let volume = "\(routineVolume) / \(routineVolume) / \(routineVolume)"
        return "\(volume) + \(ObjectiveUnit.meters.format(benchmarkMeters))"
    }

    /// Les blocs pairs se terminent par une semaine allégée dans le scénario
    /// nominal. La décharge suit le bloc, pas le calendrier.
    var endsWithDeload: Bool { index % 2 == 0 }
}

/// Les huit blocs de Saitama.
enum SaitamaBlocks {

    static let all: [SaitamaBlockSpec] = [
        .init(id: "SAI-B1", index: 1, title: "Le Déclic", arc: "Origines",
              routineVolume: 20, benchmarkMeters: 2000, routinePolicy: .dayCumulative,
              workingRIR: 3, routineSets: 2,
              pushSets: 4...4, pushTotalReps: 20...40, squatSets: 3, squatReps: 10...15,
              coreSets: 3, coreReps: 6...6,
              easyMinutes: 20...30, longMeters: 2000...3000,
              developmentTitle: "Course facile par blocs", developmentReps: 8,
              developmentWorkSeconds: 60, developmentRestSeconds: 60, developmentRPE: 4,
              rewardId: "SAI-001"),

        .init(id: "SAI-B2", index: 2, title: "L'Entraînement", arc: "La routine",
              routineVolume: 30, benchmarkMeters: 3000, routinePolicy: .dayCumulative,
              workingRIR: 3, routineSets: 3,
              pushSets: 4...5, pushTotalReps: 18...24, squatSets: 4, squatReps: 12...15,
              coreSets: 3, coreReps: 8...12,
              easyMinutes: 25...35, longMeters: 2500...3500,
              developmentTitle: "Blocs de 90 secondes", developmentReps: 8,
              developmentWorkSeconds: 90, developmentRestSeconds: 75, developmentRPE: 5,
              rewardId: "SAI-002"),

        .init(id: "SAI-B3", index: 3, title: "Le Disciple", arc: "Genos et la Maison de l'Évolution",
              routineVolume: 40, benchmarkMeters: 4500, routinePolicy: .structuredSession,
              workingRIR: 2, routineSets: 4,
              pushSets: 4...5, pushTotalReps: 24...30, squatSets: 4, squatReps: 15...20,
              coreSets: 3, coreReps: 8...12,
              easyMinutes: 30...40, longMeters: 4000...5000,
              developmentTitle: "Blocs de 2 minutes", developmentReps: 6,
              developmentWorkSeconds: 120, developmentRestSeconds: 120, developmentRPE: 6,
              rewardId: "SAI-003"),

        .init(id: "SAI-B4", index: 4, title: "Héros professionnel", arc: "Hero Association",
              routineVolume: 50, benchmarkMeters: 5000, routinePolicy: .structuredSession,
              workingRIR: 2, routineSets: 5,
              pushSets: 5...6, pushTotalReps: 30...38, squatSets: 4, squatReps: 18...25,
              coreSets: 4, coreReps: 10...15,
              easyMinutes: 30...45, longMeters: 5000...5000,
              developmentTitle: "Blocs de 5 minutes", developmentReps: 3,
              developmentWorkSeconds: 300, developmentRestSeconds: 180, developmentRPE: 6,
              rewardId: "SAI-004"),

        .init(id: "SAI-B5", index: 5, title: "La Météorite", arc: "Z-City",
              routineVolume: 65, benchmarkMeters: 6500, routinePolicy: .structuredSession,
              workingRIR: 2, routineSets: 5,
              pushSets: 5...6, pushTotalReps: 38...48, squatSets: 5, squatReps: 15...20,
              coreSets: 4, coreReps: 12...15,
              easyMinutes: 35...45, longMeters: 6000...7000,
              developmentTitle: "Blocs de 5 minutes", developmentReps: 4,
              developmentWorkSeconds: 300, developmentRestSeconds: 150, developmentRPE: 6,
              rewardId: "SAI-005"),

        .init(id: "SAI-B6", index: 6, title: "Justice indomptable", arc: "Deep Sea King",
              routineVolume: 75, benchmarkMeters: 7500, routinePolicy: .structuredSession,
              workingRIR: 2, routineSets: 5,
              pushSets: 6...6, pushTotalReps: 45...55, squatSets: 5, squatReps: 18...22,
              coreSets: 5, coreReps: 12...15,
              easyMinutes: 35...50, longMeters: 7000...8000,
              developmentTitle: "Blocs de 10 minutes", developmentReps: 2,
              developmentWorkSeconds: 600, developmentRestSeconds: 240, developmentRPE: 6,
              rewardId: "SAI-006"),

        .init(id: "SAI-B7", index: 7, title: "Conquérant de l'Univers", arc: "Dark Matter",
              routineVolume: 90, benchmarkMeters: 9000, routinePolicy: .structuredSession,
              workingRIR: 2, routineSets: 6,
              pushSets: 6...8, pushTotalReps: 55...70, squatSets: 6, squatReps: 10...13,
              coreSets: 6, coreReps: 8...11,
              easyMinutes: 35...45, longMeters: 8500...9500,
              developmentTitle: "Blocs de 8 minutes", developmentReps: 3,
              developmentWorkSeconds: 480, developmentRestSeconds: 180, developmentRPE: 7,
              rewardId: "SAI-007"),

        .init(id: "SAI-B8", index: 8, title: "Le Plus Fort", arc: "King, Garou, conclusion",
              routineVolume: 80, benchmarkMeters: 10000, routinePolicy: .structuredSession,
              workingRIR: 2, routineSets: 5,
              pushSets: 5...6, pushTotalReps: 40...50, squatSets: 5, squatReps: 12...16,
              coreSets: 5, coreReps: 10...13,
              easyMinutes: 20...40, longMeters: 8000...9000,
              developmentTitle: "Allure de 10 km, contrôlée", developmentReps: 3,
              developmentWorkSeconds: 300, developmentRestSeconds: 180, developmentRPE: 6,
              rewardId: "SAI-008")
    ]

    static func spec(_ index: Int) -> SaitamaBlockSpec {
        all[min(max(index, 1), all.count) - 1]
    }

    static func spec(id: String) -> SaitamaBlockSpec? { all.first { $0.id == id } }
}

// MARK: - Le générateur

/// Produit les séances de Saitama à partir du bloc, du type de séance, de la
/// calibration et des échelons atteints.
///
/// Remplace l'ancien générateur en ligne droite : plus aucune séance ne sort
/// d'une interpolation de 10 à 100 répétitions.
enum SaitamaEngine {

    /// Ce qu'il faut savoir pour fabriquer une séance.
    struct Context {
        var blockIndex: Int
        var sessionType: SessionType
        var calibration: SaitamaCalibration
        /// Échelon courant par famille, qui peut avoir dépassé la calibration.
        var levels: [String: Int]
        /// Familles dont la variante vient de changer : premier contact à
        /// volume réduit, chapitre 4.
        var freshVariants: Set<String> = []
        var isDeload: Bool
        var sessionIndex: Int
        var narrativeId: String?
        var scheduling: SessionSchedulingMetadata?

        func level(_ domain: SaitamaDomain) -> Int {
            guard let family = domain.familyId else { return 1 }
            return levels[family] ?? calibration.level(domain)
        }

        func exercise(_ domain: SaitamaDomain) -> Exercise? {
            guard let family = domain.familyId else { return nil }
            return SaitamaLibrary.exercise(family: family, level: level(domain))
        }
    }

    /// Coefficients de décharge, chapitre 9 : résistance 60–70 %, course
    /// 70–80 % du volume habituel.
    private static let deloadStrength = 0.65
    private static let deloadRunning = 0.75
    /// Réduction au premier contact avec une nouvelle variante : 15 à 30 %
    /// selon la spécification, on retient 20 %.
    private static let freshVariantFactor = 0.80

    static func session(_ context: Context) -> PlannedSession {
        let spec = SaitamaBlocks.spec(context.blockIndex)
        let prescriptions: [ExercisePrescription]
        let title: String

        switch context.sessionType {
        case .strength:
            // Force A et Force B alternent : le slot pair porte la capacité,
            // l'impair la routine spécifique.
            if context.sessionIndex % 2 == 0 {
                prescriptions = forceA(spec, context)
                title = "Force A — capacité et technique"
            } else {
                prescriptions = forceB(spec, context)
                title = "Force B — routine \(spec.routineVolume)/\(spec.routineVolume)/\(spec.routineVolume)"
            }
        case .easyEndurance, .recovery:
            prescriptions = easyRun(spec, context)
            title = "Endurance facile"
        case .qualityEndurance:
            prescriptions = developmentRun(spec, context)
            title = spec.developmentTitle
        case .longEndurance:
            prescriptions = longRun(spec, context)
            title = "Sortie longue"
        default:
            prescriptions = easyRun(spec, context)
            title = "Endurance facile"
        }

        return PlannedSession(
            id: "saitama-\(context.sessionIndex)",
            programID: .saitama,
            index: context.sessionIndex + 1,
            stageIndex: spec.index - 1,
            title: context.isDeload ? "\(title) · décharge" : title,
            steps: [],
            prescribed: prescriptions,
            scheduling: context.scheduling,
            narrativeId: context.narrativeId)
    }

    // MARK: - A · Force A, capacité et technique

    private static func forceA(_ spec: SaitamaBlockSpec, _ context: Context) -> [ExercisePrescription] {
        var items = warmupStrength(context)

        let push = context.exercise(.push)
        let pushSets = spec.pushSets.lowerBound
        let pushPerSet = max(3, scale(spec.pushTotalReps.lowerBound / max(1, pushSets), context, domain: .push))
        items.append(work(name: push?.name ?? "Pompes", exercise: push,
                          sets: pushSets, perSet: pushPerSet, rest: 90,
                          rir: spec.workingRIR, context: context))

        let squat = context.exercise(.squat)
        items.append(work(name: squat?.name ?? "Squats", exercise: squat,
                          sets: spec.squatSets, perSet: scale(spec.squatReps.lowerBound, context, domain: .squat),
                          rest: 75, rir: spec.workingRIR + 1, context: context))

        let core = context.exercise(.core)
        items.append(work(name: core?.name ?? "Tronc", exercise: core,
                          sets: spec.coreSets, perSet: scale(spec.coreReps.lowerBound, context, domain: .core),
                          rest: 60, rir: spec.workingRIR, context: context))

        // chaîne postérieure et scapulaire : assistance, hors routine
        items.append(assist("Pont fessier", sets: 3, perSet: scale(12, context), rest: 45))
        items.append(assist("Reverse snow angel", sets: 2, perSet: scale(10, context), rest: 45))

        items.append(cooldown("Retour au calme", seconds: 180,
                              detail: "Marche lente, respiration, mobilité douce"))
        return items
    }

    // MARK: - B · Force B, la routine

    private static func forceB(_ spec: SaitamaBlockSpec, _ context: Context) -> [ExercisePrescription] {
        var items = warmupStrength(context, short: true)

        let sets = spec.routineSets
        let policy = spec.routinePolicy
        let rest = policy == .structuredSession ? 90 : 0

        for domain in [SaitamaDomain.push, .squat, .core] {
            let volume = scale(spec.routineVolume, context, domain: domain)
            let perSet = max(1, volume / max(1, sets))
            let exercise = context.exercise(domain)
            var item = ExercisePrescription(
                exerciseId: exercise?.id,
                name: exercise?.name ?? domain.label,
                detail: policy == .dayCumulative
                    ? "À répartir librement dans la journée"
                    : "\(sets) séries, \(rest) s de repos",
                targetValue: volume, unit: .reps,
                sets: policy == .structuredSession ? sets : nil,
                targetPerSet: policy == .structuredSession ? perSet : nil,
                restSeconds: rest > 0 ? rest : nil,
                characteristic: .force,
                targetRIR: spec.workingRIR,
                completionPolicy: policy)
            item.id = "sai.routine.\(domain.rawValue).\(context.sessionIndex)"
            item.exerciseLevel = context.level(domain)
            item.variantId = exercise?.id
            item.easierVariantId = SaitamaLibrary.exercise(family: domain.familyId ?? "",
                                                           level: context.level(domain) - 1)?.id
            item.harderVariantId = SaitamaLibrary.exercise(family: domain.familyId ?? "",
                                                           level: context.level(domain) + 1)?.id
            items.append(item)
        }

        items.append(cooldown("Retour au calme", seconds: 120, detail: "Marche et respiration"))
        return items
    }

    // MARK: - C · Endurance facile

    private static func easyRun(_ spec: SaitamaBlockSpec, _ context: Context) -> [ExercisePrescription] {
        var items = warmupRun(easy: true)
        var minutes = spec.easyMinutes.lowerBound
        if context.isDeload { minutes = Int(Double(minutes) * deloadRunning) }

        var item = ExercisePrescription(
            name: "Course facile",
            detail: "Allure de conversation. Si la course continue n'est pas encore accessible, alterne course et marche.",
            targetValue: minutes * 60, unit: .seconds,
            characteristic: .endurance,
            targetRPE: 4,
            completionPolicy: .continuous)
        item.id = "sai.easy.\(context.sessionIndex)"
        items.append(item)

        items.append(cooldown("Marche de récupération", seconds: 180, detail: nil))
        return items
    }

    // MARK: - D · Course de développement

    private static func developmentRun(_ spec: SaitamaBlockSpec, _ context: Context) -> [ExercisePrescription] {
        var items = warmupRun(easy: false)
        let reps = context.isDeload ? max(2, spec.developmentReps - 1) : spec.developmentReps

        var work = ExercisePrescription(
            name: "Bloc contrôlé",
            detail: "\(reps) fois, avec \(spec.developmentRestSeconds / 60) min de récupération facile entre chaque. Ce n'est pas une course.",
            targetValue: reps * spec.developmentWorkSeconds, unit: .seconds,
            sets: reps, targetPerSet: spec.developmentWorkSeconds,
            restSeconds: spec.developmentRestSeconds,
            characteristic: .endurance,
            targetRPE: spec.developmentRPE,
            completionPolicy: .structuredSession)
        work.id = "sai.dev.\(context.sessionIndex)"
        items.append(work)

        items.append(cooldown("Retour au calme", seconds: 300, detail: "Trot très facile puis marche"))
        return items
    }

    // MARK: - E · Sortie longue

    private static func longRun(_ spec: SaitamaBlockSpec, _ context: Context) -> [ExercisePrescription] {
        var items = warmupRun(easy: true)
        var meters = spec.longMeters.lowerBound
        if context.isDeload { meters = Int(Double(meters) * deloadRunning / 100) * 100 }

        var item = ExercisePrescription(
            name: "Sortie longue",
            detail: "Allure facile tenue. C'est la séance la plus importante de la semaine.",
            targetValue: meters, unit: .meters,
            characteristic: .endurance,
            targetRPE: 5,
            completionPolicy: .continuous)
        item.id = "sai.long.\(context.sessionIndex)"
        items.append(item)

        items.append(cooldown("Marche de récupération", seconds: 300, detail: nil))
        return items
    }

    // MARK: - Échauffements, chapitre 7

    private static func warmupStrength(_ context: Context, short: Bool = false) -> [ExercisePrescription] {
        var items: [ExercisePrescription] = [
            warmupTime("Marche active ou trot léger", seconds: 120, detail: "Se mettre en route"),
            warmupReps("Cercles d'épaules", sets: 1, perSet: 10, detail: "Dix dans chaque sens"),
            warmupReps("Scapular push-ups", sets: 2, perSet: 8, detail: "Amplitude d'omoplate seule, bras tendus")
        ]
        if !short {
            items.append(warmupReps("Squats à amplitude progressive", sets: 2, perSet: 8,
                                    detail: "De plus en plus bas à chaque série"))
            items.append(warmupReps("Dead bug", sets: 1, perSet: 6,
                                    detail: "Six de chaque côté, bas du dos plaqué au sol"))
        }
        if let push = context.exercise(.push) {
            items.append(warmupReps("\(push.name) — montée en charge", sets: 2, perSet: 5,
                                    detail: "Deux séries légères, pour retrouver le geste"))
        }
        return items
    }

    private static func warmupRun(easy: Bool) -> [ExercisePrescription] {
        var items: [ExercisePrescription] = [
            warmupTime("Marche active", seconds: easy ? 240 : 300, detail: nil),
            warmupTime("Mobilité de cheville", seconds: 60, detail: nil),
            warmupTime("Balancements de jambe", seconds: 60, detail: "Dix de chaque côté")
        ]
        if easy {
            items.append(warmupTime("Trot facile", seconds: 180, detail: nil))
        } else {
            items.append(warmupTime("Trot facile", seconds: 480, detail: nil))
            items.append(warmupTime("Accélérations progressives", seconds: 60,
                                    detail: "2 à 4 fois 15 secondes, sans sprint"))
        }
        return items
    }

    // MARK: - Fabrication

    /// Applique la décharge au volume de renforcement.
    private static func scale(_ value: Int, _ context: Context,
                              domain: SaitamaDomain? = nil) -> Int {
        var result = Double(value)
        if context.isDeload { result *= deloadStrength }
        if let family = domain?.familyId, context.freshVariants.contains(family) {
            result *= freshVariantFactor
        }
        return max(1, Int(result))
    }

    private static func work(name: String, exercise: Exercise?, sets: Int, perSet: Int,
                             rest: Int, rir: Int, context: Context) -> ExercisePrescription {
        var item = ExercisePrescription(
            exerciseId: exercise?.id,
            name: name,
            detail: exercise?.detail,
            targetValue: sets * perSet, unit: .reps,
            sets: sets, targetPerSet: perSet,
            restSeconds: rest,
            characteristic: .force,
            targetRIR: rir,
            completionPolicy: .structuredSession)
        item.id = "sai.work.\(exercise?.id ?? name).\(context.sessionIndex)"
        item.exerciseLevel = exercise?.level
        item.variantId = exercise?.id
        if let exercise = exercise {
            item.easierVariantId = SaitamaLibrary.exercise(family: exercise.familyId,
                                                          level: exercise.level - 1)?.id
            item.harderVariantId = SaitamaLibrary.exercise(family: exercise.familyId,
                                                          level: exercise.level + 1)?.id
        }
        return item
    }

    private static func assist(_ name: String, sets: Int, perSet: Int, rest: Int) -> ExercisePrescription {
        var item = ExercisePrescription(
            name: name, detail: "Assistance — ne compte pas dans la routine",
            targetValue: sets * perSet, unit: .reps,
            sets: sets, targetPerSet: perSet, restSeconds: rest,
            characteristic: .force,
            completionPolicy: .structuredSession)
        item.id = "sai.assist.\(name)"
        item.countsTowardAdaptation = false
        return item
    }

    private static func warmupTime(_ name: String, seconds: Int, detail: String?) -> ExercisePrescription {
        var item = ExercisePrescription(
            name: name, detail: detail, targetValue: seconds, unit: .seconds,
            characteristic: .mobility, completionPolicy: .structuredSession)
        item.id = "sai.warm.\(name)"
        item.isWarmup = true
        item.countsTowardAdaptation = false
        return item
    }

    private static func warmupReps(_ name: String, sets: Int, perSet: Int,
                                   detail: String?) -> ExercisePrescription {
        var item = ExercisePrescription(
            name: name, detail: detail, targetValue: sets * perSet, unit: .reps,
            sets: sets > 1 ? sets : nil, targetPerSet: sets > 1 ? perSet : nil,
            characteristic: .mobility, completionPolicy: .structuredSession)
        item.id = "sai.warm.\(name)"
        item.isWarmup = true
        item.countsTowardAdaptation = false
        return item
    }

    private static func cooldown(_ name: String, seconds: Int, detail: String?) -> ExercisePrescription {
        var item = ExercisePrescription(
            name: name, detail: detail, targetValue: seconds, unit: .seconds,
            characteristic: .mobility, completionPolicy: .structuredSession)
        item.id = "sai.cool.\(name)"
        item.isCooldown = true
        item.countsTowardAdaptation = false
        return item
    }
}
