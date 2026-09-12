# Partager Budokai Ichi avec des amis (TestFlight)

TestFlight est le service d'Apple qui permet de distribuer une app **avant** (ou sans)
publication sur l'App Store. Tu obtiens un **lien public** à partager : la personne
installe l'app TestFlight depuis l'App Store, ouvre ton lien, et l'app s'installe.

## Ce qu'il faut savoir avant de commencer

| | |
|---|---|
| Testeurs | jusqu'à **10 000** via un lien public |
| Première mise en ligne | une **revue Apple** de 24 à 48 h, une seule fois |
| Durée de vie d'un build | **90 jours** — il faut en renvoyer un nouveau tous les 3 mois |
| Mises à jour | automatiques pour tes testeurs, sans revue supplémentaire |

Ces règles sont celles d'Apple et peuvent changer : vérifie sur
<https://developer.apple.com/testflight/> en cas de doute.

## 1. Créer l'app dans App Store Connect

1. <https://appstoreconnect.apple.com> → **Mes apps** → **+** → **Nouvelle app**.
2. Plateforme **iOS**, nom « Budokai Ichi », langue **Français**.
3. **Identifiant de bundle** : `com.franckmoyal.BudokaiIchi`. S'il n'apparaît pas dans
   la liste, crée-le d'abord dans *Certificates, Identifiers & Profiles* →
   **Identifiers** → **+** → *App IDs* → *App*.
4. SKU : ce que tu veux, par exemple `budokai-ichi`.

## 2. Envoyer un build depuis Xcode

1. Ouvre `BudokaiIchi.xcodeproj`.
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

## 3. Ouvrir le lien public

1. Dans App Store Connect → **TestFlight** → **Tests externes** → créer un groupe
   (ex. « Amis »).
2. Ajoute le build au groupe. **Renseigne « Informations sur les tests »** — description
   de ce qu'il faut tester et un e-mail de contact — c'est obligatoire pour la revue.
3. Envoie à la revue. Comptez 24 à 48 h pour le **premier** build seulement.
4. Une fois approuvé, active **Lien public** et copie l'URL. C'est ce lien que tu partages.

Tes amis : installer **TestFlight** depuis l'App Store, ouvrir ton lien, appuyer sur
**Accepter** puis **Installer**.

## 4. Envoyer une mise à jour

À chaque nouvelle version :

1. Dans Xcode, augmente **Build** (`CURRENT_PROJECT_VERSION`) — et **Version**
   (`MARKETING_VERSION`) si le changement est notable. Deux builds ne peuvent pas porter
   le même numéro.
2. **Product → Archive → Distribute → Upload**.
3. Dans App Store Connect, ajoute le nouveau build au groupe « Amis ».

Pas de nouvelle revue pour les mises à jour d'un groupe déjà approuvé : tes testeurs
reçoivent la notification dans les minutes qui suivent.

## L'autre app

Le défi 100 pompes se distribue séparément, sous son propre identifiant
`com.franckmoyal.PompesChallenge`, depuis le dossier `../defi-100-pompes/` — il a son guide
et un script d'envoi en une commande. **Ne jamais réunifier les deux identifiants** :
deux apps qui partagent le leur s'écrasent l'une l'autre à l'installation.
