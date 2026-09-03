#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if command -v godot4 >/dev/null 2>&1; then
  GODOT=godot4
elif command -v godot >/dev/null 2>&1; then
  GODOT=godot
else
  echo "Godot 4 introuvable dans PATH." >&2
  exit 127
fi

echo "== Parse/import project =="
"$GODOT" --headless --path "$ROOT_DIR" --editor --quit

tests=(
  "res://scripts/tests/smoke_stats.gd"
  "res://scripts/tests/smoke_pnj_management.gd"
  "res://scripts/tests/smoke_refactor_domain.gd"
  "res://scripts/tests/generate_pnj_test.gd"
)

for test_script in "${tests[@]}"; do
  echo "== $test_script =="
  "$GODOT" --headless --path "$ROOT_DIR" --script "$test_script"
done

echo "ALL_REFACTOR_SMOKES_OK"
