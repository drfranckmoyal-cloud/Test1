# 100 Pompes Challenge — version web

La même app, en page web : compteur, calendrier, création de défi, quatre tons de
motivation, thème clair/sombre. Tout est stocké **dans le navigateur** du visiteur
(`localStorage`) — aucune donnée n'est envoyée nulle part, et chacun a son propre défi.

## La différence avec l'app iPhone

**Les rappels automatiques ne marchent pas.** iOS ne permet pas à une page web de
programmer des notifications à heure fixe. L'écran Réglages affiche les trois créneaux
avec la répartition des répétitions, à mettre en alarme dans l'app Horloge.

Tout le reste est identique, y compris les phrases de motivation absurdes.

## Mettre en ligne

Le dossier est un site statique : n'importe quel hébergeur convient.

- **Netlify** : glisser-déposer le dossier `web/` sur <https://app.netlify.com/drop>.
- **Ligne de commande** : `netlify deploy --dir web --prod`.

Aucune étape de compilation, aucune dépendance.

## Installer sur l'écran d'accueil

Sur iPhone, ouvrir le lien dans **Safari** (pas Chrome), bouton **Partager**, puis
**Sur l'écran d'accueil**. L'app s'ouvre alors en plein écran avec son icône, et
fonctionne hors connexion grâce au service worker.

## Fichiers

```
index.html            structure et styles (palette clair/sombre en variables CSS)
app.js                état, calculs, écrans, textes de motivation
manifest.webmanifest  nom, icônes, couleurs pour l'écran d'accueil
sw.js                 cache hors ligne
icon-*.png            icônes, produites par tools/make_app_icon.py
```
