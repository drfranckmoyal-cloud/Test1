import Foundation

/// Le catalogue et le contenu sportif.
///
/// Deux programmes sont jouables : Saitama et Naruto. Les sept autres sont
/// dans le catalogue, verrouillés, avec leur condition d'ouverture — ils
/// existent pour qu'on voie où l'on va, pas encore pour être suivis.
enum Catalog {

    static let programs: [Program] = [
        Program(
            id: .saitama, name: "Saitama", family: "Transformation physique",
            pitch: "Pompes, abdominaux, squats et course, montés ensemble sur huit jalons jusqu'à la routine complète tenue en une seule journée. Tu ne travailles pas une qualité : tu les montes toutes à la fois. Deviens obstiné comme Saitama — il n'a jamais rien fait d'autre que répéter.",
            stages: ["Salaryman raté", "Le déclic", "Trois mois de discipline",
                     "La première année", "La deuxième année", "Les cheveux perdus",
                     "Héros de classe C", "Demi-dieu"],
            sessionsPerStage: [10, 10, 10, 10, 11, 11, 11, 11],
            rhythm: "Tous les jours", equipment: "Aucun",
            darkColor: 0xD6202A, lightColor: 0xF5C518, unlock: .open, playable: true),

        Program(
            id: .naruto, name: "Naruto", family: "Résilience",
            pitch: "Courir, longtemps, de plus en plus loin. Cinq jalons pour passer de l'alternance course-marche au semi-marathon couru d'une traite. Deviens endurant et persévérant comme Naruto — il ne lâche jamais.",
            stages: ["Numéro un imprévisible", "Rasengan", "Mode Ermite",
                     "Chakra de Kurama", "Hokage"],
            sessionsPerStage: [6, 6, 6, 6, 3],
            rhythm: "3 sorties par semaine", equipment: "Aucun",
            darkColor: 0x0E2340, lightColor: 0xF47B20, unlock: .open, playable: true),

        Program(
            id: .rocklee, name: "Rock Lee", family: "Explosivité",
            pitch: "Sauter, rebondir, accélérer. Peu de répétitions, beaucoup de qualité, beaucoup de repos. Cinq jalons pour gagner de la détente et de la vitesse d'appui. Deviens explosif à force de travail, comme Rock Lee.",
            stages: ["Porte de l'Ouverture", "Porte du Repos", "Porte de la Vie",
                     "Porte de la Blessure", "Porte de la Limite", "Porte de la Vue",
                     "Porte de la Merveille", "Porte de la Mort"],
            sessionsPerStage: [5, 5, 5, 5, 5, 5, 5, 5],
            rhythm: "5 séances par semaine", equipment: "Corde à sauter",
            darkColor: 0x0C3F24, lightColor: 0x1E8449,
            unlock: .stat(.force, 20), playable: true),

        Program(
            id: .kenshiro, name: "Kenshiro", family: "Force pure",
            pitch: "La force au poids du corps, poussée jusqu'à ses variantes les plus dures : pompe à une main, tractions strictes, squat sur une jambe. Sept jalons, peu de répétitions, beaucoup de tension. Deviens implacable comme Kenshiro.",
            stages: ["Dubhe", "Merak", "Phecda", "Megrez", "Alioth", "Mizar", "Alkaid"],
            sessionsPerStage: [4, 4, 4, 4, 4, 4, 4],
            rhythm: "3 séances par semaine", equipment: "Barre de traction",
            darkColor: 0x2A0A0A, lightColor: 0x8B1A1A,
            unlock: .stat(.force, 45), playable: true),

        Program(
            id: .ichigo, name: "Ichigo", family: "Six cibles",
            pitch: "Six chiffres à tenir : cent pompes, deux cents abdominaux et cent squats dans la journée, dix tractions et cinquante pompes d'affilée, cinq kilomètres. Neuf jalons pour les réunir le même jour. Deviens tenace comme Ichigo.",
            stages: ["100 pompes dans la journée", "200 abdos dans la journée",
                     "100 squats dans la journée", "10 tractions d'affilée",
                     "50 pompes d'affilée", "5 km sans marcher", "Bankai"],
            sessionsPerStage: [1, 1, 1, 1, 1, 1, 1],
            rhythm: "À ton rythme", equipment: "Barre de traction",
            darkColor: 0x1A1A1A, lightColor: 0xC0392B,
            unlock: .rank(.b), playable: true),

        Program(
            id: .minato, name: "Minato", family: "Vitesse",
            pitch: "Courir vite, sur dix, trente et soixante mètres. Beaucoup de récupération, jamais de sprint fatigué : on ne court vite qu'en étant frais. Sept jalons pour gagner des dixièmes. Deviens insaisissable comme Minato.",
            stages: ["Genin", "Chūnin", "Jōnin", "ANBU", "L'Éclair Jaune",
                     "Hiraishin", "Yondaime Hokage"],
            sessionsPerStage: [3, 3, 3, 3, 2, 2, 2],
            rhythm: "2 séances par semaine", equipment: "60 m de plat",
            darkColor: 0x2C4A8C, lightColor: 0xF5D547,
            unlock: .stat(.vitesse, 25), playable: true),

        Program(
            id: .levi, name: "Levi", family: "Gainage",
            pitch: "Gainage, suspension, tractions, contrôle croisé. Des séances courtes qui construisent un tronc qui ne cède pas. Cinq jalons jusqu'aux cinq standards tenus la même semaine. Deviens précis et inébranlable comme Levi.",
            stages: ["Recrue", "Bataillon d'exploration", "Escouade d'élite",
                     "Caporal-chef", "Le plus fort de l'humanité"],
            sessionsPerStage: [5, 5, 5, 5, 4],
            rhythm: "4 séances par semaine", equipment: "Barre de traction",
            darkColor: 0x1C241E, lightColor: 0x4A5D4E,
            unlock: .stat(.force, 30), playable: true),

        Program(
            id: .luffy, name: "Luffy", family: "Souplesse",
            pitch: "Gagner de l'amplitude et apprendre à la contrôler : chevilles, hanches, ischios, épaules, buste. Des séances courtes, presque tous les jours. Cinq jalons pour cinq familles. Deviens libre de tes mouvements comme Luffy.",
            stages: ["Gomu Gomu", "Gear 2", "Gear 3", "Gear 4", "Gear 5"],
            sessionsPerStage: [7, 7, 7, 7, 7],
            rhythm: "Tous les jours", equipment: "Aucun",
            darkColor: 0x7A1010, lightColor: 0xD62828,
            unlock: .rank(.d), playable: true),

        Program(
            id: .goku, name: "Goku", family: "Progression extrême",
            pitch: "Pousser, tirer, porter plus lourd de semaine en semaine, avec un simple sac lesté. Huit jalons pour refaire le test du premier jour avec un quart de charge en plus. Deviens plus fort à chaque palier, comme Goku.",
            stages: ["Base", "Kaiō-ken", "Kaiō-ken ×4", "Super Saiyan",
                     "Super Saiyan 2", "Super Saiyan 3", "Super Saiyan Blue", "Ultra Instinct"],
            sessionsPerStage: [5, 5, 5, 5, 5, 5, 5, 5],
            rhythm: "4 séances par semaine", equipment: "Sac lesté",
            darkColor: 0x12406B, lightColor: 0xFF6B00,
            unlock: .rank(.a), playable: true)
    ]

