import Foundation
import SwiftUI

/// Un tuteur : un nom chinois, une voix stable, un visage reconnaissable.
///
/// La pédagogie ne change pas d'un tuteur à l'autre — c'est le même moteur.
/// Ce qui change est la voix et le ton, pour que les séances ne se
/// ressemblent pas toutes.
struct Tutor: Identifiable, Hashable {
    let id: String
    let hanzi: String
    let pinyin: String
    /// Une phrase qui dit comment ce tuteur parle, passée au modèle.
    let manner: String
    /// L'identifiant exact d'une voix iOS, quand l'appareil l'a installée.
    let preferredVoiceIdentifier: String?
    /// Le débit de parole, entre 0 et 1. Un tuteur parle un peu plus vite
    /// qu'un autre, et c'est tout.
    let speechRate: Float
    let accent: Color

    static let all: [Tutor] = [
        Tutor(
            id: "lin",
            hanzi: "林老师",
            pinyin: "Lín lǎoshī",
            manner: "Calme, patient, phrases courtes. Laisse un silence après chaque question.",
            preferredVoiceIdentifier: "com.apple.voice.compact.zh-CN.Tingting",
            speechRate: 0.42,
            accent: Color(red: 0.75, green: 0.22, blue: 0.17)
        ),
        Tutor(
            id: "chen",
            hanzi: "陈老师",
            pinyin: "Chén lǎoshī",
            manner: "Direct, énergique, corrige vite les tons. Encourage brièvement.",
            preferredVoiceIdentifier: nil,
            speechRate: 0.48,
            accent: Color(red: 0.16, green: 0.36, blue: 0.48)
        ),
        Tutor(
            id: "wang",
            hanzi: "王老师",
            pinyin: "Wáng lǎoshī",
            manner: "Chaleureux, un peu bavard, aime les exemples du quotidien.",
            preferredVoiceIdentifier: nil,
            speechRate: 0.45,
            accent: Color(red: 0.40, green: 0.33, blue: 0.16)
        ),
        Tutor(
            id: "zhao",
            hanzi: "赵老师",
            pinyin: "Zhào lǎoshī",
            manner: "Précis, exigeant sur la prononciation, peu de bavardage.",
            preferredVoiceIdentifier: nil,
            speechRate: 0.44,
            accent: Color(red: 0.24, green: 0.40, blue: 0.27)
        ),
    ]

    static func tutor(id: String?) -> Tutor {
        guard let id, let found = all.first(where: { $0.id == id }) else { return all[0] }
        return found
    }

    /// Le tuteur du jour : une simple rotation, sauf si l'apprenant en a fixé un.
    static func next(after lastID: String?, locked: String?) -> Tutor {
        if let locked, let tutor = all.first(where: { $0.id == locked }) { return tutor }
        guard let lastID, let index = all.firstIndex(where: { $0.id == lastID }) else { return all[0] }
        return all[(index + 1) % all.count]
    }

    /// L'initiale affichée dans l'avatar, à défaut d'un dessin.
    var initial: String { String(hanzi.prefix(1)) }
}

/// Les phrases de transition, en mandarin, jouées pendant que le modèle
/// réfléchit. Dix variantes : assez pour que l'attente ne sonne pas comme une
/// boucle, assez peu pour rester simples à comprendre au niveau 1.
enum TransitionPhrases {
    static let all: [(zh: String, pinyin: String, fr: String)] = [
        ("好", "hǎo", "bien"),
        ("嗯", "ǹg", "mmh"),
        ("好的", "hǎo de", "d'accord"),
        ("对", "duì", "c'est ça"),
        ("我想想", "wǒ xiǎng xiang", "je réfléchis"),
        ("等一下", "děng yí xià", "un instant"),
        ("是这样", "shì zhèyàng", "c'est comme ça"),
        ("很好", "hěn hǎo", "très bien"),
        ("再说一次", "zài shuō yí cì", "redis-le une fois"),
        ("你说", "nǐ shuō", "à toi"),
    ]

    /// Une phrase au hasard, jamais deux fois la même de suite.
    static func random(avoiding previous: String?) -> (zh: String, pinyin: String, fr: String) {
        let pool = all.filter { $0.zh != previous }
        return pool.randomElement() ?? all[0]
    }
}
