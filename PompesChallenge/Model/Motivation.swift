import Foundation

/// Tous les textes de motivation, déclinés selon le ton choisi.
enum Motivation {

    /// Ligne affichée sur l'écran du jour. `unit` est l'exercice le plus en
    /// retard ; `remaining == 0` signifie que la journée est bouclée.
    static func daily(tone: MotivationTone, unit: String, remaining: Int, count: Int, dayIndex: Int) -> String {
        if remaining == 0 {
            switch tone {
            case .cash: return "Objectif plié. Jour \(dayIndex) dans la poche."
            case .coach: return "Journée validée. C'est exactement comme ça qu'on construit une habitude."
            case .zen: return "C'est fait. Rien à ajouter, la journée est complète."
            }
        }
        if count == 0 {
            switch tone {
            case .cash: return "Rien de fait pour l'instant. La première série coûte 90 secondes."
            case .coach: return "On démarre doucement : le plus dur est de commencer."
            case .zen: return "Commence par une seule série. Le reste suivra."
            }
        }
        if remaining <= 20 {
            switch tone {
            case .cash: return "Plus que \(remaining) \(unit). Tu ne vas pas t'arrêter maintenant."
            case .coach: return "Il reste \(remaining) \(unit) : une dernière série et c'est bouclé."
            case .zen: return "Encore \(remaining) \(unit). Prends ton temps, mais finis."
            }
        }
        switch tone {
        case .cash: return "Plus que \(remaining) \(unit). C'est 3 minutes de ta journée, pas plus."
        case .coach: return "\(count) de faites, \(remaining) \(unit) restantes. Coupe ça en deux séries."
        case .zen: return "\(count) derrière toi. Avance à ton rythme, il reste \(remaining) \(unit)."
        }
    }

    /// Corps de la notification d'un créneau. `shares` liste ce qu'il y a à
    /// faire maintenant : « 30 pompes, 6 tractions ».
    static func reminderBody(tone: MotivationTone, shares: String, slot: Int) -> String {
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
        case .zen:
            switch slot {
            case 0: return "Un moment pour toi : \(shares), tranquillement."
            case 1: return "Une pause active : \(shares) quand tu es prêt."
            default: return "Clôture la journée avec \(shares)."
            }
        }
    }

    /// Phrase de l'écran de célébration.
    static func celebration(tone: MotivationTone, dayIndex: Int, duration: Int, total: Int) -> String {
        let remainingDays = max(0, duration - dayIndex)
        if remainingDays == 0 {
            return "Défi terminé. \(total.grouped) répétitions en \(duration) jours."
        }
        if dayIndex * 2 == duration {
            return "Tu viens de passer la moitié du défi.\n\(total.grouped) répétitions depuis le jour 1."
        }
        switch tone {
        case .cash: return "Encore \(remainingDays) jours.\n\(total.grouped) répétitions au compteur."
        case .coach: return "\(remainingDays) jours avant la fin du défi.\nTotal : \(total.grouped) répétitions."
        case .zen: return "Un jour de plus, sans forcer.\n\(total.grouped) répétitions depuis le début."
        }
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
