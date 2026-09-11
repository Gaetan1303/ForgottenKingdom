#!/usr/bin/env bash
# Validation reproductible sans toucher aux caches ni aux sauvegardes du projet.
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
validation_dir="$(mktemp -d "${TMPDIR:-/tmp}/fk-validation-XXXXXX")"
mkdir -p "$validation_dir/mvp"
# Toujours importer les sources : un cache copié masquerait des assets manquants.
tar -C "$repo_dir/mvp" --exclude='./.godot' --exclude='./build' -cf - . | tar -C "$validation_dir/mvp" -xf -
printf 'Validation isolée : %s\n' "$validation_dir"
godot --version
python3 "$repo_dir/scripts/run_godot_tests.py" "$validation_dir/mvp" "$validation_dir/results"
