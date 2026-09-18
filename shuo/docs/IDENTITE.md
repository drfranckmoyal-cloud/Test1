# L'identité de Shuō

Trois éléments : un cercle tracé au pinceau, un disque rouge, et 说. Le nom et
la signature se posent autour.

Le tracé est **celui d'origine**, pas une reconstitution : le grain du pinceau,
les traits secs du cercle, la matière du disque rouge. Il vient des PNG livrés,
rangés dans `identite-source/`.

## Comment on passe des fichiers d'origine à l'app

Les fichiers livrés ne sont pas utilisables tels quels sur iOS, pour deux
raisons :

1. **Leurs coins sont déjà arrondis**, sur un fond gris clair. iOS applique son
   propre masque : un coin arrondi dans un coin arrondi se voit tout de suite,
   avec un liseré autour de l'icône.
2. **Le mot « Shuō » est dedans.** À 40 px c'est une tache illisible, et iOS
   écrit déjà le nom sous l'icône.

`tools/preparer_marque.py` s'en occupe :

```
python3 tools/preparer_marque.py identite-source
```

Il découpe la marque seule, retire le fond en retrouvant l'opacité réelle de
chaque pixel, puis écrit quatre fichiers :

| Fichier | Ce que c'est |
|---|---|
| `AppIcon.png` / `AppIcon-Dark.png` | L'icône, fond jusqu'au bord, sans le mot |
| `ShuoMark.imageset/mark-light.png` / `mark-dark.png` | La marque détourée, pour l'app |

La marque est reposée sur un fond uni plutôt que recollée avec son rectangle de
papier : le grain ne se raccorde jamais exactement, et la couture se verrait
comme une bande en haut et en bas de l'icône.

## Dans l'app

| Vue | Ce que c'est |
|---|---|
| `ShuoMark` | La marque. Une image, deux versions, le catalogue bascule seul. |
| `SealMark` | Le sceau carré. Dessiné, lui : trop petit pour qu'une image y gagne. |
| `HorizontalLogo` | La marque, le nom, la signature, sur une ligne. |

Le catalogue porte les deux versions de la marque, encre sur papier et encre
claire sur fond sombre, sous le même nom. `Image("ShuoMark")` prend la bonne
sans qu'on ait à le demander.

À l'ouverture, la marque **infuse** : elle arrive floue et se resserre, comme de
l'encre qui prend. C'est la seule animation qui aille avec un tracé au pinceau —
la faire mine de se dessiner toute seule sonnerait faux, puisque c'est une image
et non un trait calculé.

## La palette

| Rôle | Clair | Sombre |
|---|---|---|
| Papier | `#F5F0E6` | `#121110` |
| Encre | `#1A1917` | `#F3EEE3` |
| Rouge | `#CC2E26` | `#DE4438` |

## Les mots

- **Shuō** — en romain, jamais en capitales.
- **Parlez chinois.** — le point final fait partie de la signature : c'est une
  phrase, pas une étiquette. Lettres espacées.
- **更近的世界** — « un monde plus proche ». En colonne, contre le bord gauche,
  sur l'écran de lancement seulement.

## Ce qui n'a pas servi

`identite-source/` contient aussi le paysage à l'encre, le logo horizontal et la
calligraphie isolée, mais **en vignettes** : entre 150 et 450 pixels de large,
soit trop peu pour un écran d'iPhone, qui en demande trois fois plus. Ils sont
gardés comme référence, pas comme matière.

Si les versions pleine résolution arrivent un jour :

- le **paysage** irait en fond d'écran de lancement, sous la marque ;
- le **logo horizontal** remplacerait `HorizontalLogo`, aujourd'hui composé en
  texte.

Rien de tout cela ne manque au fonctionnement de l'app.
