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
            pitch: "La routine canonique — 100 pompes, 100 abdos, 100 squats, 10 km — mais montée sur douze semaines au lieu du premier jour. Le corps qui n'a rien fait depuis dix ans devient celui qui encaisse tout.",
            stages: ["Salaryman raté", "Le déclic", "Trois mois de discipline",
                     "La première année", "La deuxième année", "Les cheveux perdus",
                     "Héros de classe C", "Demi-dieu"],
            sessionsPerStage: [10, 10, 10, 10, 11, 11, 11, 11],
            rhythm: "Tous les jours", equipment: "Aucun",
            darkColor: 0xD6202A, lightColor: 0xF5C518, unlock: .open, playable: true),

        Program(
            id: .naruto, name: "Naruto", family: "Résilience",
            pitch: "De zéro à cinq kilomètres courus sans marcher. Neuf semaines, trois sorties, des intervalles course-marche qui se résorbent. Le personnage qui ne lâche jamais porte la seule qualité qui se gagne par la répétition.",
            stages: ["Numéro un imprévisible", "Rasengan", "Mode Ermite",
                     "Chakra de Kurama", "Hokage"],
            sessionsPerStage: [6, 6, 6, 6, 3],
            rhythm: "3 sorties par semaine", equipment: "Aucun",
            darkColor: 0x0E2340, lightColor: 0xF47B20, unlock: .open, playable: true),

        Program(
            id: .rocklee, name: "Rock Lee", family: "Explosivité",
            pitch: "Pliométrie, corde à sauter, séries de pompes en 30-30-20. Huit portes, huit crans d'intensité.",
            stages: ["Porte de l'Ouverture", "Porte du Repos", "Porte de la Vie",
                     "Porte de la Blessure", "Porte de la Limite", "Porte de la Vue",
                     "Porte de la Merveille", "Porte de la Mort"],
            sessionsPerStage: [5, 5, 5, 5, 5, 5, 5, 5],
            rhythm: "5 séances par semaine", equipment: "Corde à sauter",
            darkColor: 0x0C3F24, lightColor: 0x1E8449,
            unlock: .stat(.force, 20), playable: false),

        Program(
            id: .kenshiro, name: "Kenshiro", family: "Force pure",
            pitch: "Force maximale au poids du corps : pompes archer puis à une main, squats pistol, tractions lestées. Peu de répétitions, beaucoup de tension.",
            stages: ["Dubhe", "Merak", "Phecda", "Megrez", "Alioth", "Mizar", "Alkaid"],
            sessionsPerStage: [4, 4, 4, 4, 4, 4, 4],
            rhythm: "3 séances par semaine", equipment: "Barre de traction",
            darkColor: 0x2A0A0A, lightColor: 0x8B1A1A,
            unlock: .stat(.force, 45), playable: false),

        Program(
            id: .ichigo, name: "Ichigo", family: "Objectifs",
            pitch: "Pas de planning : une cible unique à la fois, énorme et nette. On ne passe à la suivante qu'une fois celle-ci tombée.",
            stages: ["100 pompes dans la journée", "200 abdos dans la journée",
                     "100 squats dans la journée", "10 tractions d'affilée",
                     "50 pompes d'affilée", "5 km sans marcher", "Bankai"],
            sessionsPerStage: [1, 1, 1, 1, 1, 1, 1],
            rhythm: "À ton rythme", equipment: "Barre de traction",
            darkColor: 0x1A1A1A, lightColor: 0xC0392B,
            unlock: .rank(.b), playable: false),

        Program(
            id: .minato, name: "Minato", family: "Vitesse",
            pitch: "L'Éclair Jaune de Konoha. Sprints courts, éducatifs de course, pliométrie horizontale. Deux séances par semaine, soixante-douze heures d'écart.",
            stages: ["Genin", "Chūnin", "Jōnin", "ANBU", "L'Éclair Jaune",
                     "Hiraishin", "Yondaime Hokage"],
            sessionsPerStage: [3, 3, 3, 3, 2, 2, 2],
            rhythm: "2 séances par semaine", equipment: "60 m de plat",
            darkColor: 0x2C4A8C, lightColor: 0xF5D547,
            unlock: .stat(.vitesse, 25), playable: false),

        Program(
            id: .levi, name: "Levi", family: "Gainage",
            pitch: "Puissance rapportée au poids de corps : gainage, tractions, suspensions, rotations. Séances courtes, intensité haute.",
            stages: ["Recrue", "Bataillon d'exploration", "Escouade d'élite",
                     "Caporal-chef", "Le plus fort de l'humanité"],
            sessionsPerStage: [5, 5, 5, 5, 4],
            rhythm: "4 séances par semaine", equipment: "Barre de traction",
            darkColor: 0x1C241E, lightColor: 0x4A5D4E,
            unlock: .stat(.force, 30), playable: false),

        Program(
            id: .luffy, name: "Luffy", family: "Souplesse",
            pitch: "Le seul personnage dont le pouvoir est l'élasticité. Mobilité articulaire, étirements tenus, ouverture de hanches et d'épaules. Dix minutes par jour.",
            stages: ["Gomu Gomu", "Gear 2", "Gear 3", "Gear 4", "Gear 5"],
            sessionsPerStage: [7, 7, 7, 7, 7],
            rhythm: "Tous les jours", equipment: "Aucun",
            darkColor: 0x7A1010, lightColor: 0xD62828,
            unlock: .rank(.d), playable: false),

        Program(
            id: .goku, name: "Goku", family: "Progression extrême",
            pitch: "Chaque transformation multiplie la charge de la précédente. Le Kaiō-ken ×4 est déjà un multiplicateur dans l'œuvre : il le devient ici.",
            stages: ["Base", "Kaiō-ken", "Kaiō-ken ×4", "Super Saiyan",
                     "Super Saiyan 2", "Super Saiyan 3", "Super Saiyan Blue", "Ultra Instinct"],
            sessionsPerStage: [5, 5, 5, 5, 5, 5, 5, 5],
            rhythm: "4 séances par semaine", equipment: "Sac lesté",
            darkColor: 0x12406B, lightColor: 0xFF6B00,
            unlock: .rank(.a), playable: false)
    ]

    static func program(_ id: ProgramID) -> Program {
        programs.first { $0.id == id } ?? programs[0]
    }

    /// Toutes les séances d'un programme, calibrées sur le palier choisi.
    static func sessions(for id: ProgramID, tier: Tier) -> [PlannedSession] {
        switch id {
        case .saitama: return saitamaSessions(tier: tier)
        case .naruto: return narutoSessions(tier: tier)
        default: return []
        }
    }

    static func session(for id: ProgramID, index: Int, tier: Tier) -> PlannedSession? {
        let all = sessions(for: id, tier: tier)
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

    // MARK: - Outils

    private static func scaled(_ value: Double, _ tier: Tier) -> Int {
        max(1, Int((value * tier.load).rounded()))
    }

    /// Des mètres ronds : personne ne court 1 847 m.
    private static func roundMeters(_ meters: Int) -> Int {
        meters >= 2000 ? Int((Double(meters) / 500).rounded()) * 500
                       : Int((Double(meters) / 100).rounded()) * 100
    }
}