    static func program(_ id: ProgramID) -> Program {
        programs.first { $0.id == id } ?? programs[0]
    }

    /// Toutes les séances d'un programme, calibrées sur le palier choisi.
    static func sessions(for id: ProgramID, tier: Tier, intensity: Double = 1.0) -> [PlannedSession] {
        let all = build(id, tier: tier)
        return intensity == 1.0 ? all : all.map { $0.scaled(by: intensity) }
    }

    private static func build(_ id: ProgramID, tier: Tier) -> [PlannedSession] {
        switch id {
        case .saitama: return saitamaSessions(tier: tier)
        case .naruto: return narutoSessions(tier: tier)
        case .rocklee: return rockLeeSessions(tier: tier)
        case .kenshiro: return kenshiroSessions(tier: tier)
        case .ichigo: return ichigoSessions(tier: tier)
        case .minato: return minatoSessions(tier: tier)
        case .levi: return leviSessions(tier: tier)
        case .luffy: return luffySessions(tier: tier)
        case .goku: return gokuSessions(tier: tier)
        }
    }

    static func session(for id: ProgramID, index: Int, tier: Tier,
                        intensity: Double = 1.0) -> PlannedSession? {
        let all = sessions(for: id, tier: tier, intensity: intensity)
        guard index >= 0 && index < all.count else { return nil }
        return all[index]
    }

