#!/usr/bin/env bash
set -euo pipefail

# Permet de forcer le chemin :
# GODOT_PROJECT_DIR=mvp ./scripts/ci_test.sh
if [[ -n "${GODOT_PROJECT_DIR:-}" ]]; then
  if [[ ! -f "${GODOT_PROJECT_DIR}/project.godot" ]]; then
    echo "ERROR: GODOT_PROJECT_DIR='${GODOT_PROJECT_DIR}' ne contient pas project.godot." >&2
    exit 1
  fi

  cd "${GODOT_PROJECT_DIR}"
  pwd
  exit 0
fi

mapfile -t PROJECT_FILES < <(
  find . \
    -type f \
    -name project.godot \
    -not -path './.git/*' \
    -not -path './.godot/*' \
    -not -path './build/*' \
    -not -path './dist/*' \
    | sort
)

if [[ ${#PROJECT_FILES[@]} -eq 0 ]]; then
  echo "ERROR: aucun fichier project.godot trouvé dans le dépôt." >&2
  echo "Contenu de la racine :" >&2
  ls -la >&2
  exit 1
fi

if [[ ${#PROJECT_FILES[@]} -gt 1 ]]; then
  echo "ERROR: plusieurs projets Godot ont été trouvés :" >&2
  printf ' - %s\n' "${PROJECT_FILES[@]}" >&2
  echo "Définis GODOT_PROJECT_DIR pour choisir explicitement le bon projet." >&2
  exit 1
fi

PROJECT_FILE="${PROJECT_FILES[0]}"
PROJECT_DIR="$(dirname "$PROJECT_FILE")"

# Retire le ./ initial pour rendre les logs plus lisibles.
PROJECT_DIR="${PROJECT_DIR#./}"

if [[ "$PROJECT_DIR" == "." || -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR="."
fi

cd "$PROJECT_DIR"
pwd
