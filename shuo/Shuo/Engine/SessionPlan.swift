import Foundation

/// Ce qu'une phase de séance demande de faire.
enum PhaseKind: String, Codable, Hashable {
    /// La micro-remédiation d'une erreur qui revient. Une minute, pas plus.
    case remediation
    /// L'annonce d'ouverture : mots du jour, point de langue, point de son.
    case opening
    /// Le rappel initial, puisé dans tout l'historique.
    case recall
    /// Une étape de prononciation P01…P08.
    case bootcamp
    /// Un mot nouveau et son cycle complet.
    case newItem
    /// Réemploi guidé.
    case guided
    /// Réemploi semi-guidé, sans modèle.
    case semiGuided
    /// Conversation libre, 1 à 3 minutes.
    case free
    /// Écoute d'un dialogue, à une vitesse donnée.
    case listening
    /// Bilan de module ou intégration : on vérifie, on n'ajoute rien.
    case checkpoint
    /// Le récapitulatif. Aucun contenu nouveau (A17).
    case recap

    var label: String {
        switch self {
        case .remediation: return "Reprise"
        case .opening: return "Aujourd'hui"
        case .recall: return "Rappel"
        case .bootcamp: return "Prononciation"
        case .newItem: return "Nouveau mot"
        case .guided: return "Emploi guidé"
        case .semiGuided: return "Emploi semi-guidé"
        case .free: return "Conversation"
        case .listening: return "Écoute"
        case .checkpoint: return "Bilan"
        case .recap: return "Récapitulatif"
        }
    }

    /// Les phases où le tuteur corrige vite et fort plutôt qu'en fin de tour.
    var isDrill: Bool { self == .bootcamp || self == .recall }
}

/// Une phase de la séance, avec ce qu'il faut pour la jouer.
struct SessionPhase: Identifiable, Hashable {
    let id = UUID()
    let kind: PhaseKind
    /// La durée prévue. Indicative : le tuteur attend que l'apprenant finisse.
    var seconds: Int
    /// Les mots concernés. Un seul pour `newItem`, plusieurs pour `recall`.
    var itemIDs: [String] = []
    /// L'entrée du programme d'où vient la phase.
    var entryID: String?
    /// La consigne ou l'annonce, telle que le programme l'écrit.
    var text: String?
    var dialogue: Dialogue?
    /// « slow », « normal » ou « fast_native ».
    var listeningSpeed: String?
    /// Les motifs d'erreur repris en début de séance.
    var patterns: [String] = []
    /// Le point de langue et le point de son travaillés.
    var grammarFocus: String?
    var pronunciationFocus: String?
    /// Où se trouve le curseur du programme une fois cette phase jouée.
    /// Nul pour les phases qui ne font pas avancer le programme.
    var cursorAfterPhase: CurriculumCursor?

    static func == (lhs: SessionPhase, rhs: SessionPhase) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// La recette de la séance : des phases, dans l'ordre, et ce qu'elles coûtent
/// au programme.
struct SessionPlan: Identifiable {
    let sessionID: UUID
    var id: UUID { sessionID }
    let mode: SessionMode
    let durationMinutes: Int
    let tutorID: String
    var phases: [SessionPhase]
    /// Le curseur du programme au moment où la séance a été composée.
    let cursorBefore: CurriculumCursor
    /// Le curseur du programme une fois la séance terminée.
    var cursorAfter: CurriculumCursor
    /// Les motifs d'erreur repris, à retirer de la file une fois la séance finie.
    var remediationsHandled: [String]

    /// Les mots introduits aujourd'hui. Plafonné à trois par construction.
    var newItemIDs: [String] {
        phases.filter { $0.kind == .newItem }.flatMap(\.itemIDs)
    }

    /// Les mots revus, sans les nouveaux.
    var reviewItemIDs: [String] {
        let new = Set(newItemIDs)
        return phases
            .filter { $0.kind == .recall || $0.kind == .checkpoint }
            .flatMap(\.itemIDs)
            .filter { !new.contains($0) }
    }

    var totalSeconds: Int { phases.reduce(0) { $0 + $1.seconds } }

    /// L'entrée du programme que la séance travaille, s'il y en a une.
    var primaryEntryID: String? {
        phases.first { $0.kind == .newItem || $0.kind == .bootcamp || $0.kind == .checkpoint }?.entryID
    }
}