    // MARK: - Saitama

    /// Objectif de fin de chaque étape : répétitions par exercice, puis mètres
    /// de course. La progression est linéaire à l'intérieur d'une étape.
    private static let saitamaTargets: [(reps: Int, meters: Int)] = [
        (20, 1000), (30, 1500), (40, 2000), (50, 3000),
        (65, 4000), (80, 5000), (90, 7000), (100, 10000)
    ]
    private static let saitamaStart = (reps: 10, meters: 600)

    private static func saitamaSessions(tier: Tier) -> [PlannedSession] {
        let program = self.program(.saitama)
        var sessions: [PlannedSession] = []
        var index = 0

        for stage in 0..<program.sessionsPerStage.count {
            let count = program.sessionsPerStage[stage]
            let from = stage == 0 ? saitamaStart : saitamaTargets[stage - 1]
            let to = saitamaTargets[stage]

            for position in 0..<count {
                let t = Double(position + 1) / Double(count)
                let reps = scaled(Double(from.reps) + (Double(to.reps) - Double(from.reps)) * t, tier)
                let meters = scaled(Double(from.meters) + (Double(to.meters) - Double(from.meters)) * t, tier)

                var steps: [SessionStep] = []
                var stepID = 0
                for (name, stat, rest) in [("Pompes", StatKind.force, 60),
                                           ("Abdos", StatKind.force, 45),
                                           ("Squats", StatKind.force, 45)] {
                    let perSet = max(1, Int((Double(reps) / 4.0).rounded()))
                    for set in 1...4 {
                        steps.append(SessionStep(
                            id: stepID, name: name, detail: "Série \(set) sur 4",
                            goal: Goal(unit: .reps, value: perSet),
                            restSeconds: set == 4 ? 90 : rest, stat: stat))
                        stepID += 1
                    }
                }
                steps.append(SessionStep(
                    id: stepID, name: "Course", detail: "Allure libre, sans t'arrêter",
                    goal: Goal(unit: .meters, value: roundMeters(meters)),
                    restSeconds: 0, stat: .endurance))

                index += 1
                sessions.append(PlannedSession(
                    id: "saitama-\(index)", programID: .saitama, index: index,
                    stageIndex: stage, title: "Jour \(index)", steps: steps))
            }
        }
        return sessions
    }

    // MARK: - Naruto

    /// Les neuf semaines du plan « Couch to 5K », une ligne par séance.
    /// Chaque couple est (secondes de course, secondes de marche) ; une marche
    /// à zéro termine la séance.
    private static func narutoIntervals(week: Int, session: Int) -> [(run: Int, walk: Int)] {
        switch week {
        case 1: return Array(repeating: (60, 90), count: 8)
        case 2: return Array(repeating: (90, 120), count: 6)
        case 3: return [(90, 90), (180, 180), (90, 90), (180, 0)]
        case 4: return [(180, 90), (300, 150), (180, 90), (300, 0)]
        case 5:
            if session == 0 { return [(300, 180), (300, 180), (300, 0)] }
            if session == 1 { return [(480, 300), (480, 0)] }
            return [(1200, 0)]
        case 6:
            if session == 0 { return [(300, 180), (480, 180), (300, 0)] }
            if session == 1 { return [(600, 180), (600, 0)] }
            return [(1500, 0)]
        case 7: return [(1500, 0)]
        case 8: return [(1680, 0)]
        default: return [(1800, 0)]
        }
    }

