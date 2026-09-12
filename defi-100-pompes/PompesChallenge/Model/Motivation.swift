import Foundation

/// Tous les textes de motivation, déclinés selon le ton choisi.
///
/// Le ton « Absurde » puise dans de longues listes de promesses délirantes.
/// Le tirage est *déterministe* : il dépend du jour et du compteur, jamais du
/// hasard — sinon la phrase changerait à chaque rafraîchissement de l'écran.
enum Motivation {

    // MARK: - Écran du jour

    /// `unit` est l'exercice le plus en retard ; `remaining == 0` signifie que
    /// la journée est bouclée.
    static func daily(tone: MotivationTone, unit: String, remaining: Int, count: Int, dayIndex: Int) -> String {
        let seed = dayIndex &* 131 &+ count

        if tone == .absurd {
            if remaining == 0 { return pick(absurdDone(dayIndex: dayIndex), seed: seed) }
            if count == 0 { return pick(absurdStart(unit: unit), seed: seed) }
            return pick(absurdGoing(remaining: remaining, unit: unit), seed: seed)
        }

        if remaining == 0 {
            switch tone {
            case .cash: return "Objectif plié. Jour \(dayIndex) dans la poche."
            case .coach: return "Journée validée. C'est exactement comme ça qu'on construit une habitude."
            default: return "C'est fait. Rien à ajouter, la journée est complète."
            }
        }
        if count == 0 {
            switch tone {
            case .cash: return "Rien de fait pour l'instant. La première série coûte 90 secondes."
            case .coach: return "On démarre doucement : le plus dur est de commencer."
            default: return "Commence par une seule série. Le reste suivra."
            }
        }
        if remaining <= 20 {
            switch tone {
            case .cash: return "Plus que \(remaining) \(unit). Tu ne vas pas t'arrêter maintenant."
            case .coach: return "Il reste \(remaining) \(unit) : une dernière série et c'est bouclé."
            default: return "Encore \(remaining) \(unit). Prends ton temps, mais finis."
            }
        }
        switch tone {
        case .cash: return "Plus que \(remaining) \(unit). C'est 3 minutes de ta journée, pas plus."
        case .coach: return "\(count) de faites, \(remaining) \(unit) restantes. Coupe ça en deux séries."
        default: return "\(count) derrière toi. Avance à ton rythme, il reste \(remaining) \(unit)."
        }
    }

    // MARK: - Notifications

    /// `shares` liste ce qu'il y a à faire maintenant : « 30 pompes, 6 tractions ».
    /// `seed` change d'un jour à l'autre pour que le texte ne se répète pas.
    static func reminderBody(tone: MotivationTone, shares: String, slot: Int, seed: Int) -> String {
        if tone == .absurd {
            return pick(absurdReminders(shares: shares, slot: slot), seed: seed)
        }
        switch tone {
        case .cash:
            switch slot {
            case 0: return "\(shares), tout de suite. La journée commence bien ou pas du tout."
            case 1: return "\(shares) avant de repartir. Pas d'excuse, tu es debout."
            default: return "Dernier créneau : \(shares) et la journée est validée."
            }
        case .coach:
            switch slot {
            case 0: return "Première série du jour : \(shares) pour lancer la machine."
            case 1: return "Deuxième créneau : \(shares), tu es à mi-parcours."
            default: return "Dernière série : \(shares) pour valider ta journée."
            }
        default:
            switch slot {
            case 0: return "Un moment pour toi : \(shares), tranquillement."
            case 1: return "Une pause active : \(shares) quand tu es prêt."
            default: return "Clôture la journée avec \(shares)."
            }
        }
    }

    // MARK: - Célébration

    static func celebration(tone: MotivationTone, dayIndex: Int, duration: Int, total: Int) -> String {
        let remainingDays = max(0, duration - dayIndex)

        if tone == .absurd {
            if remainingDays == 0 {
                return "Défi terminé. \(total.grouped) répétitions.\nLe monde te doit officiellement quelque chose."
            }
            return pick(absurdCelebrations(dayIndex: dayIndex, remainingDays: remainingDays, total: total),
                        seed: dayIndex &* 17)
        }

        if remainingDays == 0 {
            return "Défi terminé. \(total.grouped) répétitions en \(duration) jours."
        }
        if dayIndex * 2 == duration {
            return "Tu viens de passer la moitié du défi.\n\(total.grouped) répétitions depuis le jour 1."
        }
        switch tone {
        case .cash: return "Encore \(remainingDays) jours.\n\(total.grouped) répétitions au compteur."
        case .coach: return "\(remainingDays) jours avant la fin du défi.\nTotal : \(total.grouped) répétitions."
        default: return "Un jour de plus, sans forcer.\n\(total.grouped) répétitions depuis le début."
        }
    }

