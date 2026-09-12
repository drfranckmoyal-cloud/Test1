import Foundation

/// Le combat final d'un programme, résolu et jouable.
///
/// La définition d'un programme dit le combat en termes de spécification :
/// une cible chiffrée ici, « huit pour cent de mieux qu'au départ » là, et
/// parfois un critère qu'aucun compteur ne mesure. Cette structure fait le
/// travail de traduction une fois pour toutes : elle va chercher la mesure de
/// départ dans la calibration, en déduit la cible du jour, et dit clairement
/// quelles composantes sont obligatoires et combien des autres doivent passer.
///
/// C'est ce qui permet aux neuf combats de se jouer sur le même écran, alors
/// que celui de Saitama compte des répétitions, celui de Minato des dixièmes
/// de seconde et celui de Luffy des degrés.
struct BossChallenge: Identifiable {

    var programID: ProgramID
    var title: String
    var summary: String
    var components: [Component]
    var requirements: [String]
    var note: String?
    var rewardId: String?

    /// Combien de composantes facultatives doivent passer. Nul quand elles
    /// doivent toutes passer.
    var optionalRequired: Int?
    /// Recul toléré sur une composante facultative non retenue.
    var maxRegression: Double?
    /// Progression exigée sur une composante facultative non retenue.
    var unmetImprovement: Double?
    /// Part de la cible qu'une composante facultative non retenue doit
    /// malgré tout atteindre.
    var unmetTargetRatio: Double?

    var id: String { programID.rawValue }

    // MARK: - Une composante

    struct Component: Identifiable {
        var id: String
        var name: String
        var unit: ObjectiveUnit
        var policy: CompletionPolicy
        /// Faux quand la composante entre dans un « deux sur trois ».
        var mandatory: Bool
        /// La cible du jour, résolue. Zéro quand il n'y a rien à compter.
        var target: Int
        /// La mesure de départ, quand la cible en dépend.
        var baseline: Int?
        /// La progression exigée, en décimal.
        var improvement: Double?
        /// Vrai quand progresser veut dire baisser — un chrono.
        var lowerIsBetter: Bool
        var family: String?
        var note: String?
        /// Ce qu'on annonce, en clair.
        var targetLabel: String

        /// Vrai quand il n'y a aucun compteur : la composante se coche.
        var isDeclarative: Bool { target <= 0 }
        /// Vrai quand la cible a été calculée sur la mesure de départ.
        var isRelative: Bool { improvement != nil }
    }

    var mandatoryComponents: [Component] { components.filter(\.mandatory) }
    var optionalComponents: [Component] { components.filter { !$0.mandatory } }

    /// Combien de composantes facultatives doivent passer : celles qu'on
    /// exige, ou toutes à défaut de règle.
    var optionalThreshold: Int {
        min(optionalComponents.count, optionalRequired ?? optionalComponents.count)
    }

    /// La tolérance sur les facultatives non retenues, dite en clair.
    var toleranceLabel: String? {
        if let regression = maxRegression {
            return "Les autres ne doivent pas reculer de plus de \(percent(regression))."
        }
        if let improvement = unmetImprovement {
            return "La dernière doit tout de même avoir gagné \(percent(improvement))."
        }
        if let ratio = unmetTargetRatio {
            return "La dernière doit atteindre au moins \(percent(ratio)) de sa cible."
        }
        return nil
    }

    private func percent(_ value: Double) -> String {
        let number = value * 100
        let text = number == number.rounded()
            ? "\(Int(number))"
            : String(format: "%.1f", number).replacingOccurrences(of: ".", with: ",")
        return "\(text) %"
    }
}

// MARK: - Construction

extension BossChallenge {

    /// Fabrique le combat d'un programme à partir de sa définition et des
    /// mesures de départ du joueur.
    ///
    /// `baselines` associe l'identifiant d'un test de calibration à la mesure
    /// relevée au lancement du programme. Sans elle, une composante relative
    /// reste jouable : elle devient déclarative, et son libellé dit la
    /// progression attendue au lieu d'un chiffre qu'on ne peut pas calculer.
    static func make(_ id: ProgramID, baselines: [String: Int]) -> BossChallenge? {
        guard let boss = ProgramLibrary.definition(id)?.boss else { return nil }

        let components = boss.components.map { source -> Component in
            let unit = source.objectiveUnit
            let baseline = source.baselineTest.flatMap { baselines[$0] }
            let lower = source.lowerIsBetter ?? false

            var target = source.value ?? 0
            var label = source.targetLabel

            if let improvement = source.improvement {
                if let baseline = baseline, baseline > 0 {
                    let factor = lower ? 1 - improvement : 1 + improvement
                    target = max(1, Int((Double(baseline) * factor).rounded()))
                    label = lower
                        ? "\(unit.format(target)) au plus — \(unit.format(baseline)) au départ"
                        : "\(unit.format(target)) au moins — \(unit.format(baseline)) au départ"
                } else {
                    // sans mesure de départ, aucun chiffre n'est calculable :
                    // la composante se coche et son libellé dit la progression
                    target = 0
                }
            }

            return Component(
                id: source.id,
                name: source.name,
                unit: unit,
                policy: source.completionPolicy,
                mandatory: source.isMandatory,
                target: target,
                baseline: baseline,
                improvement: source.improvement,
                lowerIsBetter: lower,
                family: source.family,
                note: source.note,
                targetLabel: label)
        }

        return BossChallenge(
            programID: id,
            title: boss.title,
            summary: boss.summary,
            components: components,
            requirements: boss.requirements,
            note: boss.note,
            rewardId: boss.rewardId,
            optionalRequired: boss.optionalRequired,
            maxRegression: boss.maxRegression,
            unmetImprovement: boss.unmetImprovement,
            unmetTargetRatio: boss.unmetTargetRatio)
    }