    private static func narutoSessions(tier: Tier) -> [PlannedSession] {
        let program = self.program(.naruto)
        var sessions: [PlannedSession] = []
        var index = 0

        for week in 1...9 {
            for session in 0..<3 {
                let intervals = narutoIntervals(week: week, session: session)
                var steps: [SessionStep] = []
                var stepID = 0

                steps.append(SessionStep(
                    id: stepID, name: "Marche d'échauffement",
                    detail: "Tranquillement, le temps de se mettre en route",
                    goal: Goal(unit: .seconds, value: 300), restSeconds: 0, stat: .endurance))
                stepID += 1

                for (position, interval) in intervals.enumerated() {
                    let run = max(30, Int((Double(interval.run) * tier.load).rounded() / 10) * 10)
                    steps.append(SessionStep(
                        id: stepID, name: "Course",
                        detail: "Bloc \(position + 1) sur \(intervals.count)",
                        goal: Goal(unit: .seconds, value: run), restSeconds: 0, stat: .endurance))
                    stepID += 1
                    if interval.walk > 0 {
                        steps.append(SessionStep(
                            id: stepID, name: "Marche",
                            detail: "Récupération active",
                            goal: Goal(unit: .seconds, value: interval.walk),
                            restSeconds: 0, stat: .endurance))
                        stepID += 1
                    }
                }

                steps.append(SessionStep(
                    id: stepID, name: "Retour au calme",
                    detail: "Marche lente, respiration",
                    goal: Goal(unit: .seconds, value: 180), restSeconds: 0, stat: .endurance))

                index += 1
                let stage = program.stageIndex(forSession: index - 1)
                sessions.append(PlannedSession(
                    id: "naruto-\(index)", programID: .naruto, index: index,
                    stageIndex: stage,
                    title: "Semaine \(week), sortie \(session + 1)", steps: steps))
            }
        }
        return sessions
    }

    // MARK: - Assemblage commun

    /// Un bloc d'exercice : le même mouvement répété en séries.
    private struct Block {
        var name: String
        var sets: Int
        var goal: Goal
        var rest: Int
        var stat: StatKind
        /// Repos après la dernière série, avant l'exercice suivant.
        var breakAfter: Int = 90
        var note: String?
    }

    /// Déplie des blocs en étapes de séance. Toute la mécanique de séance —
    /// séries, repos, numérotation — tient ici : les programmes ne décrivent
    /// que leur contenu.
    private static func assemble(_ id: ProgramID,
                                 _ perSession: [[Block]],
                                 title: (Int) -> String) -> [PlannedSession] {
        let program = self.program(id)
        var sessions: [PlannedSession] = []

        for position in perSession.indices {
            var steps: [SessionStep] = []
            var stepID = 0
            for block in perSession[position] {
                guard block.sets > 0, block.goal.value > 0 else { continue }
                for set in 1...block.sets {
                    let count = block.sets > 1 ? "Série \(set) sur \(block.sets)" : ""
                    let detail = [count, block.note ?? ""]
                        .filter { !$0.isEmpty }
                        .joined(separator: " · ")
                    steps.append(SessionStep(
                        id: stepID, name: block.name, detail: detail, goal: block.goal,
                        restSeconds: set == block.sets ? block.breakAfter : block.rest,
                        stat: block.stat))
                    stepID += 1
                }
            }
            if var last = steps.last {
                last.restSeconds = 0          // pas de repos après le dernier effort
                steps[steps.count - 1] = last
            }
            sessions.append(PlannedSession(
                id: "\(id.rawValue)-\(position + 1)", programID: id, index: position + 1,
                stageIndex: program.stageIndex(forSession: position),
                title: title(position), steps: steps))
        }
        return sessions
    }

