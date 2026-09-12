# Budokai Ichi

武道会一 — jeu de progression sportive. Des programmes d'entraînement tirés
d'animés japonais, de l'expérience, des rangs, des caractéristiques et des
déblocages.

L'app est née d'un défi « 100 pompes par jour pendant 30 jours ». Cette
première version reste entière sur la branche **`v1-defi-100-pompes`** ; le
défi lui-même est devenu le programme *Saitama*.

## Ouvrir le projet

```
open BudokaiIchi.xcodeproj
```

Xcode 16 ou plus récent, iOS 17 minimum, iPhone, portrait. Le groupe de fichiers
est synchronisé avec le système de fichiers : ajouter un fichier dans
`BudokaiIchi/` suffit, sans passer par le `.pbxproj`.

L'identifiant de bundle **n'a pas changé** (`com.franckmoyal.PompesChallenge`).
C'est voulu : l'app installée se met à jour au lieu de se dédoubler, et les
répétitions déjà faites dans « 100 Pompes » sont reprises comme expérience de
départ.

## Où en est le projet

**Le moteur de jeu est écrit, avec deux programmes jouables.** Les sept autres
figurent au catalogue, verrouillés, avec leur condition d'ouverture — ils
existent pour qu'on voie où l'on va.

| Programme | Famille | Contenu |
|---|---|---|
| **Saitama** | Transformation physique | 84 séances quotidiennes, 8 étapes |
| **Naruto** | Résilience | 27 sorties sur 9 semaines, 5 étapes |
| Rock Lee · Kenshiro · Ichigo · Minato · Levi · Luffy · Goku | — | contenu à écrire |

## Le moteur

**L'expérience** vient de cinq sources : la séance terminée (100 XP × le palier
de calibrage), le dépassement de l'objectif (1 XP par répétition en plus,
plafonné à 50), le record personnel (150), le multiplicateur de série (×1 à
×1,5), et les franchissements — 850 XP par étape, 1 500 par programme bouclé.
Le niveau *n* demande `250 × n^1,6` XP cumulés.

**Les rangs** vont de E à S+, chacun attaché à un palier de niveau. **Trois
caractéristiques** — Force, Vitesse, Endurance — montent bien plus lentement que
l'XP et conditionnent les déblocages : « Force 30 requise » devant un programme
dit quoi travailler, là où un niveau global ne dit rien.

**Une séance manquée ne casse pas la série.** Elle ouvre une quête de pénalité,
calibrée sur le rang, à accomplir avant minuit : accomplie, la série est sauvée ;
ignorée, elle tombe. Le mécanisme vient de *Solo Leveling* et vaut mieux qu'une
sanction sèche — il transforme l'échec en rattrapage.

Tout cela est dans `Model/GameEngine.swift`, en fonctions pures : la courbe se
règle sans toucher au reste de l'app.

## Organisation

```
BudokaiIchi/
├── BudokaiIchiApp.swift
├── Design/Theme.swift            palette clair/sombre, rangs, typographie
├── Model/
│   ├── Program.swift             rangs, paliers, étapes de séance, programmes
│   ├── Content.swift             le catalogue et les deux programmes jouables
│   ├── PlayerState.swift         ce qui est conservé d'une ouverture à l'autre
│   ├── GameEngine.swift          les règles, sans état
│   ├── GameStore.swift           source de vérité, persistance, reprise de v1
│   └── Motivation.swift          les textes, déclinés par ton
├── Services/NotificationManager  rappels sur fenêtre glissante de 20 jours
└── Views/                        Root, Today, GuidedSession, Outcome, Penalty,
                                  Programs, ProgramDetail, Profile, Settings,
                                  Onboarding, Components
```

L'état tient dans `UserDefaults` sous `budokai.player.v1`.

## Ce qui reste

- Le contenu sportif des sept autres programmes.
- Le test de forme à l'inscription : pour l'instant une simple déclaration
  — je reprends / je suis actif / je m'entraîne déjà — calibre les charges.
- Le réglage de la courbe d'XP et des seuils de caractéristiques, sur des
  chiffres d'usage réels. Aucun équilibrage ne tombe juste du premier coup.

## Maquette et cadrage

- `docs/cadrage-budokai-chi.html` — le cahier des charges complet.
- `design-v2/` — les artboards de la maquette et les fonds d'univers.
- `design-v2/images/` — une image par programme, remplaçable (voir son README).

## Outils

```
python3 tools/make_budokai_icon.py BudokaiIchi/Assets.xcassets/AppIcon.appiconset/AppIcon.png
python3 tools/fetch_universes.py
```

Aucune dépendance : le rendu d'image et l'encodage PNG sont écrits à la main.
