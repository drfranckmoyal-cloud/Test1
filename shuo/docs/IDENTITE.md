# L'identité de Shuō

La planche d'identité tient en trois éléments : un cercle tracé au pinceau, un
disque rouge, et 说. Tout le reste — le nom, la signature, le sceau — se pose
autour.

## Où elle vit dans le code

L'identité n'est **pas** une collection d'images. Elle est dessinée, en
vectoriel, dans `Shuo/Views/BrandMarks.swift` :

| Vue | Ce que c'est |
|---|---|
| `EnsoShape` | Le cercle au pinceau. Une forme pleine, pas un contour. |
| `SunMark` | Le disque rouge. |
| `SealMark` | Le sceau carré, caractère réservé en clair. |
| `ShuoMark` | Les trois ensemble : cercle + disque + caractère. |
| `HorizontalLogo` | La marque, le nom, la signature, sur une ligne. |

Deux raisons de la dessiner plutôt que de l'importer : elle est nette à
n'importe quelle taille, et elle bascule toute seule entre le thème clair et le
thème sombre. Une image ne fait ni l'un ni l'autre.

`tools/make_app_icon.py` reprend exactement la même géométrie pour fabriquer
l'icône. **Si l'une des deux change, changer l'autre** — les constantes portent
les mêmes noms et les mêmes valeurs des deux côtés.

## Le cercle

Ce n'est pas `Circle().stroke`. Un trait d'épaisseur constante se voit tout de
suite : il a l'air fait au compas. Ici le pinceau attaque fin en haut à droite,
s'épaissit dans le virage, puis s'efface — et le rayon tremble très légèrement,
d'un treizième de l'épaisseur, ce qui suffit à faire une main.

Le trait se **trace** à l'ouverture de l'app, en une seconde et demie. C'est le
geste qui fait la marque, pas la forme finale. L'animation passe par `progress`
et `animatableData`, pas par un `trim` : la forme étant pleine, la tronquer
donnerait une tache qui grandit au lieu d'un trait qui avance.

## La palette

| Rôle | Clair | Sombre |
|---|---|---|
| Papier | `#F5F0E6` | `#121110` |
| Encre | `#1A1917` | `#F3EEE3` |
| Rouge | `#CC2E26` | `#DE4438` |
| Bord du rouge | `#A81F18` | `#B8291F` |

Le disque rouge est plat sur 90 % de son rayon : seul le bord fonce, là où le
pigment s'accumule en séchant. Un dégradé plus marqué donnerait une bille en
trois dimensions, ce qui n'a rien à faire sur une planche à l'encre.

## Les mots

- **Shuō** — en romain, jamais en capitales.
- **Parlez chinois.** — le point final fait partie de la signature : c'est une
  phrase, pas une étiquette. Lettres espacées.
- **更近的世界** — « un monde plus proche ». En colonne, contre le bord gauche,
  sur l'écran de lancement seulement.

## La police du caractère

L'app utilise la police système, qui sait rendre les hanzi partout. Le
générateur d'icône, lui, cherche dans l'ordre : Songti, PingFang, Hei (macOS),
puis WenQuanYi et Noto CJK (Linux). **L'icône doit être régénérée sur le Mac** :
une session distante n'a que WenQuanYi, un sans-serif maigre, là où Songti donne
le trait plein de la planche.

```
python3 tools/make_app_icon.py
```

Sans argument, le script écrit les deux icônes à leur place dans le catalogue.

## Ce qui manque encore

La planche d'origine comporte des éléments que ce dépôt n'a pas reçus en
fichiers, seulement en planche de contact — donc trop petits pour servir :

- le paysage à l'encre (`22_wallpaper`, `23_wallpaper_vertical`) ;
- la calligraphie au pinceau de 说 (`24_calligraphie`), plus vivante que le
  rendu de la police système.

Le paysage n'est pas nécessaire : le dossier demande un écran de lancement
sobre, centré sur le caractère. La calligraphie, en revanche, améliorerait
nettement la marque. Déposer le PNG à fond transparent dans
`Shuo/Assets.xcassets/` et remplacer le `Text("说")` de `ShuoMark`.
