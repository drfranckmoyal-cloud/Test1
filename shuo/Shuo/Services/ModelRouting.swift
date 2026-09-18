import Foundation
import SwiftUI

/// Un modèle de langue utilisable comme couche d'exécution.
///
/// Le moteur pédagogique ne dépend d'aucun d'eux : ils sont interchangeables,
/// et le nom du modèle réellement actif reste affiché en permanence.
struct LanguageModel: Identifiable, Hashable {
    /// L'identifiant exact envoyé à l'API.
    let id: String
    /// Le nom montré dans le badge.
    let displayName: String
    /// Prix par million de jetons, en dollars.
    let inputPricePerMTok: Double
    let outputPricePerMTok: Double
    /// La couleur du badge : plus le modèle est lourd, plus elle est chaude.
    let complexity: Complexity

    enum Complexity: Int, Comparable {
        case light = 0
        case strong = 1

        static func < (lhs: Complexity, rhs: Complexity) -> Bool { lhs.rawValue < rhs.rawValue }

        var color: Color {
            switch self {
            case .light: return Color(red: 0.24, green: 0.45, blue: 0.33)
            case .strong: return Color(red: 0.72, green: 0.34, blue: 0.13)
            }
        }

        var label: String {
            switch self {
            case .light: return "léger"
            case .strong: return "fort"
            }
        }
    }

    /// Le modèle léger, par défaut : transitions, reformulations, explications
    /// déjà scriptées.
    static let light = LanguageModel(
        id: "claude-haiku-4-5",
        displayName: "Haiku 4.5",
        inputPricePerMTok: 1.0,
        outputPricePerMTok: 5.0,
        complexity: .light
    )

    /// Le modèle fort : intention ambiguë, explication complexe, conversation
    /// libre inattendue, diagnostic d'erreurs multiples, reprise après échec.
    static let strong = LanguageModel(
        id: "claude-opus-5",
        displayName: "Opus 5",
        inputPricePerMTok: 5.0,
        outputPricePerMTok: 25.0,
        complexity: .strong
    )

    static let all = [light, strong]

    /// Le coût d'un appel, en dollars.
    func cost(inputTokens: Int, outputTokens: Int) -> Double {
        Double(inputTokens) / 1_000_000 * inputPricePerMTok
            + Double(outputTokens) / 1_000_000 * outputPricePerMTok
    }
}

/// Ce qui a déclenché le choix du modèle fort.
enum RoutingTrigger: String, CaseIterable {
    case ambiguousIntent = "intention ambiguë"
    case complexExplanation = "explication complexe"
    case freeConversation = "conversation libre"
    case multiErrorDiagnosis = "erreurs multiples"
    case recoveryAfterFailure = "reprise après échec"
    case lowConfidence = "confiance faible"
}

/// Comment le modèle est choisi.
enum RoutingMode: String, CaseIterable, Identifiable {
    case automatic
    case forceLight
    case forceStrong

    var id: String { rawValue }

    var label: String {
        switch self {
        case .automatic: return "Auto"
        case .forceLight: return "Forcer léger"
        case .forceStrong: return "Forcer fort"
        }
    }
}

/// Le routeur. Il choisit le modèle avant chaque tour de parole.
///
/// La règle du dossier est claire : le léger par défaut, le fort quand c'est
/// nécessaire, et **le fort quand on hésite**. La qualité l'emporte sur le coût.
enum ModelRouter {

    /// Ce qu'on sait du tour qui vient, pour trancher.
    struct Context {
        var phaseKind: PhaseKind
        var helpLevel: HelpLevel = .none
        /// Confiance de la reconnaissance vocale, quand iOS la donne.
        var asrConfidence: Float?
        /// Nombre d'erreurs repérées dans le dernier tour.
        var errorCount: Int = 0
        /// Vrai après un échec sur ce même point.
        var recoveringFromFailure: Bool = false
        /// Vrai quand l'apprenant a dit quelque chose d'inattendu.
        var offScript: Bool = false
    }

    /// Choisit le modèle, et dit pourquoi.
    static func choose(_ context: Context, mode: RoutingMode) -> (model: LanguageModel, trigger: RoutingTrigger?) {
        switch mode {
        case .forceLight: return (.light, nil)
        case .forceStrong: return (.strong, nil)
        case .automatic: break
        }

        if context.phaseKind == .free || context.offScript {
            return (.strong, context.offScript ? .ambiguousIntent : .freeConversation)
        }
        if context.errorCount >= 2 {
            return (.strong, .multiErrorDiagnosis)
        }
        if context.recoveringFromFailure {
            return (.strong, .recoveryAfterFailure)
        }
        if context.helpLevel >= .strongHint {
            return (.strong, .complexExplanation)
        }
        // Reconnaissance vocale hésitante : on ne devine pas, on prend le fort.
        if let confidence = context.asrConfidence, confidence < 0.4 {
            return (.strong, .lowConfidence)
        }
        return (.light, nil)
    }
}

