import Foundation

/// Le tuteur distant : un modèle de langue qui exécute la conversation.
///
/// Il ne décide ni du programme ni des statuts. Il parle, il corrige, et il
/// *propose* des notes que `MasteryEngine` accepte ou non. Le contexte envoyé
/// est volontairement court : le résumé de l'apprenant, la recette de la phase,
/// et les derniers tours — jamais tout l'historique.
struct AnthropicTutorBrain: TutorBrain {

    let model: LanguageModel
    let apiKey: String
    /// Repli local quand l'appel échoue : la séance ne s'arrête pas pour ça.
    let fallback = ScriptedTutorBrain()

    var displayName: String { model.displayName }

    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let apiVersion = "2023-06-01"

    /// Ce que l'appel a coûté, rempli après coup pour la télémétrie.
    final class Usage {
        var inputTokens = 0
        var outputTokens = 0
        var failedOver = false
    }

    func respond(to context: TurnContext) async throws -> TutorTurn {
        try await respond(to: context, usage: Usage())
    }

    /// Même chose, mais en rendant compte des jetons consommés.
    func respond(to context: TurnContext, usage: Usage) async throws -> TutorTurn {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(apiVersion, forHTTPHeaderField: "anthropic-version")
        // Une séance orale n'attend pas : au-delà, on repasse en local.
        request.timeoutInterval = 12

        request.httpBody = try JSONSerialization.data(withJSONObject: body(for: context))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            usage.failedOver = true
            return try await fallback.respond(to: context)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            usage.failedOver = true
            return try await fallback.respond(to: context)
        }

        if let tokens = json["usage"] as? [String: Any] {
            usage.inputTokens = tokens["input_tokens"] as? Int ?? 0
            usage.outputTokens = tokens["output_tokens"] as? Int ?? 0
        }

        // Un refus poli du modèle ne doit pas laisser l'apprenant en plan.
        if let stop = json["stop_reason"] as? String, stop == "refusal" {
            usage.failedOver = true
            return try await fallback.respond(to: context)
        }

