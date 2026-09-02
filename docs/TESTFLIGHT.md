# Partager l'app avec des amis (TestFlight)

TestFlight est le service d'Apple qui permet de distribuer une app **avant** (ou sans)
publication sur l'App Store. Tu obtiens un **lien public** à partager : la personne
installe l'app TestFlight depuis l'App Store, ouvre ton lien, et l'app s'installe.

## Ce qu'il faut savoir avant de commencer

| | |
|---|---|
| Coût | **99 € / an** (Apple Developer Program) |
| Testeurs | jusqu'à **10 000** via un lien public |
| Première mise en ligne | une **revue Apple** de 24 à 48 h, une seule fois |
| Durée de vie d'un build | **90 jours** — il faut en renvoyer un nouveau tous les 3 mois |
| Mises à jour | automatiques pour tes testeurs, sans revue supplémentaire |

Ces règles sont celles d'Apple et peuvent changer : vérifie sur
<https://developer.apple.com/testflight/> en cas de doute.

## 1. Compte développeur

1. <https://developer.apple.com/programs/> → **Enroll**.
2. Choisis **Individual** : c'est immédiat. *Organization* demande un numéro D-U-N-S et
   plusieurs jours de vérification — inutile ici, sauf si tu veux que le nom de CEMEDIS
   apparaisse comme éditeur.
3. Paie les 99 €. L'accès est actif en quelques heures à un jour.

## 2. Créer l'app dans App Store Connect

1. <https://appstoreconnect.apple.com> → **Mes apps** → **+** → **Nouvelle app**.
2. Plateforme **iOS**, nom (ex. « 100 Pompes Challenge »), langue **Français**.
3. **Identifiant de bundle** : il doit être identique à celui du projet Xcode. Le projet
   utilise `com.franckmoyal.PompesChallenge` — garde-le, ou change-le des deux côtés.
4. SKU : ce que tu veux, par exemple `pompes-challenge`.

## 3. Envoyer un build depuis Xcode

1. Ouvre `PompesChallenge.xcodeproj`.
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

1. Dans Xcode, augmente **Build** (`CURRENT_PROJECT_VERSION`) — et **Version**
   (`MARKETING_VERSION`) si le changement est notable. Deux builds ne peuvent pas porter
   le même numéro.
2. **Product → Archive → Distribute → Upload**.
3. Dans App Store Connect, ajoute le nouveau build au groupe « Amis ».

Pas de nouvelle revue pour les mises à jour d'un groupe déjà approuvé : tes testeurs
reçoivent la notification dans les minutes qui suivent.

## Si tu ne veux pas payer

La version web dans `web/` fait presque tout — compteur, calendrier, motivation, thèmes —
et s'ajoute à l'écran d'accueil depuis Safari. Seuls les rappels automatiques manquent :
iOS ne les autorise pas hors d'une vraie app. Voir `web/README.md`.
