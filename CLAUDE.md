# Budokai Ichi

App iPhone SwiftUI : défis sportifs inspirés d'animés japonais, avec XP,
niveaux, rangs et déblocages. Voir `README.md` pour le détail du moteur et
des neuf programmes, et `docs/cadrage-budokai-chi.html` pour le cadrage.

## À qui on parle

Franck n'est pas développeur. Pas de jargon, pas d'explication technique non
demandée. Quand il y a quelque chose à faire de son côté : des étapes
numérotées, littérales, en français. Réponses en français.

## Branche de travail

`claude/100-pushups-challenge-app-0aj91w`. La v1 (défi 100 pompes) est figée
sur la branche `v1-defi-100-pompes`, commit `258e22c`.

## Deux environnements, un seul projet

Les sessions distantes (cloud) **ne peuvent pas compiler** : pas de macOS, pas
de Swift, pas de Xcode. Elles écrivent, committent, poussent. Seule une session
**locale sur le Mac** compile et installe sur l'iPhone.

Conséquence : à chaque changement de côté, commencer par `git pull`, et finir
par un commit + push. Une session distante qui touche au code doit écrire du
SwiftUI conservateur — elle ne verra jamais l'erreur de compilation.

## Pièges à ne pas réintroduire

- **`PRODUCT_BUNDLE_IDENTIFIER` reste `com.franckmoyal.PompesChallenge`**,
  malgré le renommage en Budokai Ichi. C'est ce qui fait que l'app installée
  se met à jour au lieu de se dupliquer, et que les données de la v1 migrent.
  Ne pas « corriger ».
- `DEVELOPMENT_TEAM = A7H8D53DKZ` — signature de l'app, ne pas retirer.
- Projet Xcode 16 à groupes synchronisés (`PBXFileSystemSynchronizedRootGroup`) :
  un fichier déposé dans `BudokaiIchi/` est pris en compte sans toucher au
  `.pbxproj`.
- Pas de `Text(...) + Text(...)` avec le `+` en début de ligne.
- `ForEach` sur des indices (`x.indices, id: \.self`), pas sur des tuples
  d'`enumerated()`.
- Jamais deux `fullScreenCover` présentés en même temps — `GameStore.complete`
  *retourne* le résultat de séance au lieu de le publier, exprès.
- Les textes de motivation sont tirés par un pseudo-aléatoire **déterministe**
  (graine = jour + compteur) : un vrai aléatoire changerait à chaque redraw.
- Notifications : fenêtre glissante de 20 jours en `UNCalendarNotificationTrigger`
  à usage unique, pas `repeats: true` — chaque jour a un texte différent.

## Illustrations

Fonds d'univers dans `design-v2/images/`, tirés du domaine public (Met Open
Access, CC0), générés par `tools/fetch_universes.py` — chaque œuvre est
**épinglée par objectID**, ne pas revenir à une sélection automatique.
Franck dépose ses propres images dans `design-v2/images/banque/`.

## Messages de commit

En français, à l'impératif, sujet court. Le corps explique le *pourquoi*
quand ce n'est pas évident.
