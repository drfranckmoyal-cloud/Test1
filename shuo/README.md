# Shuō / 说

**Parlez chinois.**

Un tuteur de mandarin qui parle, écoute et corrige. La colonne vertébrale est le
programme officiel **HSK 3.0 niveau 1** — 300 mots, 15 thèmes — mais l'app
l'enseigne à l'oral : écouter, dire, se faire reprendre sur les tons.

`com.franckmoyal.Shuo`

## Ce qu'une séance fait

On choisit 5, 10, 15 ou 20 minutes. La séance reprend d'abord ce qui a coincé la
fois d'avant, rappelle quelques mots tirés de **tout** l'historique, puis
introduit **un à trois mots nouveaux au maximum** — jamais plus, même si on a le
temps. Chaque mot suit le même chemin : la carte, le sens, le modèle audio, une
tentative sans être interrompu, la correction après coup, un premier emploi, un
deuxième contexte, puis du réemploi de plus en plus libre. Les deux dernières
minutes récapitulent, sans rien ajouter.

Le tuteur change à chaque séance — quatre, avec leur voix et leur nom chinois.
La pédagogie, elle, ne change pas.

## Ce qui décide qu'un mot est acquis

Pas le tuteur. Un mot passe au vert quand les preuves s'accumulent : une
prononciation et des tons très bons, cinq productions correctes, et au moins
trois rappels réussis sur des **séances différentes**. Un mot compris mais mal
prononcé reste orange, même si la machine l'a parfaitement reconnu. Un échec
isolé ne fait jamais redescendre un vert ; des échecs répétés, sur des séances
séparées, oui.

La force de mémoire de chaque mot décroît toute seule. Un acquis d'il y a trois
semaines redevient fragile et ressort en révision, sans qu'on ait rien demandé.

## Parler

Deux modes, échangeables en pleine séance : mains libres, ou appui pour parler.
En mains libres, parler coupe le tuteur sur-le-champ — pas à la fin de sa phrase.

Trois mots à dire quand ça coince :

- **« aide »** — le tuteur demande d'abord ce qui bloque, puis aide par paliers ;
- **« réponse »** — la solution tout de suite, puis il faut la réutiliser ;
- **« arrête-toi »** — retour au mode guidé.

## Ce qu'il y a sous le capot

Le programme, les révisions et les statuts sont calculés sur l'iPhone. Le modèle
de langue ne sert qu'à tenir la conversation et à corriger : il propose des
observations, il ne décide d'aucun statut. Sans clé d'API ou sans réseau, un
tuteur local prend le relais et la séance continue, en moins souple.

Le nom du modèle qui parle réellement est affiché en permanence. Le mode
développeur montre la latence, les jetons et le coût, avec une cible d'environ
1,25 €/h — une alerte, pas une coupure.

## Les fichiers

- `Shuo/` — l'app
- `Shuo/Content/` — le contenu embarqué : 300 mots, 155 entrées de programme, 15 modules
- `handoff/` — le dossier de livraison V2, tel qu'il est arrivé ; il fait autorité
- `docs/TESTS_ACCEPTATION.md` — les 18 tests du dossier et où ils vivent dans le code
- `docs/IDENTITE.md` — la marque : le cercle, le disque, la palette, les mots
- `identite-source/` — la planche d'identité, à l'encre
- `tools/preparer_marque.py` — en tire l'icône et la marque détourée

## Droits

L'app utilise le programme officiel HSK comme **périmètre**, et les métadonnées
publiques du manuel 2026 autorisé pour situer l'arc pédagogique. Elle ne
reproduit aucun dialogue, texte ni exercice de manuel : toutes les phrases
d'exemple et tous les dialogues de Shuō sont originaux.

Avant toute diffusion commerciale, les 300 phrases d'exemple demandent une
relecture éditoriale par un locuteur natif. C'est une porte de qualité, pas un
trou dans le périmètre.
