import Foundation

/// La phrase qui accompagne l'illustration d'un jalon.
///
/// Elle décrit **le moment représenté sur l'image**, et c'est ce qui la
/// distingue du pack narratif : celui-ci raconte l'ouverture du chapitre, qui
/// ne coïncide pas toujours avec la scène illustrée. Le jalon du Déclic montre
/// le Crablante ; le récit du pack parle du jeune homme sans emploi. Les deux
/// sont justes, mais sous une image c'est la scène qu'il faut nommer.
///
/// Ces phrases sont donc écrites pour l'application, pas tirées du pack. Elles
/// vivent à part pour qu'on ne les confonde jamais avec l'éditorial, et le
/// repli reste le récit du pack là où aucune phrase n'a été écrite.
enum ArcContext {

    /// La phrase d'un jalon, ou le récit du pack à défaut.
    static func line(_ id: ProgramID, stageIndex: Int) -> String? {
        if let written = table[id.rawValue], stageIndex >= 0, stageIndex < written.count {
            return written[stageIndex]
        }
        return NarrationLibrary.stageContext(id, stageIndex: stageIndex)
    }

    /// Une phrase par jalon, dans l'ordre de la progression.
    private static let table: [String: [String]] = [

        "saitama": [
            // 1 · Le Déclic — Saitama face au Crablante
            "Un homme ordinaire, sans travail, face à un monstre. C'est ce jour-là qu'il décide de devenir fort.",
            // 2 · L'Entraînement — la routine
            "Cent pompes, cent abdominaux, cent squats, dix kilomètres. Tous les jours, sans exception.",
            // 3 · Le Disciple — Genos et la Maison de l'Évolution
            "Genos cherche le secret de sa force. Il n'y en a pas : il y a trois ans de répétition.",
            // 4 · Héros professionnel — l'examen de la Hero Association
            "Le jour où sa force doit passer devant un jury. Le classement dira classe C.",
            // 5 · La Météorite — Z-City
            "Une météorite tombe sur Z-City. Personne d'autre ne peut l'arrêter.",
            // 6 · Justice indomptable — Deep Sea King
            "Le Roi des Profondeurs écrase les héros un par un. Mumen Rider se relève quand même.",
            // 7 · Conquérant de l'Univers — Boros
            "Boros a traversé l'espace pour trouver un adversaire à sa hauteur. Il l'a trouvé.",
            // 8 · Le Plus Fort — Super Fight
            "Être le plus fort ne suffit pas. Il cherche encore quelqu'un capable de le faire trembler.",
        ],

        "naruto": [
            // 1 · Genin — le départ de Konoha
            "L'équipe sept franchit les portes du village. Le dernier de la classe part en mission.",
            // 2 · Examen Chūnin — Naruto contre Neji
            "Face à Neji, on lui dit que son destin est écrit. Il répond qu'il ne revient jamais sur sa parole.",
            // 3 · Héritier de Jiraiya — le Rasengan
            "Jiraiya lui apprend le Rasengan. Une technique qui ne se copie pas : elle s'arrache par la répétition.",
            // 4 · Mode Sennin — Pain à Konoha
            "Konoha est en ruines et Pain l'attend. Naruto revient en mode ermite, seul contre six.",
            // 5 · Hokage — l'aube sur Konoha
            "Le village qui le rejetait le regarde désormais d'en bas. Il est devenu Hokage.",
        ],
    ]
}
