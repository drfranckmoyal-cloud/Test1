import Foundation

/// Tous les textes de motivation, déclinés selon le ton choisi.
enum Motivation {

    /// Ligne affichée sur l'écran du jour.
    static func daily(tone: MotivationTone, remaining: Int, count: Int, goal: Int, dayIndex: Int, duration: Int) -> String {
        if remaining == 0 {
            switch tone {
            case .cash: return "Objectif plié. Jour \(dayIndex) dans la poche."
            case .coach: return "Journée validée. C'est exactement comme ça qu'on construit une habitude."
            case .zen: return "C'est fait. Rien à ajouter, la journée est complète."
            }
        }
        if count == 0 {
            switch tone {
            case .cash: return "Zéro pompe pour l'instant. La première série coûte 90 secondes."
            case .coach: return "On démarre par 20 : le plus dur est de se mettre au sol."
            case .zen: return "Commence par une seule série. Le reste suivra."
            }
        }
        if remaining <= 20 {
            switch tone {
            case .cash: return "Plus que \(remaining). Tu ne vas pas t'arrêter maintenant."
            case .coach: return "Il reste \(remaining) pompes : une dernière série et c'est bouclé."
            case .zen: return "Encore \(remaining). Prends ton temps, mais finis."
            }
        }
        switch tone {
        case .cash: return "Plus que \(remaining). C'est 3 minutes de ta journée, pas plus."
        case .coach: return "\(count) de faites, \(remaining) restantes. Coupe ça en deux séries."
        case .zen: return "\(count) derrière toi. Avance à ton rythme, il reste \(remaining)."
        }
    }

    /// Corps de la notification d'un créneau.
    static func reminderBody(tone: MotivationTone, share: Int, slot: Int, goal: Int) -> String {
        switch tone {
        case .cash:
            switch slot {
            case 0: return "\(share) pompes, tout de suite. La journée commence bien ou pas du tout."
            case 1: return "\(share) pompes avant de repartir. Pas d'excuse, tu es debout."
            default: return "Dernier créneau : \(share) pompes et les \(goal) sont bouclées."
            }
        case .coach:
            switch slot {
            case 0: return "Première série du jour : \(share) pompes pour lancer la machine."
            case 1: return "Deuxième créneau : \(share) pompes, tu es à mi-parcours."
            default: return "Dernière série : \(share) pompes pour valider ta journée."
            }
        case .zen:
            switch slot {
            case 0: return "Un moment pour toi : \(share) pompes, tranquillement."
            case 1: return "Une pause active : \(share) pompes quand tu es prêt."
            default: return "Clôture la journée avec \(share) pompes."
            }
        }
    }

    /// Phrase de l'écran de célébration.
    static func celebration(tone: MotivationTone, dayIndex: Int, duration: Int, total: Int) -> String {
        let remainingDays = max(0, duration - dayIndex)
        if remainingDays == 0 {
            return "Défi terminé. \(total.formattedPushups) pompes en \(duration) jours."
        }
        if dayIndex * 2 == duration {
            return "Tu viens de passer la moitié du défi.\n\(total.formattedPushups) pompes depuis le jour 1."
        }
        switch tone {
        case .cash: return "Encore \(remainingDays) jours.\n\(total.formattedPushups) pompes au compteur."
        case .coach: return "\(remainingDays) jours avant la fin du défi.\nTotal : \(total.formattedPushups) pompes."
        case .zen: return "Un jour de plus, sans forcer.\n\(total.formattedPushups) pompes depuis le début."
        }
    }
}

extension Int {
    /// 1563 -> "1 563"
    var formattedPushups: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "\u{00A0}"
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
