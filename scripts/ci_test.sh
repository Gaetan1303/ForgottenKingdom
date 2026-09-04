#!/usr/bin/env bash
set -euo pipefail

echo "== Royaume Déchu / ForgottenKingdom CI tests =="
echo "Godot version:"
godot --version

if [[ ! -f "project.godot" ]]; then
  echo "ERROR: project.godot introuvable."
  exit 1
fi

echo
echo "1/3 - Import des ressources"
godot --headless --editor --path . --quit

echo
echo "2/3 - Validation du démarrage"
godot --headless --path . --quit

echo
echo "3/3 - Tests de domaine"
TEST_FILE="scripts/tests/test_domain_services.gd"

if [[ -f "$TEST_FILE" ]]; then
  godot --headless --path . -s "$TEST_FILE"
else
  echo "INFO: $TEST_FILE absent ; aucun test de domaine dédié n'est exécuté."
fi

echo
echo "CI Godot terminée avec succès."
