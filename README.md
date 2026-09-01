# 100 Pompes Challenge

Application iPhone de motivation pour le défi **100 pompes par jour pendant 30 jours**.

Chaque journée court **de minuit à minuit** : le total est enregistré sous la date locale
du jour, donc le compteur repart de zéro tout seul au changement de date, et le jour est
validé ou manqué définitivement.

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
| **Aujourd'hui** | Anneau de progression du jour, boutons d'ajout rapide (+1 / +5 / +10 / +20), saisie d'un total exact, message de motivation, barre des 30 jours. |
| **Calendrier** | Les 30 jours du défi : étoile orange si validé, case grise si manqué, contour orange et pourcentage sur le jour en cours, gris éteint pour les jours à venir. Toucher un jour passé permet de corriger son total. Série en cours, meilleure série et total de pompes en bas. |
| **Rappels** | Les trois rappels quotidiens (heure, activation), le ton des messages, l'objectif quotidien, et la possibilité de recommencer le défi. |
| **Célébration** | Plein écran orange à l'instant où l'objectif du jour est atteint : jour validé, série, total, semaine en étoiles. Affiché une seule fois par jour. |

## Rappels

Trois notifications locales répétées tous les jours (07:30, 13:00, 20:30 par défaut),
reprogrammées à chaque modification d'horaire, d'objectif ou de ton. L'objectif quotidien
est réparti sur les trois créneaux (30 % / 35 % / 35 %). Si les notifications sont
refusées au niveau du système, l'écran Rappels affiche un bandeau et un raccourci vers les
réglages iOS.

Trois tons de message sont disponibles — **Cash**, **Coach**, **Zen** — et s'appliquent
aussi bien aux notifications qu'aux textes affichés dans l'app.

## Organisation du code

```
PompesChallenge/
├── PompesChallengeApp.swift      point d'entrée, autorisation des notifications
├── Design/Theme.swift            palette et typographie
├── Model/
│   ├── Models.swift              Reminder, DayCell, ChallengeState…
│   ├── ChallengeStore.swift      source de vérité : jours, séries, persistance
│   └── Motivation.swift          tous les textes, déclinés par ton
├── Services/NotificationManager  programmation des rappels locaux
└── Views/                        Root, Today, Calendar, Reminders, Celebration
```

Les données sont persistées en JSON dans `UserDefaults` (clé `pompes.challenge.state.v1`) :
volume minuscule, aucune dépendance externe.

## Maquette

Les sources de la maquette (canvas Claude Design) sont dans `design/` :
un artboard `.dc.html` par écran, plus `canvas.json` pour la mise en page.
`AltClair.dc.html` est la variante claire, non retenue.

## Points connus

- Le projet n'a pas pu être compilé dans l'environnement où il a été écrit (pas de
  toolchain Swift) : une première ouverture dans Xcode reste à faire.
- L'icône d'application est un emplacement vide dans `Assets.xcassets` — il reste à
  fournir un PNG 1024×1024.
- La maquette utilise la police Archivo ; l'app utilise l'équivalent système
  (`.system(weight: .black)`) pour éviter d'embarquer une police.
