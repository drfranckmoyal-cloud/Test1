import Foundation

/// Les soixante-quatre beats narratifs de Saitama, chapitres 11 à 18 de la
/// spécification.
///
/// Ce sont les faits narratifs tels que le document les arrête : ils sont
/// repris **mot pour mot**, jamais réécrits ni complétés. Aucune citation
/// canonique n'est déclarée — la spécification interdit d'en inventer, et
/// aucune source vérifiée n'est fournie. Le `senseiMessage`, lui, est un
/// texte original Budokai, et n'est jamais présenté comme une citation.
enum SaitamaNarrative {

    static let beats: [NarrativeContent] = [
        beat("SAI-B1-N01", 1, 1, "Origines", "Avant le héros", "Saitama est encore un jeune homme ordinaire en recherche d'emploi."),
        beat("SAI-B1-N02", 1, 2, "Origines", "Crablante", "Première confrontation qui réveille l'envie de devenir héros."),
        beat("SAI-B1-N03", 1, 3, "Origines", "Le choix", "Devenir héros par passion plutôt que par statut."),
        beat("SAI-B1-N04", 1, 4, "Origines", "Le premier jour d'entraînement", "Commencer sans garantie de résultat."),
        beat("SAI-B1-N05", 1, 5, "Origines", "Répéter la routine", "L'idée simple qui deviendra son obsession."),
        beat("SAI-B1-N06", 1, 6, "Origines", "Les jours sans gloire", "Aucun classement, aucun témoin, seulement la régularité."),
        beat("SAI-B1-N07", 1, 7, "Origines", "La transformation commence avant qu'elle ne soit visible", "La transformation commence avant qu'elle ne soit visible."),
        beat("SAI-B1-N08", 1, 8, "Origines", "Premier jalon", "La décision vaut moins que les répétitions réellement accomplies."),
        beat("SAI-B2-N01", 2, 9, "La routine", "Trois années d'entraînement", "La force de Saitama vient d'une répétition obstinée."),
        beat("SAI-B2-N02", 2, 10, "La routine", "La routine emblématique est révélée comme quelque chose de volontairement extrême", "La routine emblématique est révélée comme quelque chose de volontairement extrême."),
        beat("SAI-B2-N03", 2, 11, "La routine", "La perte des cheveux devient le symbole comique de sa transformation", "La perte des cheveux devient le symbole comique de sa transformation."),
        beat("SAI-B2-N04", 2, 12, "La routine", "Vaccine man", "Le monde est déjà rempli de menaces avant que Saitama ne soit reconnu."),
        beat("SAI-B2-N05", 2, 13, "La routine", "Beefcake", "Puissance gigantesque contre simplicité absolue."),
        beat("SAI-B2-N06", 2, 14, "La routine", "Le rêve des subterraneans", "Saitama cherche enfin un combat qui lui fasse ressentir quelque chose."),
        beat("SAI-B2-N07", 2, 15, "La routine", "Le réveil", "Contraste entre fantasme d'adversité et réalité de son invincibilité."),
        beat("SAI-B2-N08", 2, 16, "La routine", "La routine devient un repère, pas encore un challenge à reproduire chaque jour", "La routine devient un repère, pas encore un challenge à reproduire chaque jour."),
        beat("SAI-B3-N01", 3, 17, "Genos et la Maison de l'Évolution", "Mosquito girl", "Entrée de Genos dans l'histoire."),
        beat("SAI-B3-N02", 3, 18, "Genos et la Maison de l'Évolution", "Genos observe une force qu'il ne comprend pas encore", "Genos observe une force qu'il ne comprend pas encore."),
        beat("SAI-B3-N03", 3, 19, "Genos et la Maison de l'Évolution", "La demande de devenir disciple transforme saitama malgré lui en maître", "La demande de devenir disciple transforme Saitama malgré lui en maître."),
        beat("SAI-B3-N04", 3, 20, "Genos et la Maison de l'Évolution", "L'attaque de la maison de l'évolution rapproche la théorie de la pratique", "L'attaque de la Maison de l'Évolution rapproche la théorie de la pratique."),
        beat("SAI-B3-N05", 3, 21, "Genos et la Maison de l'Évolution", "Armored gorilla", "La puissance ne suffit pas à rendre un combat intéressant."),
        beat("SAI-B3-N06", 3, 22, "Genos et la Maison de l'Évolution", "Dr genus", "Obsession de l'évolution artificielle face à la simplicité de Saitama."),
        beat("SAI-B3-N07", 3, 23, "Genos et la Maison de l'Évolution", "Carnage kabuto", "L'entraînement de Saitama devient lui-même un mystère."),
        beat("SAI-B3-N08", 3, 24, "Genos et la Maison de l'Évolution", "Genos apprend que copier une routine n'est pas comprendre une progression", "Genos apprend que copier une routine n'est pas comprendre une progression."),
        beat("SAI-B4-N01", 4, 25, "Hero Association", "Examen de la hero association", "Saitama doit enfin être mesuré par un système extérieur."),
        beat("SAI-B4-N02", 4, 26, "Hero Association", "L'épreuve physique", "Contraste entre capacités réelles et classement administratif."),
        beat("SAI-B4-N03", 4, 27, "Hero Association", "Classe c", "Être le plus fort ne signifie pas être reconnu."),
        beat("SAI-B4-N04", 4, 28, "Hero Association", "Genos entre en classe s pendant que saitama commence tout en bas", "Genos entre en Classe S pendant que Saitama commence tout en bas."),
        beat("SAI-B4-N05", 4, 29, "Hero Association", "Le nom caped baldy rappelle que le statut public ne reflète pas la performance", "Le nom Caped Baldy rappelle que le statut public ne reflète pas la performance."),
        beat("SAI-B4-N06", 4, 30, "Hero Association", "La règle d'activité hebdomadaire impose de la constance, même à saitama", "La règle d'activité hebdomadaire impose de la constance, même à Saitama."),
        beat("SAI-B4-N07", 4, 31, "Hero Association", "Sonic réapparaît comme rival autoproclamé et obsédé par la vitesse", "Sonic réapparaît comme rival autoproclamé et obsédé par la vitesse."),
        beat("SAI-B4-N08", 4, 32, "Hero Association", "Premier vrai palier budokai", "La moitié de la routine canonique devient accessible."),
        beat("SAI-B5-N01", 5, 33, "Z-City", "Une météorite géante menace z-city", "Une météorite géante menace Z-City."),
        beat("SAI-B5-N02", 5, 34, "Z-City", "La hero association appelle les héros de classe s", "La Hero Association appelle les héros de Classe S."),
        beat("SAI-B5-N03", 5, 35, "Z-City", "Genos se prépare à utiliser tout ce qu'il possède", "Genos se prépare à utiliser tout ce qu'il possède."),
        beat("SAI-B5-N04", 5, 36, "Z-City", "Silver fang apparaît comme repère de maîtrise plutôt que de panique", "Silver Fang apparaît comme repère de maîtrise plutôt que de panique."),
        beat("SAI-B5-N05", 5, 37, "Z-City", "Metal knight choisit sa propre logique d'intervention", "Metal Knight choisit sa propre logique d'intervention."),
        beat("SAI-B5-N06", 5, 38, "Z-City", "Saitama arrive avec sa simplicité habituelle face à une menace démesurée", "Saitama arrive avec sa simplicité habituelle face à une menace démesurée."),
        beat("SAI-B5-N07", 5, 39, "Z-City", "Détruire la météorite ne supprime pas toutes les conséquences", "Puissance et résultat ne sont pas identiques."),
        beat("SAI-B5-N08", 5, 40, "Z-City", "Le bloc rappelle qu'une grosse séance ne remplace jamais la progression accumulée", "Le bloc rappelle qu'une grosse séance ne remplace jamais la progression accumulée."),
        beat("SAI-B6-N01", 6, 41, "Deep Sea King", "Les deep sea folk envahissent la surface", "Les Deep Sea Folk envahissent la surface."),
        beat("SAI-B6-N02", 6, 42, "Deep Sea King", "Pri-pri prisoner affronte le deep sea king", "Pri-Pri Prisoner affronte le Deep Sea King."),
        beat("SAI-B6-N03", 6, 43, "Deep Sea King", "Sonic mise sur sa vitesse mais le contexte change le rapport de force", "Sonic mise sur sa vitesse mais le contexte change le rapport de force."),
        beat("SAI-B6-N04", 6, 44, "Deep Sea King", "Genos intervient malgré un combat qui se dégrade", "Genos intervient malgré un combat qui se dégrade."),
        beat("SAI-B6-N05", 6, 45, "Deep Sea King", "L'abri devient le centre de la tension", "La puissance des héros est comparée à l'attente du public."),
        beat("SAI-B6-N06", 6, 46, "Deep Sea King", "Mumen rider arrive sans disposer de la puissance nécessaire", "Mumen Rider arrive sans disposer de la puissance nécessaire."),
        beat("SAI-B6-N07", 6, 47, "Deep Sea King", "Son intervention incarne l'engagement malgré l'écart de niveau", "Son intervention incarne l'engagement malgré l'écart de niveau."),
        beat("SAI-B6-N08", 6, 48, "Deep Sea King", "Saitama conclut le combat, mais laisse volontairement la place aux autres héros dans le regard du public", "Saitama conclut le combat, mais laisse volontairement la place aux autres héros dans le regard du public."),
        beat("SAI-B7-N01", 7, 49, "Dark Matter", "La prophétie de shibabawa annonce une menace d'une autre échelle", "La prophétie de Shibabawa annonce une menace d'une autre échelle."),
        beat("SAI-B7-N02", 7, 50, "Dark Matter", "Les héros de classe s sont rassemblés", "Les héros de Classe S sont rassemblés."),
        beat("SAI-B7-N03", 7, 51, "Dark Matter", "Le vaisseau de dark matter transforme a-city en champ de bataille", "Le vaisseau de Dark Matter transforme A-City en champ de bataille."),
        beat("SAI-B7-N04", 7, 52, "Dark Matter", "Melzargard retient plusieurs héros à l'extérieur", "Melzargard retient plusieurs héros à l'extérieur."),
        beat("SAI-B7-N05", 7, 53, "Dark Matter", "Saitama entre seul dans le vaisseau", "Saitama entre seul dans le vaisseau."),
        beat("SAI-B7-N06", 7, 54, "Dark Matter", "Geryuganshoop illustre encore le contraste entre démonstration spectaculaire et efficacité", "Geryuganshoop illustre encore le contraste entre démonstration spectaculaire et efficacité."),
        beat("SAI-B7-N07", 7, 55, "Dark Matter", "Boros apparaît enfin comme adversaire capable de survivre au premier échange", "Boros apparaît enfin comme adversaire capable de survivre au premier échange."),
        beat("SAI-B7-N08", 7, 56, "Dark Matter", "Le serious series annonce le dernier niveau de spécificité avant ton propre challenge final", "Le Serious Series annonce le dernier niveau de spécificité avant ton propre challenge final."),
        beat("SAI-B8-N01", 8, 57, "King, Garou, conclusion", "Après boros, l'ennui de saitama ne disparaît pas", "Être le plus fort n'est pas une fin en soi."),
        beat("SAI-B8-N02", 8, 58, "King, Garou, conclusion", "King est présenté comme l'homme le plus fort aux yeux du public", "King est présenté comme l'homme le plus fort aux yeux du public."),
        beat("SAI-B8-N03", 8, 59, "King, Garou, conclusion", "La relation saitama–king montre le décalage entre réputation et réalité", "La relation Saitama–King montre le décalage entre réputation et réalité."),
        beat("SAI-B8-N04", 8, 60, "King, Garou, conclusion", "Garou déclare la guerre au monde des héros", "Garou déclare la guerre au monde des héros."),
        beat("SAI-B8-N05", 8, 61, "King, Garou, conclusion", "Le tournoi super fight offre à saitama un autre moyen de chercher du défi", "Le tournoi Super Fight offre à Saitama un autre moyen de chercher du défi."),
        beat("SAI-B8-N06", 8, 62, "King, Garou, conclusion", "Les monstres et les héros continuent de s'affronter pendant que saitama reste en marge des classements", "Les monstres et les héros continuent de s'affronter pendant que Saitama reste en marge des classements."),
        beat("SAI-B8-N07", 8, 63, "King, Garou, conclusion", "La dernière semaine budokai ne cherche plus à construire", "Elle cherche à laisser apparaître le travail déjà fait."),
        beat("SAI-B8-N08", 8, 64, "King, Garou, conclusion", "Boss final", "Tu ne copies pas l'entraînement quotidien de Saitama ; tu prouves une fois que ton propre parcours t'a rendu capable de sa routine.")
    ]

