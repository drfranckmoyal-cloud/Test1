# Shuō / 说

App iPhone d'apprentissage oral du mandarin. Identifiant `com.franckmoyal.Shuo`.

Ce fichier fait autorité pour ce dossier. Le `CLAUDE.md` de la racine dit la
règle commune aux trois apps du dépôt : **une conversation, une app, un
dossier**. Ne pas toucher à `defi-100-pompes/` ni à `budokai-ichiban/` depuis
ici.

## La source de vérité

`handoff/` contient le dossier de livraison V2 tel qu'il est arrivé. En cas de
doute sur une décision d'implémentation, `handoff/00_SOURCE_OF_TRUTH_V2.json`
tranche. **On ne redessine pas la pédagogie** : elle est décidée, écrite, et le
code l'exécute.

Les fichiers de contenu réellement embarqués dans l'app sont dans
`Shuo/Content/`. Ils gardent leur nom d'origine (`02_…`, `04_…`) pour qu'on
retrouve d'où vient chaque donnée des mois plus tard.

## Ce qui ne se négocie pas

Ces règles viennent du dossier. Une modification qui en casse une est une
régression, même si elle paraît meilleure :

- **1 à 3 mots nouveaux par séance**, jamais plus. L'invariant est vérifié deux
  fois : à la composition (`SessionOrchestrator.isValid`) et sur le contenu
  embarqué (`ContentAudit`).
- **Un mot mal prononcé ne peut pas devenir vert.** Le verrou est dans
  `MasteryEngine.status`, avant tout autre critère.
- **Un échec isolé ne rétrograde jamais un vert.** Il faut des échecs sur des
  séances *différentes*.
- **Le modèle de langue ne décide d'aucun statut.** Il propose des notes ;
  `MasteryEngine` tranche. Cette séparation est le cœur de l'architecture.
- **Le hanzi est montré dès le premier jour, mais savoir le lire ne bloque
  rien** dans la validation orale.
- `aide` = aide graduée, `réponse` = solution immédiate, `arrête-toi` = retour
  au mode guidé.
- L'apprenant finit sa phrase avant d'être corrigé, sauf blocage prolongé.
- La parole de l'apprenant coupe le tuteur immédiatement.
- Le nom du modèle réellement actif reste affiché.
- La cible de coût (~1,25 €/h) est une alerte, pas un robinet. La qualité
  l'emporte quand on hésite.

`docs/TESTS_ACCEPTATION.md` dit où chacun des 18 tests du dossier est
implémenté.

## L'identité

Elle est **dessinée**, pas importée : `Shuo/Views/BrandMarks.swift` porte le
cercle au pinceau, le disque rouge, le sceau et le logo. `tools/make_app_icon.py`
reprend la même géométrie pour l'icône — si l'un change, changer l'autre.
`docs/IDENTITE.md` donne la palette, les règles et ce qui manque encore.

## L'architecture, en une phrase par couche

| Dossier | Ce qu'il porte |
|---|---|
| `Shuo/Model/` | Les formes : contenu HSK, modèle apprenant |
| `Shuo/Engine/` | Les décisions : maîtrise, révision, recette de séance, déroulé |
| `Shuo/Services/` | Les exécutants : voix, tuteurs, modèles de langue, télémétrie |
| `Shuo/Views/` | L'écran, et la marque dessinée en vectoriel |
| `Shuo/Content/` | Le contenu embarqué |

Le moteur pédagogique (`Engine/`) ne dépend d'aucun modèle de langue. On doit
pouvoir débrancher `AnthropicTutorBrain` et faire une séance entière avec
`ScriptedTutorBrain` — c'est d'ailleurs ce qui se passe hors ligne ou sans clé.

## Les modèles de langue

Deux, choisis par `ModelRouter` : `claude-haiku-4-5` par défaut,
`claude-opus-5` quand c'est nécessaire — et **quand on hésite**. La clé d'API se
saisit en mode développeur et vit dans le trousseau, jamais dans les réglages,
jamais dans les journaux exportés.

## Deux environnements

Une session distante (nuage) **ne peut pas compiler** : pas de macOS, pas de
Xcode. Elle écrit, committe, pousse. Seule une session locale sur le Mac
compile et installe sur l'iPhone. Donc : du SwiftUI conservateur, et `git pull`
en arrivant, commit + push en partant.

## À qui on parle

Franck n'est pas développeur. Pas de jargon, pas d'explication technique non
demandée. Quand il y a quelque chose à faire de son côté : des étapes
numérotées, littérales, en français. Réponses en français.

## Messages de commit

En français, à l'impératif, sujet court. Le corps explique le *pourquoi* quand
ce n'est pas évident.