/// Un appel au modèle, tel qu'il apparaît dans le journal technique.
struct ModelCallLog: Identifiable, Hashable {
    let id = UUID()
    let at: Date
    let modelID: String
    let modelName: String
    let complexity: LanguageModel.Complexity
    let trigger: String?
    /// Latence de bout en bout, en secondes.
    let latency: TimeInterval
    let inputTokens: Int
    let outputTokens: Int
    let costUSD: Double
    let phase: String
    /// Vrai quand l'appel a échoué et qu'on est retombé sur le tuteur local.
    let failedOver: Bool

    static func == (lhs: ModelCallLog, rhs: ModelCallLog) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// La télémétrie : ce que la séance a coûté, en temps, en jetons et en euros.
///
/// Elle n'existe que pour être regardée. Aucune de ces valeurs ne sert à
/// couper quoi que ce soit — le dossier demande des alertes, pas un robinet.
@MainActor
final class Telemetry: ObservableObject {

    /// Cible du dossier : environ 1,25 €/heure, avec une fourchette souple.
    static let targetEURPerHour = 1.25
    static let softRange = (low: 1.0, high: 1.5)
    /// Taux de conversion dollar/euro, ajustable en mode développeur.
    /// Rangé dans les réglages : c'est un paramètre, pas un état apprenant.
    var usdPerEUR: Double {
        get {
            let stored = UserDefaults.standard.double(forKey: "shuo.usd.per.eur")
            return stored > 0.1 ? stored : 1.08
        }
        set { UserDefaults.standard.set(newValue, forKey: "shuo.usd.per.eur") }
    }

    @Published private(set) var calls: [ModelCallLog] = []
    @Published private(set) var activeModel: LanguageModel = .light
    @Published private(set) var lastTrigger: RoutingTrigger?
    /// Vrai quand le modèle vient de changer : l'interface le signale
    /// discrètement, puis l'oublie.
    @Published private(set) var modelJustSwitched = false
    /// Vrai quand le coût horaire de la séance sort de la fourchette souple.
    @Published private(set) var costAlert: String?

    /// Le journal de séance, en clair, exportable.
    @Published private(set) var sessionLog: [String] = []

    private var sessionStart = Date()

    func beginSession() {
        calls = []
        sessionLog = []
        costAlert = nil
        sessionStart = Date()
        note("Séance démarrée.")
    }

    /// Enregistre le modèle retenu pour le tour qui commence.
    func setActive(_ model: LanguageModel, trigger: RoutingTrigger?) {
        if model.id != activeModel.id {
            modelJustSwitched = true
            note("Modèle → \(model.displayName)\(trigger.map { " (\($0.rawValue))" } ?? "")")
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                self?.modelJustSwitched = false
            }
        }
        activeModel = model
        lastTrigger = trigger
    }

    func record(_ log: ModelCallLog) {
        calls.append(log)
        note(String(
            format: "%@ · %.2fs · %d→%d jetons · %.4f $%@",
            log.modelName, log.latency, log.inputTokens, log.outputTokens, log.costUSD,
            log.failedOver ? " · repli local" : ""
        ))
        checkCost()
    }

    func note(_ line: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        sessionLog.append("[\(formatter.string(from: Date()))] \(line)")
        if sessionLog.count > 500 { sessionLog.removeFirst(sessionLog.count - 500) }
    }

    // MARK: - Coût

    var sessionCostUSD: Double { calls.reduce(0) { $0 + $1.costUSD } }
    var sessionCostEUR: Double { sessionCostUSD / max(usdPerEUR, 0.1) }
    var sessionInputTokens: Int { calls.reduce(0) { $0 + $1.inputTokens } }
    var sessionOutputTokens: Int { calls.reduce(0) { $0 + $1.outputTokens } }

    var averageLatency: TimeInterval {
        guard !calls.isEmpty else { return 0 }
        return calls.reduce(0) { $0 + $1.latency } / Double(calls.count)
    }

    var elapsedHours: Double {
        max(Date().timeIntervalSince(sessionStart) / 3600, 1.0 / 3600)
    }

    var costPerHourEUR: Double { sessionCostEUR / elapsedHours }

    private func checkCost() {
        // On n'alerte pas sur les trente premières secondes : le coût horaire
        // extrapolé n'y veut rien dire.
        guard Date().timeIntervalSince(sessionStart) > 30 else { return }
        let rate = costPerHourEUR
        costAlert = rate > Self.softRange.high
            ? String(format: "%.2f €/h — au-dessus de la cible de %.2f €/h", rate, Self.targetEURPerHour)
            : nil
    }

    /// Le journal technique, prêt à être partagé.
    func exportLog() -> String {
        var lines = ["# Shuō — journal de séance", ""]
        lines.append(contentsOf: sessionLog)
        lines.append("")
        lines.append(String(format: "Coût séance : %.4f $ (%.3f €)", sessionCostUSD, sessionCostEUR))
        lines.append(String(format: "Coût horaire : %.2f €/h (cible %.2f)", costPerHourEUR, Self.targetEURPerHour))
        lines.append(String(format: "Latence moyenne : %.2f s", averageLatency))
        lines.append("Jetons : \(sessionInputTokens) entrée / \(sessionOutputTokens) sortie")
        return lines.joined(separator: "\n")
    }
}