    /// Interpole une valeur entre un début et une fin, sur la longueur d'un
    /// programme, puis l'ajuste au palier.
    private static func ramp(_ from: Double, _ to: Double, _ position: Int, _ count: Int, _ tier: Tier) -> Int {
        guard count > 1 else { return scaled(to, tier) }
        let t = Double(position) / Double(count - 1)
        return scaled(from + (to - from) * t, tier)
    }

    // MARK: - Rock Lee · explosivité

    /// Pliométrie et corde à sauter. Les séances impaires sont lourdes en
    /// sauts, les paires travaillent la vitesse d'exécution : deux séances
    /// pliométriques rapprochées sur la même semaine abîment plus qu'elles
    /// ne construisent.
    private static func rockLeeSessions(tier: Tier) -> [PlannedSession] {
        let count = program(.rocklee).totalSessions
        var perSession: [[Block]] = []

        for position in 0..<count {
            let heavy = position % 2 == 0
            let rope = ramp(45, 150, position, count, tier)
            let jumps = ramp(8, 22, position, count, tier)
            let lunges = ramp(6, 16, position, count, tier)
            let pushA = ramp(10, 30, position, count, tier)
            let pushB = ramp(6, 20, position, count, tier)
            let burpees = ramp(5, 18, position, count, tier)

            var blocks: [Block] = [
                Block(name: "Corde à sauter", sets: 3, goal: Goal(unit: .seconds, value: rope),
                      rest: 45, stat: .endurance, breakAfter: 75, note: nil)
            ]
            if heavy {
                blocks.append(Block(name: "Sauts groupés", sets: 4, goal: Goal(unit: .reps, value: jumps),
                                    rest: 75, stat: .vitesse, breakAfter: 90, note: nil))
                blocks.append(Block(name: "Fentes sautées", sets: 3, goal: Goal(unit: .reps, value: lunges),
                                    rest: 75, stat: .vitesse, breakAfter: 90, note: "Par jambe"))
            } else {
                blocks.append(Block(name: "Montées de genoux", sets: 3, goal: Goal(unit: .seconds, value: 30),
                                    rest: 45, stat: .vitesse, breakAfter: 75, note: "Rythme le plus haut possible"))
                blocks.append(Block(name: "Burpees", sets: 3, goal: Goal(unit: .reps, value: burpees),
                                    rest: 75, stat: .endurance, breakAfter: 90, note: nil))
            }
            // le schéma 30-30-20 du personnage, monté progressivement
            blocks.append(Block(name: "Pompes", sets: 2, goal: Goal(unit: .reps, value: pushA),
                                rest: 60, stat: .force, breakAfter: 60, note: nil))
            blocks.append(Block(name: "Pompes", sets: 1, goal: Goal(unit: .reps, value: pushB),
                                rest: 0, stat: .force, breakAfter: 0, note: "Dernière série, jusqu'au bout"))
            perSession.append(blocks)
        }

        return assemble(.rocklee, perSession) { "Séance \($0 + 1)" }
    }

    // MARK: - Kenshiro · force pure

    /// Peu de répétitions, beaucoup de tension. La progression ne vient pas
    /// du nombre mais de la difficulté du mouvement : une étoile, une
    /// variante plus dure.
    private static let kenshiroPush = ["Pompes", "Pompes déclinées", "Pompes diamant",
                                       "Pompes archer", "Pompes surélevées lestées",
                                       "Pompes excentriques une main", "Pompes une main"]
    private static let kenshiroLegs = ["Squats bulgares", "Squats sautés lestés", "Fentes lestées",
                                       "Pistol assisté", "Pistol au poteau", "Pistol", "Pistol lesté"]
    private static let kenshiroPull = ["Tractions négatives", "Tractions", "Tractions prise large",
                                       "Tractions lentes", "Tractions lestées", "Tractions archer",
                                       "Tractions une main assistées"]

