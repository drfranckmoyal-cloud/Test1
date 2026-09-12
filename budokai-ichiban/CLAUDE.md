# Budokai Ichiban

武道会一 — jeu de progression sportive. Des programmes d'entraînement tirés
d'animés japonais, de l'expérience, des rangs, des caractéristiques et des
déblocages. Voir `README.md` pour le moteur et les neuf programmes,
`docs/cadrage-budokai-chi.html` pour le cadrage.

**Identifiant : `com.franckmoyal.BudokaiIchiban`. Nom affiché : Budokai Ichiban.**

## Le périmètre de ce dossier

Tout ce qui concerne le jeu est ici, et rien d'autre. L'app du défi 100 pompes
vit dans `../defi-100-pompes/` : c'est une **autre app**, pas une ancienne
version de celle-ci. Ne jamais modifier les deux dans la même session, ne jamais
reprendre du code de l'une vers l'autre sans une raison explicite.

Le jeu est né du code du défi, et en a longtemps porté l'identifiant pour le
remplacer sur le téléphone. Cette époque est finie : les deux apps sont
désormais indépendantes et s'installent côte à côte. Le code de reprise des
anciennes données de pompes a été retiré — l'app démarre sur un état vierge.

## Pièges à ne pas réintroduire

- Projet Xcode 16 à groupes synchronisés (`PBXFileSystemSynchronizedRootGroup`) :
  un fichier déposé dans `BudokaiIchi/` est pris en compte sans toucher au
  `.pbxproj`.
- `DEVELOPMENT_TEAM = A7H8D53DKZ` — signature de l'app, ne pas retirer.
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

## Ce qui reste

- Le test de forme à l'inscription : pour l'instant une simple déclaration.
- Le réglage de la courbe d'XP et des seuils de caractéristiques, sur des
  chiffres d'usage réels.
