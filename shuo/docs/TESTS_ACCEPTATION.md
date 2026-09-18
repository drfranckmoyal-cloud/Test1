# Les 18 tests d'acceptation, et où ils vivent dans le code

Le dossier de livraison arrive avec 18 tests (`handoff/11_ACCEPTANCE_TESTS.json`).
Ce tableau dit, pour chacun, ce qui l'implémente et comment le vérifier.

Trois d'entre eux tournent **dans l'app**, en mode développeur → *Vérification du
contenu embarqué*. Les autres se vérifient à la main, sur l'iPhone.

| # | Ce qui est testé | Où c'est implémenté | Comment vérifier |
|---|---|---|---|
| A01 | Les 300 mots officiels, une fois chacun | `ContentAudit.vocabularyCount`, `ContentAudit.everyWordTaughtOnce` | Mode développeur → A01a et A01b au vert |
| A02 | Jamais plus de 3 mots nouveaux | `SessionOrchestrator.maxNewItemsPerSession`, `SessionOrchestrator.isValid`, `ContentAudit.noSessionOverThree` | Mode développeur → A02 ; l'invariant est aussi vérifié avant chaque séance |
| A03 | Un mot mal prononcé ne devient pas vert | `MasteryEngine.status` — le verrou oral est évalué **avant** tout le reste | Répondre juste mais mal prononcer : le mot reste orange |
| A04 | Quitter et relancer restaure tout | `LearnerStore` (fichier JSON dans Application Support) | Faire deux séances, tuer l'app, rouvrir : statuts, curseur et échéances sont là |
| A05 | Un échec isolé ne rétrograde pas | `MasteryEngine.applyDowngradeIfWarranted` — il faut deux séances d'échec *distinctes* | Rater un mot vert une fois : il reste vert, sa fragilité monte |
| A06 | Des échecs séparés peuvent rétrograder | même fonction, `failedSessionsBeforeDowngrade = 2` | Le rater en révision sur deux séances différentes : il passe orange |
| A07 | « aide » donne une aide graduée | `HelpLadderState.requestGradedHelp` — le premier « aide » ne donne rien, il demande ce qui bloque | Dire « aide » : le tuteur demande d'abord |
| A08 | « réponse » donne la solution | `HelpLadderState.requestAnswer` | Dire « réponse » : solution immédiate, puis réemploi demandé |
| A09 | Couper le tuteur l'arrête | `VoiceService.handleInput` → `stopSpeaking(at: .immediate)` | En mains libres, parler pendant qu'il parle |
| A10 | Basculer mains libres ↔ appui pour parler | `VoiceService.modeDidChange`, boutons dans `VoiceControls` | Basculer en pleine séance : rien n'est perdu |
| A11 | Test de retour après ~3 jours | `LearnerStore.shouldOfferReturnTest`, carte dans `HomeView` | Avancer la date de l'iPhone de 3 jours |
| A12 | Modèle, jetons, latence et coût visibles | `Telemetry`, `DevModeView` | Mode développeur pendant une séance |
| A13 | Hanzi + pinyin + français, lecture non bloquante | `WordCardView` ; `VocabItem.readingBlocking` n'est lu par aucune règle de validation | Apprendre un mot sans savoir lire le caractère |
| A14 | On attend la fin de la tentative | `SessionRunner.handlePhaseOutcome` n'évalue qu'à la fin du tour ; règle 1 du prompt système | Se tromper au milieu d'une phrase |
| A15 | Erreur répétée → micro-remédiation bornée | `MasteryEngine.recordError` (3 récurrences), phase `.remediation` de 60 s en tête de séance | Faire trois fois la même erreur |
| A16 | Filet français / retour au guidé | `HelpCommand.arreteToi` → `SessionRunner.returnToGuidedMode` | Dire « arrête-toi » en conversation libre |
| A17 | Rien de neuf dans les deux dernières minutes | `SessionOrchestrator` place toujours `.recap` en dernier, sans `newItems` ; `RecapView` n'affiche ni note ni leçon suivante | Aller au bout d'une séance |
| A18 | Périmètre officiel distinct de la couche Shuō | `VocabItem.contentStatus`, `ContentAudit.officialScopeStaysDistinct` | Mode développeur → A18 au vert |

## Ce qui n'est pas encore vérifiable en session distante

Aucune de ces lignes n'a été compilée : une session Claude Code dans le nuage
n'a ni macOS, ni Xcode. La première ouverture sur le Mac est donc aussi la
première compilation. C'est attendu, et c'est la règle du dépôt.