    private static func kenshiroSessions(tier: Tier) -> [PlannedSession] {
        let program = self.program(.kenshiro)
        var perSession: [[Block]] = []

        for position in 0..<program.totalSessions {
            let star = min(program.stageIndex(forSession: position), kenshiroPush.count - 1)
            let within = position - program.firstSession(ofStage: star)
            let reps = scaled(Double(4 + within), tier)          // 4, 5, 6, 7 dans l'étoile
            let hold = scaled(Double(25 + within * 5), tier)

            perSession.append([
                Block(name: kenshiroPush[star], sets: 5, goal: Goal(unit: .reps, value: reps),
                      rest: 120, stat: .force, breakAfter: 150, note: "Descente lente, 3 secondes"),
                Block(name: kenshiroPull[star], sets: 4, goal: Goal(unit: .reps, value: max(2, reps - 1)),
                      rest: 150, stat: .force, breakAfter: 150, note: nil),
                Block(name: kenshiroLegs[star], sets: 4, goal: Goal(unit: .reps, value: reps),
                      rest: 120, stat: .force, breakAfter: 120, note: "Par jambe"),
                Block(name: "Gainage lesté", sets: 3, goal: Goal(unit: .seconds, value: hold),
                      rest: 60, stat: .force, breakAfter: 0, note: nil)
            ])
        }

        return assemble(.kenshiro, perSession) { position in
            let star = min(self.program(.kenshiro).stageIndex(forSession: position),
                           self.program(.kenshiro).stages.count - 1)
            return self.program(.kenshiro).stages[star]
        }
    }

    // MARK: - Ichigo · objectifs

    /// Une cible unique par étape. Rien à planifier : on s'y attaque quand on
    /// se sent prêt, et on ne passe à la suivante qu'une fois celle-ci tombée.
    private static func ichigoSessions(tier: Tier) -> [PlannedSession] {
        let targets: [(name: String, goal: Goal, stat: StatKind, note: String)] = [
            ("Pompes", Goal(unit: .reps, value: 100), .force, "Dans la journée, en autant de séries qu'il faut"),
            ("Abdos", Goal(unit: .reps, value: 200), .force, "Dans la journée, en autant de séries qu'il faut"),
            ("Squats", Goal(unit: .reps, value: 100), .force, "Dans la journée, en autant de séries qu'il faut"),
            ("Tractions", Goal(unit: .reps, value: 10), .force, "D'affilée, sans lâcher la barre"),
            ("Pompes", Goal(unit: .reps, value: 50), .force, "D'affilée, sans poser les genoux"),
            ("Course", Goal(unit: .meters, value: 5000), .endurance, "Sans marcher une seule fois"),
            ("Bankai", Goal(unit: .reps, value: 1), .force, "Les six objectifs, le même jour")
        ]

        let perSession = targets.map { target in
            [Block(name: target.name, sets: 1, goal: target.goal, rest: 0,
                   stat: target.stat, breakAfter: 0, note: target.note)]
        }

        return assemble(.ichigo, perSession) { self.program(.ichigo).stages[$0] }
    }

    // MARK: - Minato · vitesse

