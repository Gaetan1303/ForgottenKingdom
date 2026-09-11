#!/usr/bin/env bash
# Validation reproductible sans toucher aux caches ni aux sauvegardes du projet.
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validation_dir="$(mktemp -d /tmp/fk-memorial-XXXXXX)"
cp -a --reflink=auto "$repo_dir/mvp" "$validation_dir/mvp"
export XDG_CONFIG_HOME="$validation_dir/config"
export XDG_DATA_HOME="$validation_dir/data"
echo "Validation isolée : $validation_dir"
godot --version
godot --headless --path "$validation_dir/mvp" --editor --import --quit >"$validation_dir/import.log" 2>&1
if rg -n 'SCRIPT ERROR|Parse Error|Compile Error|autoload.*fail' "$validation_dir/import.log"; then exit 1; fi
godot --headless --path "$validation_dir/mvp" --quit-after 3 >"$validation_dir/boot.log" 2>&1
if rg -n 'SCRIPT ERROR|ERROR:' "$validation_dir/boot.log"; then exit 1; fi
tests=(test_compile_smoke test_power_objectives test_memory_sequences test_multiroute_campaign test_memorial_resume test_prologue_navigation test_playable_prologue test_character_creation_point_buy test_character_creation_smoke test_domain_services test_world_state_adapter)
if [[ "${1:-}" == "--all" ]]; then
  mapfile -t tests < <(rg --files "$repo_dir/mvp/scripts/tests" -g '*.gd' | sort | sed 's|.*/||; s/\.gd$//')
fi
for test_name in "${tests[@]}"; do
  # Chaque suite reçoit son dossier utilisateur, y compris l'index des slots.
  XDG_DATA_HOME="$validation_dir/data/$test_name" timeout 60 godot --headless --path "$validation_dir/mvp" -s "scripts/tests/$test_name.gd" >"$validation_dir/$test_name.log" 2>&1
  if rg -n 'SCRIPT ERROR|ERROR:' "$validation_dir/$test_name.log"; then exit 1; fi
  echo "$test_name : PASS"
done
echo "MEMORIAL_PROLOGUE_SUITE_OK"