    /// Les prescriptions à suivre le jour du combat.
    ///
    /// Une composante chronométrée se joue à l'envers des autres : le
    /// compteur ne monte pas vers la cible, il doit descendre en dessous.
    /// L'app ne sait pas encore compter à rebours, donc ces composantes se
    /// cochent et leur libellé porte le chiffre à battre.
    var prescriptions: [ExercisePrescription] {
        components.map { component in
            var item = ExercisePrescription(
                name: component.name,
                detail: component.note ?? component.policy.instruction,
                targetValue: max(1, component.target),
                unit: component.unit,
                characteristic: characteristic(component),
                completionPolicy: component.policy)
            item.id = component.id
            item.countsTowardAdaptation = component.mandatory
            if component.isDeclarative || component.lowerIsBetter {
                item.amountOverride = component.targetLabel
            }
            return item
        }
    }

    /// Une composante ne se coche pas comme les autres quand elle n'a pas de
    /// compteur qui monte.
    func isCounted(_ component: Component) -> Bool {
        !component.isDeclarative && !component.lowerIsBetter
    }

    private func characteristic(_ component: Component) -> TrainingCharacteristic {
        switch component.unit {
        case .meters: return .endurance
        case .seconds: return component.lowerIsBetter ? .speed : .control
        case .centiseconds: return .speed
        case .centimeters: return .power
        case .degrees: return .mobility
        case .reps, .kg: return .force
        }
    }
}

// MARK: - L'issue du combat

extension BossChallenge {

    /// Ce que valent les compteurs du jour au regard de la règle du combat.
    struct Outcome {
        var mandatoryDone: Int
        var mandatoryTotal: Int
        var optionalDone: Int
        var optionalThreshold: Int

        var mandatoryOK: Bool { mandatoryDone >= mandatoryTotal }
        var optionalOK: Bool { optionalDone >= optionalThreshold }
        var isWon: Bool { mandatoryOK && optionalOK }

        /// Ce qui manque, dit en clair.
        var missing: [String] {
            var items: [String] = []
            if !mandatoryOK {
                let left = mandatoryTotal - mandatoryDone
                items.append(left == 1
                    ? "une composante obligatoire reste à valider"
                    : "\(left) composantes obligatoires restent à valider")
            }
            if !optionalOK {
                let left = optionalThreshold - optionalDone
                items.append(left == 1
                    ? "une performance de plus à valider"
                    : "\(left) performances de plus à valider")
            }
            return items
        }
    }

    /// Juge le combat sur les objectifs de la journée ouverte.
    func outcome(_ objectives: [String: DailyObjectiveProgress]) -> Outcome {
        func done(_ component: Component) -> Bool {
            objectives[component.id]?.status.isDone ?? false
        }
        return Outcome(
            mandatoryDone: mandatoryComponents.filter(done).count,
            mandatoryTotal: mandatoryComponents.count,
            optionalDone: optionalComponents.filter(done).count,
            optionalThreshold: optionalThreshold)
    }
}

// MARK: - L'accès au combat

/// Ce qui ouvre la porte du combat final d'un programme écrit par le coach.
///
/// Le combat n'est pas une séance de plus : il se passe une fois la route
/// parcourue. On n'en fait donc pas un examen surprise — on regarde si le
/// plan est allé au bout, et si le point de départ a bien été mesuré, sans
/// quoi aucune progression relative n'est calculable.
struct BossAccess {
    var planComplete: Bool
    var sessionsDone: Int
    var sessionsPlanned: Int
    var calibrated: Bool
    var lastSessionOK: Bool

    var isEligible: Bool { planComplete && calibrated && lastSessionOK }

    var missing: [String] {
        var items: [String] = []
        if !planComplete {
            let left = max(0, sessionsPlanned - sessionsDone)
            items.append(left == 1
                ? "la dernière séance du parcours"
                : "\(left) séances pour finir le parcours")
        }
        if !calibrated {
            items.append("tes mesures de départ, sans lesquelles aucune progression ne se calcule")
        }
        if !lastSessionOK {
            items.append("une séance récente menée à son terme")
        }
        return items
    }
}
