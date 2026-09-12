# Images de fond des programmes

L'app cherche ici une image par programme. **Si le fichier existe, il s'affiche ;
s'il est absent, le fond graphique dessiné en CSS prend le relais.** Rien ne casse
dans un cas comme dans l'autre — tu peux en déposer une, huit, ou aucune, et en
changer quand tu veux sans toucher au code.

**Les neuf fichiers sont déjà là**, composés à partir d'estampes japonaises du
domaine public traitées dans la palette de chaque programme — voir `CREDITS.md`.
Déposer un fichier du même nom remplace celui d'origine.

## Les neuf fichiers attendus

| Fichier | Programme | Dominantes de la palette |
|---|---|---|
| `saitama.jpg` | Transformation physique | jaune `#F5C518` · rouge `#D6202A` |
| `goku.jpg` | Progression extrême | orange `#FF6B00` · bleu `#1B6CA8` |
| `rocklee.jpg` | Explosivité | vert `#1E8449` · orange `#F5B041` |
| `kenshiro.jpg` | Force pure | rouge sombre `#8B1A1A` · or `#E0B44A` |
| `ichigo.jpg` | Objectifs | noir `#1A1A1A` · rouge `#C0392B` |
| `minato.jpg` | Vitesse | jaune `#F5D547` · bleu `#2C4A8C` |
| `levi.jpg` | Gainage | vert-de-gris `#4A5D4E` · blanc `#D8D3C8` |
| `luffy.jpg` | Souplesse | rouge `#D62828` · jaune `#F6C453` |
| `naruto.jpg` | Résilience | orange `#F47B20` · bleu `#0E2340` |

Les noms doivent être exactement ceux-là, en minuscules. `.jpg` ou `.png`,
les deux fonctionnent.

## Le format

- **1170 × 1560 pixels minimum** — c'est la zone haute de la fiche de programme
  sur un iPhone en densité ×3. Plus grand passe, plus petit pixellise.
- **Portrait**, jamais paysage.
- **Le sujet dans le tiers supérieur.** La moitié basse disparaît sous un dégradé
  vers le noir et sous le titre du programme : ce qui y est placé ne se verra pas.
- **Moins de 800 Ko par fichier.** Au-delà, l'app démarre plus lentement pour un
  gain visuel nul.

## Où l'image apparaît

1. **La tuile** sur la carte des programmes — recadrage carré du haut de l'image.
2. **La fiche du programme** — bandeau haut, sous un dégradé qui assure la
   lisibilité du titre par-dessus.

L'image ne sert jamais de fond à un écran de séance : pendant l'entraînement,
les chiffres doivent rester lisibles sans effort.

## Recadrer sans logiciel

Sur Mac, Aperçu suffit : ouvrir l'image, `Outils → Ajuster la taille`, largeur
1170 px, puis `Outils → Rogner` sur un rapport 3:4. Enregistrer sous le nom
attendu, déposer ici, `git add` et `git push`.
