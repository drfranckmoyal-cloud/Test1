import SwiftUI

/// Les images d'un programme, versées dans le catalogue par
/// `tools/build_images.py`. Les noms sont fabriqués, pas écrits à la main :
/// un lot d'images remplacé se rebranche sans toucher au code.
extension Program {

    /// L'univers dont le programme est tiré. Sert à retrouver son logo.
    var universe: String {
        switch id {
        case .saitama: return "one_punch_man"
        case .goku: return "dragon_ball"
        case .rocklee, .minato, .naruto: return "naruto"
        case .kenshiro: return "hokuto_no_ken"
        case .ichigo: return "bleach"
        case .levi: return "attack_on_titan"
        case .luffy: return "one_piece"
        }
    }

    /// Le personnage à une étape donnée, comptée à partir de zéro.
    func stageImage(_ stage: Int) -> String {
        let clamped = min(max(stage, 0), stages.count - 1)
        return "stage_\(id.rawValue)_\(clamped + 1)"
    }

    /// L'image de présentation, celle qui porte la vignette du programme.
    /// Franck a désigné les plus parlantes ; les autres prennent la première.
    var heroStage: Int {
        switch id {
        case .saitama: return 6   // 007 · héros de classe C
        case .goku: return 4      // 013 · Super Saiyan 2
        case .minato: return 6    // 045 · Yondaime Hokage
        case .ichigo: return 3    // 035 · dix tractions d'affilée
        case .naruto: return 2    // 058 · mode ermite
        default: return 0
        }
    }

    /// Le décor de l'univers.
    var environmentImage: String { "env_\(id.rawValue)" }

    /// Le logo de l'univers.
    var logoImage: String { "logo_\(universe)" }
}