    /// Sprints courts et pliométrie horizontale, deux séances par semaine
    /// séparées de soixante-douze heures. La récupération entre les sprints
    /// est longue par nécessité : un sprint couru fatigué n'est plus un sprint.
    private static func minatoSessions(tier: Tier) -> [PlannedSession] {
        let count = program(.minato).totalSessions
        var perSession: [[Block]] = []

        for position in 0..<count {
            let sprints = 4 + position / 4                        // de 4 à 8 répétitions
            let distance = roundTo(ramp(30, 60, position, count, tier), 5)
            let bounds = ramp(6, 14, position, count, tier)

            perSession.append([
                Block(name: "Montées de genoux", sets: 2, goal: Goal(unit: .seconds, value: 25),
                      rest: 40, stat: .vitesse, breakAfter: 60, note: "Éducatif, pas de vitesse maximale"),
                Block(name: "Talons-fesses", sets: 2, goal: Goal(unit: .seconds, value: 25),
                      rest: 40, stat: .vitesse, breakAfter: 90, note: "Éducatif"),
                Block(name: "Foulées bondissantes", sets: 3, goal: Goal(unit: .reps, value: bounds),
                      rest: 90, stat: .vitesse, breakAfter: 120, note: "Chercher l'amplitude, pas la fréquence"),
                Block(name: "Sprint", sets: sprints, goal: Goal(unit: .meters, value: distance),
                      rest: 180, stat: .vitesse, breakAfter: 120,
                      note: "À fond. Trois minutes de marche entre chaque"),
                Block(name: "Retour au calme", sets: 1, goal: Goal(unit: .seconds, value: 300),
                      rest: 0, stat: .endurance, breakAfter: 0, note: "Marche lente")
            ])
        }

        return assemble(.minato, perSession) { "Séance \($0 + 1)" }
    }

    // MARK: - Levi · gainage

    /// Puissance rapportée au poids de corps. Séances courtes, denses, sans
    /// matériel lourd : ce que l'équipement tridimensionnel exigerait d'un
    /// corps humain, c'est de tenir son propre poids en l'air.
    private static func leviSessions(tier: Tier) -> [PlannedSession] {
        let count = program(.levi).totalSessions
        var perSession: [[Block]] = []

        for position in 0..<count {
            let plank = ramp(30, 120, position, count, tier)
            let side = ramp(20, 75, position, count, tier)
            let hollow = ramp(15, 60, position, count, tier)
            let hang = ramp(20, 90, position, count, tier)
            let pulls = ramp(2, 12, position, count, tier)
            let raises = ramp(5, 18, position, count, tier)

            perSession.append([
                Block(name: "Gainage ventral", sets: 3, goal: Goal(unit: .seconds, value: plank),
                      rest: 45, stat: .force, breakAfter: 60, note: nil),
                Block(name: "Gainage latéral", sets: 2, goal: Goal(unit: .seconds, value: side),
                      rest: 30, stat: .force, breakAfter: 60, note: "De chaque côté"),
                Block(name: "Hollow hold", sets: 3, goal: Goal(unit: .seconds, value: hollow),
                      rest: 45, stat: .force, breakAfter: 75, note: "Bas du dos plaqué au sol"),
                Block(name: "Tractions", sets: 4, goal: Goal(unit: .reps, value: pulls),
                      rest: 120, stat: .force, breakAfter: 90, note: nil),
                Block(name: "Relevés de jambes suspendu", sets: 3, goal: Goal(unit: .reps, value: raises),
                      rest: 75, stat: .force, breakAfter: 75, note: nil),
                Block(name: "Suspension à la barre", sets: 2, goal: Goal(unit: .seconds, value: hang),
                      rest: 60, stat: .force, breakAfter: 0, note: "Tenir, simplement")
            ])
        }

        return assemble(.levi, perSession) { "Séance \($0 + 1)" }
    }

    // MARK: - Luffy · souplesse

    /// Dix minutes par jour, tous les jours. C'est le programme qu'on garde
    /// en fond pendant les autres : il ne fatigue pas, il répare.
    private static func luffySessions(tier: Tier) -> [PlannedSession] {
        let count = program(.luffy).totalSessions
        var perSession: [[Block]] = []

        for position in 0..<count {
            let hold = ramp(25, 60, position, count, tier)
            let flow = ramp(45, 90, position, count, tier)

            perSession.append([
                Block(name: "Mobilité des épaules", sets: 2, goal: Goal(unit: .seconds, value: flow),
                      rest: 15, stat: .endurance, breakAfter: 20, note: "Cercles lents, amplitude maximale"),
                Block(name: "Ouverture de hanches", sets: 2, goal: Goal(unit: .seconds, value: hold),
                      rest: 15, stat: .force, breakAfter: 20, note: "De chaque côté"),
                Block(name: "Ischio-jambiers", sets: 2, goal: Goal(unit: .seconds, value: hold),
                      rest: 15, stat: .force, breakAfter: 20, note: "De chaque côté, jambe tendue sans forcer"),
                Block(name: "Rotation du buste", sets: 2, goal: Goal(unit: .seconds, value: hold),
                      rest: 15, stat: .force, breakAfter: 20, note: "De chaque côté"),
                Block(name: "Chevilles et mollets", sets: 2, goal: Goal(unit: .seconds, value: hold),
                      rest: 15, stat: .endurance, breakAfter: 20, note: "De chaque côté"),
                Block(name: "Respiration", sets: 1, goal: Goal(unit: .seconds, value: 90),
                      rest: 0, stat: .endurance, breakAfter: 0, note: "Allongé, sans rien faire d'autre")
            ])
        }

        return assemble(.luffy, perSession) { "Jour \($0 + 1)" }
    }

