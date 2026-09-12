# Partager le 100 Pompes avec des amis (TestFlight)

TestFlight est le service d'Apple qui permet de distribuer une app **avant** (ou sans)
publication sur l'App Store. Tu obtiens un **lien public** à partager : la personne
installe l'app TestFlight depuis l'App Store, ouvre ton lien, et l'app s'installe.

## Deux apps, deux identités

Ce dépôt contient deux apps issues du même projet :

| | Identifiant | Nom affiché | Branche |
|---|---|---|---|
| Le défi 100 pompes | `com.franckmoyal.PompesChallenge` | 100 Pompes | `v1-defi-100-pompes` |
| Le jeu | `com.franckmoyal.BudokaiIchi` | Budokai Ichi | `claude/100-pushups-challenge-app-0aj91w` |

L'identifiant — pas le nom — est ce qui définit une app pour Apple, et c'est lui qui
désigne le coffre où l'app range ses données sur le téléphone.

Le défi garde `com.franckmoyal.PompesChallenge`, le sien depuis le premier jour : c'est
ce qui lui rend tout son historique — calendrier, séries, records. Budokai Ichi, qui avait
un temps pris cet identifiant pour remplacer le défi, a désormais le sien.

**Ne jamais les réunifier.** Deux apps qui partagent un identifiant s'écrasent l'une
l'autre à l'installation, chez toi comme chez tes testeurs.

## Ce qu'il faut savoir

| | |
|---|---|
| Testeurs | jusqu'à **10 000** via un lien public |
| Première mise en ligne | une **revue Apple** de 24 à 48 h, une seule fois |
| Durée de vie d'un build | **90 jours** — il faut en renvoyer un nouveau tous les 3 mois |
| Mises à jour | automatiques pour tes testeurs, sans revue supplémentaire |

Ces règles sont celles d'Apple et peuvent changer : vérifie sur
<https://developer.apple.com/testflight/> en cas de doute.

## 1. Créer la fiche dans App Store Connect

Une fiche par app. Celle-ci est **nouvelle** : ne réutilise pas celle de Budokai Ichi.

1. <https://appstoreconnect.apple.com> → **Mes apps** → **+** → **Nouvelle app**.
2. Plateforme **iOS**, nom « 100 Pompes Challenge », langue **Français**.
3. **Identifiant de bundle** : `com.franckmoyal.PompesChallenge`. S'il n'apparaît pas dans la
   liste, c'est qu'il n'existe pas encore côté Apple — va le créer dans
   *Certificates, Identifiers & Profiles* → **Identifiers** → **+** → *App IDs* → *App*,
   puis reviens.
4. SKU : ce que tu veux, par exemple `defi-pompes`.

## 2. Envoyer un build — en une commande

Depuis un Mac, sur la branche `v1-defi-100-pompes` :

```
./tools/envoie-testflight.sh
```

Le script vérifie l'identifiant de l'app, incrémente le numéro de build, archive,
exporte et transmet à App Store Connect. Pour un premier passage sans rien envoyer :

```
./tools/envoie-testflight.sh --essai
```

Il s'arrête de lui-même si l'identifiant n'est pas `com.franckmoyal.PompesChallenge` —
archiver depuis l'autre branche enverrait Budokai Ichi sous l'identité du défi, et les
deux apps s'écraseraient.

Il utilise par défaut le compte Apple connecté dans Xcode. Pour un envoi sans aucune
interaction, renseigne une clé d'API App Store Connect (le script explique comment en
tête de fichier).

Après l'envoi, le numéro de build a changé dans le projet : le script rappelle de le
committer.

## 3. Envoyer un build à la main (si le script échoue)

Les mêmes étapes, dans l'interface de Xcode.

1. Place-toi sur la branche `v1-defi-100-pompes`, puis ouvre
   `PompesChallenge.xcodeproj`. Depuis l'autre branche tu archiverais Budokai Ichi
   sans t'en rendre compte.
2. Onglet **Signing & Capabilities** : ton équipe est sélectionnée, *Automatically manage
   signing* est coché.
3. En haut de la fenêtre, choisis la destination **Any iOS Device (arm64)** — pas un
   simulateur, sinon l'archive est impossible.
4. Menu **Product → Archive**. La fenêtre *Organizer* s'ouvre à la fin.
5. **Distribute App** → **TestFlight & App Store** → **Upload**. Laisse les options par
   défaut et valide.
6. Le build apparaît dans App Store Connect au bout de 5 à 20 minutes (onglet
   **TestFlight**), d'abord en « En cours de traitement ».

Le projet déclare déjà `ITSAppUsesNonExemptEncryption = NO` : l'app n'utilise aucun
chiffrement soumis à restriction, donc App Store Connect ne te posera pas la question de
conformité à l'exportation à chaque envoi.

## 4. Ouvrir le lien public

1. Dans App Store Connect → **TestFlight** → **Tests externes** → créer un groupe
   (ex. « Amis »).
2. Ajoute le build au groupe. **Renseigne « Informations sur les tests »** — description
   de ce qu'il faut tester et un e-mail de contact — c'est obligatoire pour la revue.
3. Envoie à la revue. Comptez 24 à 48 h pour le **premier** build seulement.
4. Une fois approuvé, active **Lien public** et copie l'URL. C'est ce lien que tu partages.

Tes amis : installer **TestFlight** depuis l'App Store, ouvrir ton lien, appuyer sur
**Accepter** puis **Installer**.

## 5. Envoyer une mise à jour

À chaque nouvelle version :

1. `./tools/envoie-testflight.sh` — le numéro de build s'incrémente tout seul.
   Augmente **Version** (`MARKETING_VERSION`) à la main si le changement est notable.
2. Dans App Store Connect, ajoute le nouveau build au groupe « Amis ».

Pas de nouvelle revue pour les mises à jour d'un groupe déjà approuvé : tes testeurs
reçoivent la notification dans les minutes qui suivent.

## La version web, en complément

Le dossier `web/` contient la même app en version site, publiée sur
<https://defi-100-pompes.netlify.app> — elle s'ajoute à l'écran d'accueil depuis Safari,
sans TestFlight et sans rien installer. Pratique pour quelqu'un qui veut juste essayer :
tout y est sauf les rappels automatiques, qu'iOS n'autorise pas hors d'une vraie app.
Voir `web/README.md`.