        guard let turn = parse(json) else {
            usage.failedOver = true
            return try await fallback.respond(to: context)
        }
        return turn
    }

    // MARK: - Requête

    private func body(for context: TurnContext) -> [String: Any] {
        var payload: [String: Any] = [
            "model": model.id,
            "max_tokens": 1024,
            "system": systemPrompt(for: context),
            "messages": messages(for: context),
            "tools": [toolDefinition],
            "tool_choice": ["type": "tool", "name": Self.toolName],
        ]
        // L'effort n'existe que sur le modèle fort ; un tour de parole n'a pas
        // besoin d'aller au-delà du minimum, c'est de la latence en moins.
        if model.complexity == .strong {
            payload["output_config"] = ["effort": "low"]
        }
        return payload
    }

    private static let toolName = "repondre"

    /// Le tuteur répond par un appel d'outil : c'est ce qui garantit une forme
    /// exploitable plutôt qu'un texte à découper.
    ///
    /// Le schéma est monté morceau par morceau, en types explicites : un seul
    /// littéral imbriqué de cette taille est pénible à compiler et illisible à
    /// relire.
    private var toolDefinition: [String: Any] {
        let mandarin: [String: Any] = [
            "type": "string",
            "description": "Ce que tu dis en mandarin, prononcé à voix haute. Vide si tu ne dis rien en chinois.",
        ]
        let francais: [String: Any] = [
            "type": "string",
            "description": "Ce que tu dis en français : consigne, explication brève, correction.",
        ]
        let phaseTerminee: [String: Any] = [
            "type": "boolean",
            "description": "Vrai quand l'objectif de cette phase est atteint.",
        ]
        let motifErreur: [String: Any] = [
            "type": "string",
            "description": "Nom court et réutilisable de l'erreur commise, ou chaîne vide.",
        ]

        let noteProperties: [String: Any] = [
            "item": ["type": "string", "description": "Le mot concerné, en hanzi."] as [String: Any],
            "dimension": [
                "type": "string",
                "enum": Dimension.allCases.map(\.rawValue),
            ] as [String: Any],
            "score": ["type": "number", "description": "De 0 à 1."] as [String: Any],
        ]
        let noteSchema: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": noteProperties,
            "required": ["item", "dimension", "score"],
        ]
        let notes: [String: Any] = [
            "type": "array",
            "description": "Observations sur les mots travaillés. Tableau vide si rien à noter.",
            "items": noteSchema,
        ]

        let properties: [String: Any] = [
            "mandarin": mandarin,
            "francais": francais,
            "phase_terminee": phaseTerminee,
            "motif_erreur": motifErreur,
            "notes": notes,
        ]
        let schema: [String: Any] = [
            "type": "object",
            "additionalProperties": false,
            "properties": properties,
            "required": ["mandarin", "francais", "phase_terminee", "motif_erreur", "notes"],
        ]
        return [
            "name": Self.toolName,
            "description": "Répondre à l'apprenant et proposer des notes d'observation.",
            "strict": true,
            "input_schema": schema,
        ]
    }

    private func messages(for context: TurnContext) -> [[String: Any]] {
        var messages: [[String: Any]] = []
        for turn in context.recentTurns.suffix(6) {
            messages.append([
                "role": turn.isTutor ? "assistant" : "user",
                "content": turn.text,
            ])
        }
        // Le dernier message décrit la situation exacte du tour à jouer.
        messages.append(["role": "user", "content": situation(for: context)])
        return messages
    }

    private func situation(for context: TurnContext) -> String {
        var lines: [String] = []
        lines.append("PHASE : \(context.phase.kind.label).")
        if let text = context.phase.text { lines.append("CONSIGNE : \(text)") }
        if let grammar = context.grammarFocus { lines.append("POINT DE LANGUE : \(grammar)") }
        if let sound = context.pronunciationFocus { lines.append("POINT DE SON : \(sound)") }

        if !context.items.isEmpty {
            lines.append("MOTS EN JEU :")
            for item in context.items {
                lines.append("- \(item.hanzi) (\(item.pinyin)) : \(item.fr) — ex. \(item.exampleZh)")
            }
        }
        if !context.itemSummaries.isEmpty {
            lines.append("ÉTAT DE CES MOTS : " + context.itemSummaries.joined(separator: " ; "))
        }
        if !context.profileNotes.isEmpty {
            lines.append("POINTS FAIBLES CONNUS : " + context.profileNotes.joined(separator: " ; "))
        }
        if let dialogue = context.phase.dialogue {
            lines.append("DIALOGUE D'APPUI (inspiration, pas script) : " + dialogue.zh.joined(separator: " / "))
        }
        if let step = context.helpStep {
            lines.append("AIDE DEMANDÉE : \(step.instruction)")
        }
        if let said = context.learnerSaid {
            lines.append("L'APPRENANT VIENT DE DIRE : « \(said) »")
        } else {
            lines.append("L'apprenant n'a encore rien dit sur cette phase : ouvre-la.")
        }
        return lines.joined(separator: "\n")
    }

    /// Les règles pédagogiques, telles que le dossier les fixe. Le modèle les
    /// exécute ; il ne les renégocie pas.
    private func systemPrompt(for context: TurnContext) -> String {
        """
        Tu es \(context.tutor.hanzi) (\(context.tutor.pinyin)), tuteur de mandarin dans Shuō.
        Manière : \(context.tutor.manner)

        L'apprenant est francophone, débutant, niveau HSK 1. L'objectif est oral :
        écouter, parler, prononcer. Les tons comptent plus que tout le reste.

        RÈGLES, dans l'ordre :
        1. Tu laisses l'apprenant finir sa phrase. Tu corriges après, brièvement et
           globalement. Tu ne l'interromps pas au milieu d'un mot.
        2. Priorité de correction : ton, puis intelligibilité, puis grammaire
           importante, puis syntaxe et vocabulaire si c'est utile.
        3. Tu ne sors jamais du vocabulaire HSK 1 en mandarin, sauf pour répéter un
           mot que l'apprenant a lui-même utilisé.
        4. Tu ne donnes jamais la solution avant d'y être invité. « aide » déclenche
           une aide graduée, « réponse » donne la solution.
        5. Tu es bref. Deux phrases en français, maximum. Le temps de parole est à
           l'apprenant.
        6. Tu ne décides d'aucun statut de maîtrise. Tu proposes des notes entre 0 et
           1 sur ce que tu as réellement entendu. Si tu n'as pas entendu la
           prononciation, tu ne notes pas la prononciation.
        7. Un mot compris mais mal prononcé n'est pas acquis. Note-le tel quel.
        8. Le français reste disponible comme filet. Tu y reviens sans reproche si
           l'apprenant décroche.

        Réponds toujours en appelant l'outil \(Self.toolName).
        """
    }

    // MARK: - Réponse

    private func parse(_ json: [String: Any]) -> TutorTurn? {
        guard let content = json["content"] as? [[String: Any]] else { return nil }
        guard let block = content.first(where: { $0["type"] as? String == "tool_use" }),
              let input = block["input"] as? [String: Any] else { return nil }

        let mandarin = input["mandarin"] as? String ?? ""
        let french = input["francais"] as? String ?? ""
        let complete = input["phase_terminee"] as? Bool ?? false
        let rawPattern = input["motif_erreur"] as? String ?? ""

        var evidence: [TutorTurn.ProposedEvidence] = []
        if let notes = input["notes"] as? [[String: Any]] {
            for note in notes {
                guard let itemID = note["item"] as? String,
                      let raw = note["dimension"] as? String,
                      let dimension = Dimension(rawValue: raw) else { continue }
                let score = (note["score"] as? Double) ?? (note["score"] as? NSNumber)?.doubleValue ?? 0
                evidence.append(.init(itemID: itemID, dimension: dimension, score: min(max(score, 0), 1)))
            }
        }

        return TutorTurn(
            mandarin: mandarin,
            french: french,
            evidence: evidence,
            phaseComplete: complete,
            errorPattern: rawPattern.isEmpty ? nil : rawPattern
        )
    }
}
