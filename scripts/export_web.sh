#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_dir="$("$repo_dir/scripts/find_godot_project.sh")"
output_dir="$repo_dir/build/web"
"$repo_dir/scripts/ensure_web_preset.sh"
"$repo_dir/scripts/ensure_export_templates.sh"
mkdir -p "$output_dir"
# Importer est indispensable après un clone propre, y compris pour les chargements dynamiques.
godot --headless --path "$project_dir" --import >"$output_dir/import.log" 2>&1
if grep -En 'SCRIPT ERROR|Parse Error|Compile Error|Failed loading resource|Error importing' "$output_dir/import.log"; then exit 1; fi
godot --headless --path "$project_dir" --export-release Web "$output_dir/index.html" >"$output_dir/export.log" 2>&1
if grep -En 'SCRIPT ERROR|ERROR:' "$output_dir/export.log"; then exit 1; fi
for extension in html wasm pck js; do
  if [[ ! -s "$output_dir/index.$extension" ]]; then
    echo "ERROR: export incomplet, index.$extension absent ou vide." >&2
    exit 1
  fi
done
# Les diagnostics restent hors de l'artefact publié.
mv "$output_dir/import.log" "$repo_dir/build/web-import.log"
mv "$output_dir/export.log" "$repo_dir/build/web-export.log"
touch "$output_dir/.nojekyll"
printf 'Export Web prêt : %s/index.html\n' "$output_dir"
