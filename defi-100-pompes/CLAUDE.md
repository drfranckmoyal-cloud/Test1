# Défi 100 Pompes

App iPhone de motivation pour un défi quotidien : un nombre de jours, un ou
plusieurs exercices (pompes, tractions, abdos) avec leur objectif de répétitions.
Compteur, calendrier, trois rappels par jour, phrases de motivation. Voir
`README.md` pour le détail des écrans.

**Identifiant : `com.franckmoyal.PompesChallenge`. Nom affiché : 100 Pompes.**

C'est son identifiant depuis le premier jour. Il ne change pas : c'est lui qui
désigne, sur le téléphone, le coffre où sont rangés l'historique, les séries et
les records.

## Le périmètre de ce dossier

Tout ce qui concerne le défi est ici, et rien d'autre. Budokai Ichiban vit dans
`../budokai-ichiban/` : c'est une **autre app**, née de ce code mais devenue un
autre produit. Ne jamais modifier les deux dans la même session.

Budokai Ichiban a un temps porté l'identifiant de cette app, pour la remplacer sur
le téléphone. Ce n'est plus le cas : chacune a le sien, et les deux s'installent
côte à côte.

## Pièges à ne pas réintroduire

- Projet Xcode 16 à groupes synchronisés (`PBXFileSystemSynchronizedRootGroup`) :
  un fichier déposé dans `PompesChallenge/` est pris en compte sans toucher au
  `.pbxproj`.
- `DEVELOPMENT_TEAM = A7H8D53DKZ` — signature de l'app, ne pas retirer.
- Pas de `Text(...) + Text(...)` avec le `+` en début de ligne.
- `ForEach` sur des indices (`x.indices, id: \.self`), pas sur des tuples
  d'`enumerated()`.
- Les phrases de motivation sont tirées par un pseudo-aléatoire **déterministe**
  (graine = jour + compteur) : un vrai aléatoire changerait à chaque redraw.
- Notifications : fenêtre glissante de 20 jours en `UNCalendarNotificationTrigger`
  à usage unique, pas `repeats: true` — chaque jour a un texte différent.
- Le bouton « remettre la journée à zéro » demande une confirmation. Ne pas la
  retirer.

## Distribution

- **TestFlight** — `./tools/envoie-testflight.sh` archive et transmet en une
  commande. Détail et procédure manuelle dans `docs/TESTFLIGHT.md`.
- **Version web** — `web/`, site statique publié sur
  <https://defi-100-pompes.netlify.app>, à ajouter à l'écran d'accueil depuis
  Safari. Le `netlify.toml` est à la racine du dépôt et pointe sur
  `defi-100-pompes/web`.