    // MARK: - Goku · progression extrême

    /// Chaque transformation multiplie la charge de la précédente. Le
    /// Kaiō-ken ×4 est déjà un multiplicateur dans l'œuvre : il le devient
    /// ici, appliqué au volume d'un circuit qui ne change pas de forme.
    private static let gokuMultipliers: [Double] = [1.0, 1.3, 1.6, 2.0, 2.4, 2.8, 3.2, 3.6]

    private static func gokuSessions(tier: Tier) -> [PlannedSession] {
        let program = self.program(.goku)
        var perSession: [[Block]] = []

        for position in 0..<program.totalSessions {
            let stage = min(program.stageIndex(forSession: position), gokuMultipliers.count - 1)
            let within = position - program.firstSession(ofStage: stage)
            let multiplier = gokuMultipliers[stage] * (1.0 + Double(within) * 0.04)
            let rounds = 3 + stage / 3                       // 3 tours, puis 4, puis 5

            func amount(_ base: Double) -> Int { scaled(base * multiplier, tier) }

            perSession.append([
                Block(name: "Pompes lestées", sets: rounds, goal: Goal(unit: .reps, value: amount(10)),
                      rest: 60, stat: .force, breakAfter: 60, note: "Sac sur le dos"),
                Block(name: "Squats lestés", sets: rounds, goal: Goal(unit: .reps, value: amount(12)),
                      rest: 60, stat: .force, breakAfter: 60, note: "Sac sur le dos"),
                Block(name: "Tractions", sets: rounds, goal: Goal(unit: .reps, value: amount(3)),
                      rest: 90, stat: .force, breakAfter: 60, note: nil),
                Block(name: "Gainage", sets: rounds, goal: Goal(unit: .seconds, value: amount(25)),
                      rest: 45, stat: .force, breakAfter: 60, note: nil),
                Block(name: "Course", sets: 1, goal: Goal(unit: .meters, value: roundMeters(amount(700))),
                      rest: 0, stat: .endurance, breakAfter: 0, note: "Allure soutenue")
            ])
        }

        return assemble(.goku, perSession) { position in
            let stage = min(self.program(.goku).stageIndex(forSession: position),
                            self.program(.goku).stages.count - 1)
            let within = position - self.program(.goku).firstSession(ofStage: stage)
            return "\(self.program(.goku).stages[stage]) · \(within + 1)"
        }
    }

    // MARK: - Outils

    private static func scaled(_ value: Double, _ tier: Tier) -> Int {
        max(1, Int((value * tier.load).rounded()))
    }

    /// Arrondit au multiple le plus proche, pour que les cibles restent lisibles.
    private static func roundTo(_ value: Int, _ step: Int) -> Int {
        max(step, Int((Double(value) / Double(step)).rounded()) * step)
    }

    /// Des mètres ronds : personne ne court 1 847 m.
    private static func roundMeters(_ meters: Int) -> Int {
        meters >= 2000 ? Int((Double(meters) / 500).rounded()) * 500
                       : Int((Double(meters) / 100).rounded()) * 100
    }
}
