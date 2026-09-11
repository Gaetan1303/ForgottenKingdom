#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

ensure_python3() {
  if command -v python3 >/dev/null 2>&1; then
    return 0
  fi

  echo "Python 3 absent du container : installation du Python système..."

  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends python3
    rm -rf /var/lib/apt/lists/*
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache python3
  else
    echo "ERROR: python3 est requis pour les validations d'assets et aucun gestionnaire de paquets supporté n'est disponible." >&2
    exit 127
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "ERROR: l'installation de python3 a échoué." >&2
    exit 127
  fi
}

ensure_python3
PYTHON_BIN="$(command -v python3)"

echo "== Royaume Déchu / ForgottenKingdom CI =="
echo "Python : $PYTHON_BIN"
"$PYTHON_BIN" --version
echo "Godot version :"
godot --version

echo
PROJECT_DIR_ABS="$("$REPO_ROOT/scripts/find_godot_project.sh")"
echo "Projet Godot détecté : $PROJECT_DIR_ABS"

echo
echo "0/4 - Préparation et validation des assets"
"$PYTHON_BIN" "$REPO_ROOT/scripts/prepare_godot_import.py" "$PROJECT_DIR_ABS"
"$PYTHON_BIN" "$REPO_ROOT/scripts/validate_project_assets.py" "$PROJECT_DIR_ABS"

if [[ "${CI:-}" == "true" ]]; then
  rm -rf "$PROJECT_DIR_ABS/.godot"
fi

cd "$PROJECT_DIR_ABS"

echo
echo "1/4 - Import des ressources"
godot --headless --editor --path . --quit

echo
echo "2/4 - Validation du démarrage/runtime"
godot --headless --path . --quit

echo
echo "3/4 - Tests de domaine"
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
echo "4/4 - Smoke tests de parcours"
for prologue_test in \
  test_creation_classes_ui.gd \
  test_expedition_corruption.gd \
  test_campaign_states.gd \
  test_playable_prologue.gd \
  test_prologue_navigation.gd; do
  if [[ -f "scripts/tests/$prologue_test" ]]; then
    echo "Exécution de : scripts/tests/$prologue_test"
    godot --headless --path . -s "scripts/tests/$prologue_test"
  fi
done

echo
echo "Validation Godot terminée avec succès."
