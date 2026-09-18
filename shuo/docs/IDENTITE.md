# L'identité de Shuō

Direction **encre de Chine** : 说 calligraphié, un petit sceau cinabre, du
papier ivoire. Ni cercle ouvert ni disque rouge — ces deux motifs-là étaient
japonais (l'ensō vient de la calligraphie zen, le disque plein est le drapeau),
et une app de mandarin ne peut pas les porter.

Le tracé est **celui de la planche**, pas une reconstitution : la vraie
calligraphie, avec ses traits secs et ses attaques. Les fichiers d'origine sont
dans `identite-source/`.

## Comment on passe de la planche à l'app

`tools/preparer_marque.py` fait le travail :

```
python3 tools/preparer_marque.py identite-source
```

Il produit quatre fichiers :

| Fichier | Ce que c'est |
|---|---|
| `AppIcon.png` / `AppIcon-Dark.png` | L'icône, fond jusqu'au bord |
| `ShuoMark.imageset/mark-light.png` / `mark-dark.png` | La marque détourée, pour l'app |

**Ne pas retoucher ces quatre fichiers à la main** : ils se regénèrent.

### Ce que le script corrige, et pourquoi

1. **Les coins de la planche sont déjà arrondis**, avec une ombre portée, sur
   une page plus claire. iOS applique son propre masque : un coin arrondi dans
   un coin arrondi se voit tout de suite, avec un liseré tout autour.
2. **Le sceau touche le bord droit** (x = 996 sur 1024). Le masque d'iOS rogne
   les angles : le sceau y perdrait un coin. La marque est donc réduite à 80 %
   de l'icône.
3. **Le fichier sombre livré est inexploitable** : c'est un agrandissement
   d'une vignette de la planche — flou, mal cadré, avec la tuile voisine
   visible sur la gauche. La version sombre est reconstruite depuis la planche
   claire, qui est nette : l'encre devient crème, le sceau garde son cinabre.

Le détourage retrouve l'opacité réelle de chaque pixel en « démélangeant » ce
qui a été peint sur l'ivoire. Deux conséquences utiles : le halo clair laissé
par l'agrandissement de la planche disparaît tout seul, et le grain du papier,
qui ressort en opacités très faibles, est planché à zéro.

Le **caractère réservé du sceau** demande un traitement à part. Il est de la
couleur du papier : détouré tel quel, il deviendrait un trou — invisible sur
l'ivoire de l'app, béant sur fond sombre. Le script remplit donc chaque ligne
du sceau entre son premier et son dernier pixel rouge, ce qui rend le caractère
sans abîmer les angles arrondis.

## Dans l'app

| Vue | Ce que c'est |
|---|---|
| `ShuoMark` | La marque. Une image, deux versions, le catalogue bascule seul. |
| `HorizontalLogo` | La marque, le nom, la signature, sur une ligne. |
| `InkColumn` | La colonne chinoise et son filet, sur l'écran de lancement. |

À l'ouverture, la marque **infuse** : elle arrive floue et se resserre, comme de
l'encre qui prend. C'est la seule animation qui aille avec un tracé au pinceau —
la faire mine de se dessiner toute seule sonnerait faux, puisque c'est une image
et non un trait calculé.

## La palette

| Rôle | Clair | Sombre |
|---|---|---|
| Papier | `#F4F0E8` | `#121110` |
| Encre | `#1A1917` | `#F3EEE3` |
| Cinabre | `#C81D1E` | `#D8322F` |

## Les mots

- **Shuō** — en romain, jamais en capitales.
- **Parlez chinois.** — le point final fait partie de la signature : c'est une
  phrase, pas une étiquette. Lettres espacées.
- **更近的世界** — « un monde plus proche ». En colonne, contre le bord gauche,
  sur l'écran de lancement seulement.

## Ce qui manque encore

La planche comporte un paysage à l'encre — montagnes, pavillon, pin, bateau —
qui occupe le tiers bas de l'écran d'ouverture. Il n'est **pas** dans l'app.

Ces éléments sont livrés en découpes de la planche de contact, entre 150 et 525
pixels de large ; `06_montagnes_encre.png` porte même le titre de la planche en
haut. Un écran d'iPhone en demande trois fois plus. Les agrandir donnerait une
bouillie, et le README de la livraison le dit lui-même : *« les masters devront
être régénérés/exportés nativement, plutôt qu'agrandis depuis la planche »*.

Il faudrait, en pleine résolution :

- le **paysage** (≥ 1200 px de large), pour le bas de l'écran de lancement ;
- le **logo horizontal**, aujourd'hui composé en texte ;
- une **icône sombre** exportée nativement, plutôt que reconstruite.

Rien de tout cela ne manque au fonctionnement de l'app.
