import Foundation

func hms(_ seconds: Int) -> String {
    if seconds >= 60 && seconds % 60 == 0 { return "\(seconds / 60) min" }
    if seconds >= 60 { return "\(seconds / 60) min \(seconds % 60) s" }
    return "\(seconds) s"
}

func amount(_ goal: Goal) -> String {
    switch goal.unit {
    case .reps: return "\(goal.value) répétitions"
    case .seconds: return hms(goal.value)
    case .meters: return goal.value >= 1000
        ? String(format: "%.1f km", Double(goal.value) / 1000).replacingOccurrences(of: ".", with: ",")
        : "\(goal.value) m"
    }
}

var out = ""
func line(_ text: String = "") { out += text + "\n" }

let tier: Tier = .confirme

line("# Budokai Ichiban — les neuf programmes")
line()
line("Contenu sportif intégral, extrait du code de l'application le "
     + { let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR")
         f.dateFormat = "d MMMM yyyy"; return f.string(from: Date()) }() + ".")
line()
line("Palier **Confirmé** (le palier de référence : Novice applique ×0,7, Classe S ×1,3).")
line("Curseur d'intensité neutre. Les durées de repos sont indiquées quand elles ne sont pas nulles.")
line()

// ---- vue d'ensemble
line("## Vue d'ensemble")
line()
line("| Programme | Qualité | Étapes | Séances | Rythme | Repos entre séances | Matériel |")
line("|---|---|---|---|---|---|---|")
for program in Catalog.programs {
    let rest = program.restDays == 0 ? "aucun" : "\(program.restDays) jour"
    line("| \(program.name) | \(program.family) | \(program.stages.count) | \(program.totalSessions) | \(program.rhythm) | \(rest) | \(program.equipment) |")
}
line()

// ---- le détail
for program in Catalog.programs {
    let sessions = Catalog.sessions(for: program.id, tier: tier)
    let minutes = sessions.reduce(0) { $0 + $1.estimatedMinutes }
    let reps = sessions.reduce(0) { $0 + $1.totalReps }

    line()
    line("---")
    line()
    line("# \(program.name) — \(program.family)")
    line()
    line("> \(program.pitch)")
    line()
    line("**\(sessions.count) séances · \(program.stages.count) étapes · \(minutes / 60) h \(minutes % 60) min cumulées"
         + (reps > 0 ? " · \(reps) répétitions au total" : "") + "**")
    line()
    line("Rythme : \(program.rhythm). Matériel : \(program.equipment).")
    line()

    for (stageIndex, stageName) in program.stages.enumerated() {
        let first = program.firstSession(ofStage: stageIndex)
        let count = program.sessionsPerStage[stageIndex]
        line("## Étape \(stageIndex + 1) — \(stageName)")
        line()
        line("*\(count) séance\(count > 1 ? "s" : "")*")
        line()

        for session in sessions where session.index > first && session.index <= first + count {
            line("### \(session.title)")
            line()
            line("*\(session.estimatedMinutes) min estimées*")
            line()

            // regroupe les étapes identiques : « Pompes · 4 × 12 »
            var order: [String] = []
            var counts: [String: Int] = [:]
            var goals: [String: Goal] = [:]
            var details: [String: String] = [:]
            var rests: [String: Int] = [:]
            for step in session.steps {
                if counts[step.name] == nil {
                    order.append(step.name)
                    details[step.name] = step.detail
                }
                counts[step.name, default: 0] += 1
                goals[step.name] = step.goal
                rests[step.name] = step.restSeconds
            }
            for name in order {
                let n = counts[name] ?? 1
                let goal = goals[name] ?? Goal(unit: .reps, value: 0)
                var text = "- **\(name)** — "
                text += n > 1 ? "\(n) × \(amount(goal))" : amount(goal)
                if let rest = rests[name], rest > 0 { text += ", repos \(hms(rest))" }
                if let detail = details[name], !detail.isEmpty, n == 1 { text += " *(\(detail))*" }
                line(text)
            }
            line()
        }
    }
}

let path = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "programmes.md"
try! out.write(toFile: path, atomically: true, encoding: .utf8)
print("écrit : \(path) — \(out.count) caractères")
