#!/usr/bin/env bash
set -euo pipefail

PRESET_FILE="export_presets.cfg"
PRESET_NAME="${GODOT_WEB_PRESET:-Web}"

if [[ -f "$PRESET_FILE" ]]; then
  if grep -Fq "name=\"$PRESET_NAME\"" "$PRESET_FILE"; then
    echo "Preset Web '$PRESET_NAME' déjà présent."
    exit 0
  fi

  echo "ERROR: export_presets.cfg existe, mais le preset '$PRESET_NAME' est absent."
  echo "La CI ne modifie pas un fichier de presets existant."
  exit 1
fi

echo "Aucun export_presets.cfg trouvé."
echo "Création d'un preset Web temporaire pour la CI..."

cat > "$PRESET_FILE" <<EOF
[preset.0]

name="$PRESET_NAME"
platform="Web"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="data/progression/*.csv"
exclude_filter=""
export_path="build/web/index.html"
script_export_mode=2

[preset.0.options]

custom_template/debug=""
custom_template/release=""
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/custom_html_shell=""
html/head_include=""
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
html/experimental_virtual_keyboard=false
progressive_web_app/enabled=false
progressive_web_app/ensure_cross_origin_isolation_headers=true
progressive_web_app/offline_page=""
progressive_web_app/display=1
progressive_web_app/orientation=0
progressive_web_app/icon_144x144=""
progressive_web_app/icon_180x180=""
progressive_web_app/icon_512x512=""
progressive_web_app/background_color=Color(0, 0, 0, 1)
EOF

echo "Preset Web '$PRESET_NAME' généré."
