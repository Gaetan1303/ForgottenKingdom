#!/usr/bin/env bash
set -euo pipefail
version_full="$(godot --version | head -n1 | tr -d '\r')"
template_version="${version_full%%.official*}"
expected_dir="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$template_version"
release_template=web_nothreads_release.zip
if [[ -s "$expected_dir/$release_template" ]]; then
  printf 'Templates Web : %s\n' "$expected_dir"
  exit 0
fi
# GODOT_TEMPLATE_SOURCE désigne un dossier de version, jamais un template d'une autre version.
search_dirs=("${GODOT_TEMPLATE_SOURCE:-}" "/root/.local/share/godot/export_templates/$template_version" "/github/home/.local/share/godot/export_templates/$template_version" "/usr/local/share/godot/export_templates/$template_version" "/usr/share/godot/export_templates/$template_version" "/opt/godot/export_templates/$template_version")
for candidate in "${search_dirs[@]}"; do
  [[ -n "$candidate" && -s "$candidate/$release_template" ]] || continue
  if [[ "$(basename "$candidate")" != "$template_version" ]]; then
    echo "ERROR: version de templates incompatible : $candidate (attendu $template_version)." >&2
    exit 1
  fi
  mkdir -p "$expected_dir"
  cp -a "$candidate"/. "$expected_dir/"
  printf 'Templates Web : %s\n' "$expected_dir"
  exit 0
done
echo "ERROR: installer les templates officiels $template_version dans $expected_dir." >&2
exit 1
