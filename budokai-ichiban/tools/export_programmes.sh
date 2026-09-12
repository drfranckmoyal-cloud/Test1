#!/bin/bash
# Sort les neuf programmes en un document lisible, extrait du code lui-même.
#
#     tools/export_programmes.sh [fichier.md]
#
# Le document n'est pas une recopie : il est produit par le vrai générateur
# de séances de l'app, au palier Confirmé. Il ne peut donc pas diverger.
set -e
racine="$(cd "$(dirname "$0")/.." && pwd)"
sortie="${1:-$HOME/Desktop/Budokai Ichiban — les neuf programmes.md}"
atelier="$(mktemp -d)"
trap 'rm -rf "$atelier"' EXIT

swiftc -O \
  "$racine/tools/export/shim.swift" \
  "$racine/BudokaiIchi/Model/Program.swift" \
  "$racine/BudokaiIchi/Model/Content.swift" \
  "$racine/tools/export/main.swift" \
  -o "$atelier/dump"

"$atelier/dump" "$sortie"
