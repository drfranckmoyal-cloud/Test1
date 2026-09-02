# 100 Pompes Challenge

Application iPhone de motivation pour un défi quotidien : un nombre de jours et un ou
plusieurs exercices (**pompes**, **tractions**, **abdos**) avec leur objectif de
répétitions par jour. Le défi par défaut reste 100 pompes par jour pendant 30 jours.

Chaque journée court **de minuit à minuit** : les totaux sont enregistrés sous la date
locale du jour, donc les compteurs repartent de zéro tout seuls au changement de date. Un
jour est **validé** quand *tous* les exercices du défi ont atteint leur objectif ; sinon
il est manqué définitivement.

## Ouvrir le projet

```
open PompesChallenge.xcodeproj
```

Sélectionner un simulateur iPhone (ou un appareil) puis `⌘R`.

- Xcode 16 ou plus récent (le projet utilise un groupe synchronisé avec le système de
  fichiers : les fichiers ajoutés dans `PompesChallenge/` sont pris en compte
  automatiquement, sans passer par le `.pbxproj`).
- iOS 17 minimum, iPhone uniquement, portrait, apparence sombre forcée.
- Sur un appareil réel, remplacer `PRODUCT_BUNDLE_IDENTIFIER` par votre propre
  identifiant et choisir votre équipe de signature dans l'onglet *Signing & Capabilities*.

## Les écrans

| Écran | Ce qu'il fait |
|---|---|
| **Aujourd'hui** | Un anneau de progression par exercice (leur taille s'adapte au nombre d'exercices), une carte par exercice avec ajouts rapides calibrés (+5/+10/+20 pour les pompes, +1/+2/+5 pour les tractions…), correction des totaux, message de motivation, barre d'avancement du défi. |
| **Calendrier** | Tous les jours du défi : étoile orange si validé, case grise si manqué, contour orange et pourcentage sur le jour en cours, gris éteint pour les jours à venir. Toucher un jour passé ouvre la saisie de tous ses exercices. Série en cours, meilleure série et total de répétitions en bas. |
| **Réglages** | Le défi en cours (objectif de chaque exercice, réglable à la volée) et le bouton **Créer un nouveau défi** ; les trois rappels quotidiens ; le ton des messages ; l'apparence (clair / sombre / système). |
| **Célébration** | Plein écran orange à l'instant où la journée est bouclée : jour validé, détail par exercice, série, semaine en étoiles. Affiché une seule fois par jour. |

## Nouveau défi

*Réglages → Créer un nouveau défi* : durée (au jour près, ou 7 / 14 / 21 / 30 / 60 / 90),
puis les exercices à inclure avec leur objectif quotidien. Le nouveau défi démarre le jour
même au jour 1 ; l'historique précédent est effacé après confirmation.

## Rappels

Trois notifications locales répétées tous les jours (07:30, 13:00, 20:30 par défaut),
reprogrammées à chaque modification d'horaire, d'objectif ou de ton. Chaque créneau porte
une part de l'objectif (30 % / 35 % / 35 %) et la notification liste ce qu'il y a à faire
pour tous les exercices : « 30 pompes, 6 tractions, 45 abdos ». Si les notifications sont
refusées au niveau du système, l'écran Réglages affiche un bandeau et un raccourci vers
les réglages iOS.

## Apparence

Thème clair (défaut), sombre, ou suivi du réglage système. Les couleurs sont déclarées une
seule fois dans `Design/Theme.swift` sous forme de paires clair/sombre et basculent
seules.

Trois tons de message sont disponibles — **Cash**, **Coach**, **Zen** — et s'appliquent
aussi bien aux notifications qu'aux textes affichés dans l'app.

## Organisation du code

```
PompesChallenge/
├── PompesChallengeApp.swift      point d'entrée, autorisation des notifications
├── Design/Theme.swift            palette et typographie
├── Model/
│   ├── Models.swift              ExerciseKind, Exercise, Reminder, ChallengeState…
│   ├── ChallengeStore.swift      source de vérité : jours, séries, persistance
│   └── Motivation.swift          tous les textes, déclinés par ton
├── Services/NotificationManager  programmation des rappels locaux
└── Views/                        Root, Today, Calendar, Settings, NewChallenge, Celebration
```

Les données sont persistées en JSON dans `UserDefaults` (clé `pompes.challenge.state.v2`) :
volume minuscule, aucune dépendance externe. Un défi enregistré par la première version
(un seul exercice, clé `…v1`) est repris automatiquement au lancement — l'historique de
pompes est conservé.

## Maquette

Les sources de la maquette (canvas Claude Design) sont dans `design/` :
un artboard `.dc.html` par écran, plus `canvas.json` pour la mise en page.
`AltClair.dc.html` est la variante claire, non retenue.

## Icône

`tools/make_app_icon.py` génère `PompesChallenge/Assets.xcassets/AppIcon.appiconset/AppIcon.png`
(1024×1024, RGB sans canal alpha comme l'exige iOS) : l'anneau de progression et l'étoile
du jour validé, sur le dégradé orange de l'app. Pour la régénérer après une retouche des
constantes en tête de fichier :

```
python3 tools/make_app_icon.py PompesChallenge/Assets.xcassets/AppIcon.appiconset/AppIcon.png
```

Le script n'a aucune dépendance : le rendu et l'encodage PNG sont faits à la main.

## Points connus

- Le projet n'est pas compilé dans l'environnement où il est écrit (pas de toolchain
  Swift) : la compilation se fait sur un Mac avec Xcode.
- La maquette utilise la police Archivo ; l'app utilise l'équivalent système
  (`.system(weight: .black)`) pour éviter d'embarquer une police.