    /// Le récit d'une séance, consommé dans l'ordre chronologique.
    static func content(sessionIndex: Int) -> NarrativeContent? {
        guard !beats.isEmpty else { return nil }
        return beats[min(sessionIndex, beats.count - 1)]
    }

    /// Les beats d'un bloc donné.
    static func beats(inBlock index: Int) -> [NarrativeContent] {
        let prefix = "SAI-B\(index)-N"
        return beats.filter { $0.id.hasPrefix(prefix) }
    }

    private static func beat(_ id: String, _ block: Int, _ chronology: Int,
                             _ arc: String, _ title: String, _ recap: String) -> NarrativeContent {
        NarrativeContent(
            id: id, anime: "One Punch Man", character: "Saitama",
            arc: arc, chronologyIndex: chronology,
            narrativeTitle: title, storyRecap: recap,
            references: [], canonicalQuote: nil, quoteCharacter: nil,
            senseiMessage: sensei[block] ?? nil,
            spoilerLevel: .anime)
    }

    /// Un mot du maître par bloc. Texte original Budokai, pas une citation.
    private static let sensei: [Int: String] = [
        1: "Personne ne te regarde encore. C'est le meilleur moment pour commencer.",
        2: "La routine ne devient une force que le jour où elle cesse d'être une décision.",
        3: "Copier un entraînement n'est pas comprendre une progression.",
        4: "Être capable et être classé sont deux choses différentes. Travaille la première.",
        5: "Une grosse séance ne rattrape jamais trois semaines de rien.",
        6: "Tenir quand on n'a pas le niveau, c'est déjà une forme de force.",
        7: "Arrivé ici, ce n'est plus le volume qui décide. C'est la fraîcheur.",
        8: "Cette semaine ne construit plus rien. Elle laisse apparaître ce qui est déjà là."
    ]
}
