#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_dir="$repo_dir/mvp"
if [[ ! -f "$project_dir/project.godot" ]]; then
  echo "ERROR: mvp/project.godot est introuvable." >&2
  exit 1
fi
if [[ -n "${GODOT_PROJECT_DIR:-}" && "$(realpath "$GODOT_PROJECT_DIR")" != "$project_dir" ]]; then
  echo "ERROR: seul mvp/ peut être utilisé comme projet Godot." >&2
  exit 1
fi
printf '%s\n' "$project_dir"
