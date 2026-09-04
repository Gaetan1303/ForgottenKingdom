#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"
PRESET="${GODOT_WEB_PRESET:-Web}"
OUTPUT_DIR="$REPO_ROOT/build/web"
OUTPUT_FILE="${GODOT_WEB_OUTPUT_FILE:-index.html}"

PROJECT_DIR_ABS="$("$REPO_ROOT/scripts/find_godot_project.sh")"

echo "Projet Godot détecté : $PROJECT_DIR_ABS"
cd "$PROJECT_DIR_ABS"

if [[ ! -f "export_presets.cfg" ]]; then
  echo "ERROR: export_presets.cfg introuvable dans : $PROJECT_DIR_ABS"
  echo "Crée un preset Web dans Godot : Project > Export > Add... > Web."
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

echo "Export du preset '$PRESET' vers '$OUTPUT_DIR/$OUTPUT_FILE'..."
godot --headless --path . --export-release "$PRESET" "$OUTPUT_DIR/$OUTPUT_FILE"

if [[ ! -f "$OUTPUT_DIR/$OUTPUT_FILE" ]]; then
  echo "ERROR: l'export Web n'a pas produit $OUTPUT_DIR/$OUTPUT_FILE."
  exit 1
fi

echo "Export Web terminé."
