#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"
PROJECT_DIR_ABS="$("$REPO_ROOT/scripts/find_godot_project.sh")"
python3 "$REPO_ROOT/scripts/prepare_godot_import.py" "$PROJECT_DIR_ABS"
python3 "$REPO_ROOT/scripts/validate_project_assets.py" "$PROJECT_DIR_ABS"
echo
echo "Patch préparé. Vérifie maintenant: git status"
echo "Puis ouvre mvp/project.godot et laisse Godot réimporter les ressources."