    // MARK: - Tirage déterministe

    /// Même graine, même phrase : l'écran peut se redessiner autant qu'il veut.
    private static func pick(_ options: [String], seed: Int) -> String {
        guard !options.isEmpty else { return "" }
        var value = UInt64(bitPattern: Int64(seed &* 2_654_435_761))
        value = value &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return options[Int(value >> 33) % options.count]
    }

    // MARK: - Ton absurde

    private static func absurdStart(unit: String) -> [String] {
        [
            "Zéro \(unit) au compteur. Tous les milliardaires ont commencé exactement comme ça, un mardi.",
            "Rien de fait. Pourtant, quelque part, une voiture de sport attend que tu signes.",
            "Toujours à zéro. Ton double dans l'univers parallèle en a déjà fait 200 et il est insupportable.",
            "Zéro. Le sol t'attend. Il a même passé l'aspirateur.",
            "Rien encore. Un jury de prix international a mis ton dossier en attente, il s'impatiente.",
            "Zéro \(unit). Ton lit t'a menti. Il ne t'aime pas vraiment.",
            "Pas commencé. Le tapis commence à se sentir humilié.",
            "Toujours rien. Ton chat te juge. Et il a raison.",
            "Zéro. À la première série, la météo passe au grand soleil sur toute la région.",
            "Rien de fait. Tes ancêtres te regardent depuis un nuage, légèrement déçus.",
            "Compteur à zéro. Trois personnes très importantes attendent ta première pompe pour changer d'avis sur toi.",
            "Zéro \(unit). L'humanité retient son souffle. Enfin, une partie de l'humanité."
        ]
    }

    private static func absurdGoing(remaining: Int, unit: String) -> [String] {
        [
            "Plus que \(remaining) \(unit) et tu deviens officiellement milliardaire. Enfin, presque.",
            "Encore \(remaining) \(unit). Après ça, on t'attend à la maison avec le meilleur plat du monde.",
            "\(remaining) \(unit) et les portes automatiques s'ouvriront avant même que tu arrives.",
            "Il reste \(remaining) \(unit). Une compagnie aérienne va te surclasser sans aucune raison.",
            "\(remaining) \(unit) avant que ton banquier ne t'appelle spontanément « Maître ».",
            "Encore \(remaining). Les feux passeront au vert sur ton passage pendant 48 heures.",
            "\(remaining) \(unit) et tu récupères enfin la caution d'appartement de 2009.",
            "Plus que \(remaining). À la fin, un inconnu te proposera un poste de PDG dans l'ascenseur.",
            "\(remaining) \(unit) restantes. Ton pantalon préféré vient de se retailler tout seul.",
            "Encore \(remaining) \(unit) et la file de la boulangerie s'écartera devant toi comme la mer Rouge.",
            "\(remaining) \(unit). Après ça, tu comprendras enfin les règles du cricket.",
            "Il reste \(remaining) \(unit). Un notaire cherche activement ton adresse pour un héritage.",
            "Plus que \(remaining) \(unit) et tu ouvriras les bocaux de cornichons d'un simple regard.",
            "\(remaining) restantes. Le voisin du dessus va enfin arrêter de déplacer ses meubles la nuit.",
            "Encore \(remaining) \(unit) : ton wifi va doubler de vitesse. Ce n'est prouvé par personne.",
            "\(remaining) \(unit) et les moustiques changeront de trottoir en te voyant.",
            "Il te reste \(remaining) \(unit) avant que la gravité ne t'accorde une remise de 12 %.",
            "\(remaining) \(unit) et ton nom entre dans une légende urbaine du 15e arrondissement.",
            "Plus que \(remaining). Ensuite, les serveurs t'apporteront le pain sans que tu demandes.",
            "\(remaining) \(unit) et tu gagnes le droit de dire « à mon époque » sans être ridicule.",
            "Encore \(remaining) \(unit). Ton ostéopathe s'apprête à fermer boutique par manque de travail.",
            "\(remaining) \(unit) restantes avant que ton téléphone ne tienne trois jours sur une charge.",
            "Il reste \(remaining) \(unit). Une chorale répète en ce moment même une chanson à ta gloire.",
            "\(remaining) \(unit) et les escaliers du métro te présenteront leurs excuses."
        ]
    }

