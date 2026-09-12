#!/bin/bash
#
# Envoie le défi 100 pompes sur TestFlight, en une commande.
#
#   ./tools/envoie-testflight.sh              archive et envoie
#   ./tools/envoie-testflight.sh --essai      archive seulement, sans envoyer
#
# À lancer depuis un Mac avec Xcode. Le script s'occupe de tout : il incrémente
# le numéro de build (deux envois ne peuvent pas porter le même), archive,
# exporte et transmet à App Store Connect.
#
# Authentification — deux possibilités :
#
#   1. Rien à faire, si ton compte Apple est connecté dans Xcode
#      (Xcode → Settings → Accounts). Le script utilise ce compte.
#
#   2. Une clé d'API App Store Connect, pour un envoi sans interaction.
#      Crée-la sur appstoreconnect.apple.com → Utilisateurs et accès → Intégrations,
#      télécharge le fichier .p8, puis :
#
#        export ASC_KEY_PATH=~/chemin/vers/AuthKey_XXXXXXX.p8
#        export ASC_KEY_ID=XXXXXXX
#        export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#
set -euo pipefail

cd "$(dirname "$0")/.."

PROJET="PompesChallenge.xcodeproj"
SCHEME="PompesChallenge"
EQUIPE="A7H8D53DKZ"
BUNDLE="com.franckmoyal.DefiPompes"
TRAVAIL="build"
ARCHIVE="$TRAVAIL/$SCHEME.xcarchive"

ESSAI=0
[ "${1:-}" = "--essai" ] && ESSAI=1

echo "▸ Vérifications"

if ! command -v xcodebuild >/dev/null; then
    echo "  ✗ xcodebuild est introuvable. Installe Xcode depuis le Mac App Store," >&2
    echo "    ouvre-le une fois, puis réessaie." >&2
    exit 1
fi

if [ ! -d "$PROJET" ]; then
    echo "  ✗ $PROJET est introuvable. Tu n'es pas sur la bonne branche :" >&2
    echo "    git checkout v1-defi-100-pompes" >&2
    exit 1
fi

# Le garde-fou qui compte : archiver depuis l'autre branche enverrait Budokai
# Ichi sous l'identifiant du défi, et les deux apps s'écraseraient.
identifiant=$(grep -m1 "PRODUCT_BUNDLE_IDENTIFIER" "$PROJET/project.pbxproj" \
              | sed 's/.*= *//; s/;.*//')
if [ "$identifiant" != "$BUNDLE" ]; then
    echo "  ✗ L'identifiant du projet est « $identifiant », or on attend « $BUNDLE »." >&2
    echo "    Arrêt : un envoi sous le mauvais identifiant écraserait l'autre app." >&2
    exit 1
fi
echo "  ✓ identifiant $BUNDLE"

echo "▸ Numéro de build"

# Deux builds ne peuvent pas porter le même numéro sur App Store Connect.
ancien=$(grep -m1 "CURRENT_PROJECT_VERSION" "$PROJET/project.pbxproj" \
         | sed 's/.*= *//; s/;.*//')
nouveau=$((ancien + 1))
perl -pi -e "s/CURRENT_PROJECT_VERSION = \Q$ancien\E;/CURRENT_PROJECT_VERSION = $nouveau;/g" \
     "$PROJET/project.pbxproj"
version=$(grep -m1 "MARKETING_VERSION" "$PROJET/project.pbxproj" \
          | sed 's/.*= *//; s/;.*//')
echo "  ✓ version $version, build $ancien → $nouveau"

echo "▸ Archive (quelques minutes)"

rm -rf "$TRAVAIL"
mkdir -p "$TRAVAIL"

xcodebuild archive \
    -project "$PROJET" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE" \
    -allowProvisioningUpdates \
    | tail -5

echo "  ✓ archive créée"

if [ "$ESSAI" = 1 ]; then
    echo
    echo "Essai terminé, rien n'a été envoyé. L'archive est dans $ARCHIVE."
    echo "Relance sans --essai pour transmettre à TestFlight."
    exit 0
fi

echo "▸ Envoi à App Store Connect"

# Les réglages d'export, régénérés à chaque fois pour qu'ils ne dérivent jamais.
# destination = upload fait transmettre directement par xcodebuild : pas besoin
# d'altool, qu'Apple a remplacé.
options="$TRAVAIL/ExportOptions.plist"
cat > "$options" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store-connect</string>
    <key>destination</key>
    <string>upload</string>
    <key>teamID</key>
    <string>$EQUIPE</string>
    <key>uploadSymbols</key>
    <true/>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
PLIST

auth=()
if [ -n "${ASC_KEY_PATH:-}" ]; then
    echo "  · authentification par clé d'API"
    auth=(-authenticationKeyPath "$ASC_KEY_PATH"
          -authenticationKeyID "$ASC_KEY_ID"
          -authenticationKeyIssuerID "$ASC_ISSUER_ID")
else
    echo "  · authentification par le compte connecté dans Xcode"
fi

xcodebuild -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportOptionsPlist "$options" \
    -exportPath "$TRAVAIL/envoi" \
    -allowProvisioningUpdates \
    "${auth[@]}" \
    | tail -10

cat <<FIN

  ✓ Envoyé : version $version, build $nouveau

Ce qu'il reste, sur appstoreconnect.apple.com :

  1. Onglet TestFlight. Le build apparaît sous 5 à 20 minutes, d'abord en
     « En cours de traitement ».
  2. Première fois seulement : Tests externes → créer le groupe « Amis »,
     y ajouter le build, remplir « Informations sur les tests », envoyer à
     la revue (24 à 48 h). Puis activer le Lien public : c'est le lien à
     partager.
  3. Les fois suivantes : ajouter le build au groupe « Amis ». Pas de revue,
     tes testeurs l'ont dans les minutes qui suivent.

Le numéro de build a été incrémenté dans le projet — pense à le committer :

  git add $PROJET/project.pbxproj
  git commit -m "Passe au build $nouveau"
  git push
FIN
