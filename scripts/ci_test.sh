#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(pwd)"

echo "== Royaume Déchu / ForgottenKingdom CI =="
echo "Godot version :"
godot --version
echo

PROJECT_DIR_ABS="$("$REPO_ROOT/scripts/find_godot_project.sh")"

echo "Projet Godot détecté : $PROJECT_DIR_ABS"
cd "$PROJECT_DIR_ABS"

echo
echo "1/3 - Import des ressources"
godot --headless --editor --path . --quit

echo
echo "2/3 - Validation du démarrage/runtime"
godot --headless --path . --quit

echo
echo "3/3 - Tests de domaine"

TEST_CANDIDATES=(
  "scripts/tests/test_domain_services.gd"
  "tests/test_domain_services.gd"
)

TEST_FOUND=""

for candidate in "${TEST_CANDIDATES[@]}"; do
  if [[ -f "$candidate" ]]; then
    TEST_FOUND="$candidate"
    break
  fi
done

if [[ -n "$TEST_FOUND" ]]; then
  echo "Exécution de : $TEST_FOUND"
  godot --headless --path . -s "$TEST_FOUND"
else
  echo "INFO: aucun test_domain_services.gd trouvé ; validation runtime uniquement."
fi

echo
for prologue_test in test_playable_prologue.gd test_prologue_navigation.gd; do
  if [[ -f "scripts/tests/$prologue_test" ]]; then
    godot --headless --path . -s "scripts/tests/$prologue_test"
  fi
done

echo "Validation Godot terminée avec succès."