    private static func absurdDone(dayIndex: Int) -> [String] {
        [
            "Jour \(dayIndex) terminé. Quelque part, un parfait inconnu vient de t'ajouter à son testament.",
            "C'est fait. Ton reflet dans le miroir t'a fait un clin d'œil.",
            "Terminé. Les pigeons du quartier ont décidé de te suivre partout.",
            "Journée bouclée. Ton banquier vient d'appeler juste pour te féliciter.",
            "Fini. Ton canapé te regarde avec un respect entièrement nouveau.",
            "Objectif atteint. La gravité a accepté de baisser de 4 % pour toi ce soir.",
            "C'est plié. Trois inconnus vont te tenir la porte demain sans raison.",
            "Terminé. Le wifi passe désormais à travers les murs porteurs chez toi.",
            "Journée validée. Un chef étoilé prépare ton dîner à cet instant, sans le savoir.",
            "Fini. Ton nom vient d'apparaître dans un livre d'histoire, page 412, note de bas de page.",
            "C'est bon. Ta photo de profil a spontanément pris trois ans de moins.",
            "Terminé. Le soleil s'est levé une deuxième fois, uniquement par politesse.",
            "Journée pliée. Ton frigo s'est rempli tout seul de choses parfaitement saines.",
            "Objectif atteint. Une plaque commémorative est en cours de gravure quelque part.",
            "Fini. Les chaussettes de la machine à laver reviendront toutes par paires."
        ]
    }

    private static func absurdReminders(shares: String, slot: Int) -> [String] {
        switch slot {
        case 0:
            return [
                "\(shares) maintenant, et la journée t'appartient. Les autres ne le savent pas encore.",
                "\(shares) avant le café. Le café le mérite. Toi, pas encore.",
                "\(shares) tout de suite : le soleil s'est levé exprès pour ça.",
                "\(shares) et la matinée n'osera plus rien tenter contre toi.",
                "\(shares) au réveil. Les gens qui réussissent font ça. Ils l'ont dit dans un livre.",
                "\(shares) maintenant et tous les distributeurs te rendront la monnaie en double."
            ]
        case 1:
            return [
                "\(shares) avant de repartir. Ton déjeuner sera 40 % plus savoureux. Étude jamais publiée.",
                "\(shares) maintenant. L'après-midi n'osera plus rien contre toi.",
                "\(shares) entre deux rendez-vous. Personne ne saura, sauf l'univers.",
                "\(shares) et tu trouveras une place de parking pile devant. Deux fois.",
                "\(shares) à midi : c'est scientifiquement l'heure où les légendes se forment.",
                "\(shares) et ton café de l'après-midi aura le goût du succès."
            ]
        default:
            return [
                "Dernier créneau : \(shares) et tu dormiras comme un empereur romain.",
                "\(shares) et la journée est validée. Ton oreiller t'applaudira debout.",
                "\(shares) avant minuit, sinon le calendrier s'en souviendra très longtemps.",
                "\(shares) maintenant et tu te réveilleras demain avec une idée à un million.",
                "\(shares) pour boucler. Le canapé attendra, il n'a rien d'autre à faire.",
                "\(shares) et la nuit t'appartient. Enfin, les huit heures habituelles, mais en mieux."
            ]
        }
    }

    private static func absurdCelebrations(dayIndex: Int, remainingDays: Int, total: Int) -> [String] {
        [
            "Jour \(dayIndex) validé.\nUne statue de toi vient d'être commandée dans une petite commune.",
            "\(total.grouped) répétitions au total.\nUn fonds d'investissement veut te rencontrer.",
            "Encore \(remainingDays) jours.\nLes lois de la physique commencent à négocier avec toi.",
            "Jour \(dayIndex) dans la poche.\nTon nom circule déjà dans les couloirs du pouvoir.",
            "\(total.grouped) répétitions.\nDeux inconnus ont pleuré de fierté sans savoir pourquoi.",
            "Plus que \(remainingDays) jours.\nTa légende s'écrit, et l'auteur a du mal à suivre.",
            "Jour \(dayIndex) terminé.\nLe monde tourne 0,3 % plus vite depuis ta dernière série.",
            "\(total.grouped) répétitions au compteur.\nUn documentaire est en préparation. Sans budget, mais quand même.",
            "Encore \(remainingDays) jours.\nLes miroirs de la ville se disputent ton reflet.",
            "Jour \(dayIndex) validé.\nQuelque part, quelqu'un a décidé de t'imiter. Il n'y arrivera pas."
        ]
    }
}

extension Int {
    /// 1563 -> "1 563"
    var grouped: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "\u{00A0}"
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
