# Deux apps, deux dossiers

Ce dépôt contient **deux applications iPhone séparées**. Elles sont nées du même
code, mais elles ont divergé : ce sont aujourd'hui deux produits distincts, qui
s'installent côte à côte sur le même téléphone.

| Dossier | App | Identifiant | Ce que c'est |
|---|---|---|---|
| `defi-100-pompes/` | 100 Pompes | `com.franckmoyal.PompesChallenge` | Le défi quotidien : compteur, calendrier, rappels |
| `budokai-ichi/` | Budokai Ichi | `com.franckmoyal.BudokaiIchi` | Le jeu : programmes d'animés, XP, rangs, déblocages |

## La règle

**Une conversation, une app, un dossier.** On ne travaille jamais sur les deux à
la fois. Chaque dossier a son propre `CLAUDE.md` : c'est lui qui fait autorité
pour l'app qu'il décrit.

Avant de modifier quoi que ce soit, vérifier dans quel dossier on est. Une
modification qui traverse les deux dossiers est presque toujours une erreur —
sauf quand elle porte sur ce fichier ou sur `netlify.toml`.

**Les deux identifiants doivent rester distincts.** Sur iOS, l'identifiant
désigne l'app *et* le coffre où elle range ses données. Deux apps qui partagent
le leur s'écrasent l'une l'autre à l'installation, et la seconde hérite des
données de la première. C'est arrivé une fois, volontairement, quand le jeu
devait remplacer le défi ; ce n'est plus le cas. Ne pas les réunifier.

## À qui on parle

Franck n'est pas développeur. Pas de jargon, pas d'explication technique non
demandée. Quand il y a quelque chose à faire de son côté : des étapes
numérotées, littérales, en français. Réponses en français.

## Deux environnements

Les sessions distantes (cloud) **ne peuvent pas compiler** : pas de macOS, pas
de Swift, pas de Xcode. Elles écrivent, committent, poussent. Seule une session
**locale sur le Mac** compile et installe sur l'iPhone.

À chaque changement de côté : `git pull` en arrivant, commit + push en partant.
Une session distante qui touche au code écrit du SwiftUI conservateur — elle ne
verra jamais l'erreur de compilation.

## Branches

Tout se passe sur `claude/100-pushups-challenge-app-0aj91w`, qui porte les deux
dossiers. La branche `v1-defi-100-pompes` est l'ancien emplacement du défi,
gardée comme archive : ne plus y travailler.

## Messages de commit

En français, à l'impératif, sujet court. Le corps explique le *pourquoi* quand
ce n'est pas évident. Préciser de quelle app il s'agit quand ce n'est pas clair
depuis les chemins de fichiers.
