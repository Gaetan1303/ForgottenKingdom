#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
preset_file="$repo_dir/mvp/export_presets.cfg"
if [[ ! -f "$preset_file" ]] || ! grep -Eq '^name="Web"$' "$preset_file"; then
  echo "ERROR: le preset canonique Web manque dans mvp/export_presets.cfg." >&2
  exit 1
fi
