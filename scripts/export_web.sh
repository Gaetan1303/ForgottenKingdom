#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
PRESET="${GODOT_WEB_PRESET:-Web}"
OUTPUT_DIR="$REPO_ROOT/build/web"
OUTPUT_FILE="${GODOT_WEB_OUTPUT_FILE:-index.html}"

PROJECT_DIR_ABS="$("$REPO_ROOT/scripts/find_godot_project.sh")"

echo "Projet Godot détecté : $PROJECT_DIR_ABS"
cd "$PROJECT_DIR_ABS"

"$REPO_ROOT/scripts/ensure_web_preset.sh"
"$REPO_ROOT/scripts/ensure_export_templates.sh"

mkdir -p "$OUTPUT_DIR"

echo
echo "Export du preset '$PRESET'..."
echo "Destination : $OUTPUT_DIR/$OUTPUT_FILE"
echo

godot --headless --path . --export-release "$PRESET" "$OUTPUT_DIR/$OUTPUT_FILE"

if [[ ! -f "$OUTPUT_DIR/$OUTPUT_FILE" ]]; then
  echo "ERROR: l'export Web n'a pas produit $OUTPUT_DIR/$OUTPUT_FILE."
  exit 1
fi

echo
echo "Fichiers exportés :"
find "$OUTPUT_DIR" -maxdepth 1 -type f -printf ' - %f\n' | sort

echo
echo "Export Web terminé avec succès."
