#!/usr/bin/env bash
set -euo pipefail

PRESET="${GODOT_WEB_PRESET:-Web}"
OUTPUT_DIR="${GODOT_WEB_OUTPUT_DIR:-build/web}"
OUTPUT_FILE="${GODOT_WEB_OUTPUT_FILE:-index.html}"

if [[ ! -f "project.godot" ]]; then
  echo "ERROR: project.godot introuvable."
  exit 1
fi

if [[ ! -f "export_presets.cfg" ]]; then
  echo "ERROR: export_presets.cfg introuvable."
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
