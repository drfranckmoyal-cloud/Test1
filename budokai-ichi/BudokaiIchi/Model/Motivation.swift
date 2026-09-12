import Foundation

/// Les textes, déclinés selon le ton. Le tirage du ton absurde est
/// déterministe : une phrase tirée au hasard changerait à chaque redessin.
enum Motivation {

    static func sessionLine(tone: MotivationTone, program: String, stage: String,
                            remaining: Int, streak: Int) -> String {
        let seed = remaining &* 131 &+ streak
        if tone == .absurd { return pick(absurd(stage: stage, remaining: remaining), seed: seed) }
        switch tone {
        case .cash:
            return remaining <= 1 ? "Dernière séance de l'étape. Tu ne vas pas t'arrêter là."
                                  : "Encore \(remaining) séances avant de franchir \(stage)."
        case .coach:
            return "Étape en cours : \(stage). Il reste \(remaining) séances, une à la fois."
        default:
            return "\(stage). Rien à précipiter : il reste \(remaining) séances."
        }
    }

    static func restLine(tone: MotivationTone, program: String) -> String {
        switch tone {
        case .cash: return "Jour de repos. C'est le programme qui le dit, pas toi."
        case .coach: return "Repos aujourd'hui. Le muscle se construit entre les séances, pas pendant."
        case .zen: return "Jour de repos. Laisse le corps faire son travail."
        case .absurd: return "Repos imposé. Tes muscles tiennent une réunion sans toi, n'y assiste pas."
        }
    }

    static func outcomeLine(tone: MotivationTone, stage: String?, streak: Int) -> String {
        if let stage = stage {
            switch tone {
            case .cash: return "\(stage) franchie. La suivante t'attend."
            case .coach: return "\(stage) franchie. C'est exactement comme ça qu'on progresse."
            case .zen: return "\(stage) franchie. Sans forcer, sans se presser."
            case .absurd: return pick(absurdStage(stage: stage), seed: streak &* 17)
            }
        }
        switch tone {
        case .cash: return "Séance pliée. \(streak) jours d'affilée."
        case .coach: return "Séance terminée. La régularité fait le reste."
        case .zen: return "C'est fait. Rien à ajouter."
        case .absurd: return pick(absurdSession(streak: streak), seed: streak &* 31)
        }
    }

    static func reminderBody(tone: MotivationTone, sessionLabel: String, slot: Int, seed: Int) -> String {
        if tone == .absurd { return pick(absurdReminders(label: sessionLabel, slot: slot), seed: seed) }
        switch tone {
        case .cash:
            return slot == 0 ? "\(sessionLabel). Maintenant, pas ce soir."
                 : slot == 1 ? "\(sessionLabel) t'attend toujours."
                             : "Dernier créneau : \(sessionLabel)."
        case .coach:
            return slot == 0 ? "Au programme aujourd'hui : \(sessionLabel)."
                 : slot == 1 ? "\(sessionLabel) — un bon moment pour s'y mettre."
                             : "Il reste la soirée pour \(sessionLabel)."
        default:
            return slot == 0 ? "\(sessionLabel), quand tu es prêt."
                 : slot == 1 ? "Une pause active : \(sessionLabel)."
                             : "Clôture la journée avec \(sessionLabel)."
        }
    }

    // MARK: - Tirage déterministe

    private static func pick(_ options: [String], seed: Int) -> String {
        guard !options.isEmpty else { return "" }
        var value = UInt64(bitPattern: Int64(seed &* 2_654_435_761))
        value = value &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return options[Int(value >> 33) % options.count]
    }

    private static func absurd(stage: String, remaining: Int) -> [String] {
        [
            "Plus que \(remaining) séances avant \(stage). Après, les portes automatiques s'ouvriront avant que tu arrives.",
            "\(remaining) séances et tu franchis \(stage). Un notaire cherche déjà ton adresse.",
            "Encore \(remaining). Ton banquier s'apprête à t'appeler spontanément « Maître ».",
            "\(remaining) séances. Ensuite tu ouvriras les bocaux de cornichons d'un simple regard.",
            "Plus que \(remaining) avant \(stage). Les moustiques changeront de trottoir en te voyant.",
            "\(remaining) séances et ton wifi doublera de vitesse. Ce n'est prouvé par personne.",
            "Encore \(remaining). Une compagnie aérienne va te surclasser sans aucune raison.",
            "\(remaining) séances avant \(stage). Les feux passeront au vert sur ton passage pendant 48 heures."
        ]
    }

    private static func absurdStage(stage: String) -> [String] {
        [
            "\(stage) franchie. Une statue de toi vient d'être commandée dans une petite commune.",
            "\(stage) franchie. La gravité a accepté de baisser de 4 % pour toi ce soir.",
            "\(stage) franchie. Ton reflet dans le miroir t'a fait un clin d'œil.",
            "\(stage) franchie. Un inconnu vient de t'ajouter à son testament.",
            "\(stage) franchie. Le wifi passe désormais à travers les murs porteurs chez toi.",
            "\(stage) franchie. Ton nom circule déjà dans les couloirs du pouvoir."
        ]
    }

    private static func absurdSession(streak: Int) -> [String] {
        [
            "Séance terminée. Ton canapé te regarde avec un respect entièrement nouveau.",
            "C'est fait. Les pigeons du quartier ont décidé de te suivre partout.",
            "Terminé. Un chef étoilé prépare ton dîner à cet instant, sans le savoir.",
            "Séance pliée. Ta photo de profil a spontanément pris trois ans de moins.",
            "Fini. \(streak) jours d'affilée : les escaliers du métro te présentent leurs excuses.",
            "Terminé. Les chaussettes de la machine à laver reviendront toutes par paires."
        ]
    }

    private static func absurdReminders(label: String, slot: Int) -> [String] {
        switch slot {
        case 0:
            return ["\(label). Maintenant, et la journée t'appartient.",
                    "\(label) avant le café. Le café le mérite. Toi, pas encore.",
                    "\(label) : le soleil s'est levé exprès pour ça."]
        case 1:
            return ["\(label) avant de repartir. Personne ne saura, sauf l'univers.",
                    "\(label) maintenant. L'après-midi n'osera plus rien contre toi.",
                    "\(label) et tu trouveras une place de parking pile devant. Deux fois."]
        default:
            return ["\(label) et tu dormiras comme un empereur romain.",
                    "\(label) avant minuit, sinon le calendrier s'en souviendra.",
                    "\(label) pour boucler. Le canapé attendra, il n'a rien d'autre à faire."]
        }
    }
}
