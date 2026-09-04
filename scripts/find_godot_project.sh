#!/usr/bin/env bash
set -euo pipefail

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
  exit 1
fi

if [[ ${#PROJECT_FILES[@]} -gt 1 ]]; then
  echo "ERROR: plusieurs projets Godot ont été trouvés :" >&2
  printf ' - %s\n' "${PROJECT_FILES[@]}" >&2
  echo "Définis GODOT_PROJECT_DIR pour sélectionner le projet." >&2
  exit 1
fi

PROJECT_DIR="$(dirname "${PROJECT_FILES[0]}")"
PROJECT_DIR="${PROJECT_DIR#./}"

if [[ -z "$PROJECT_DIR" ]]; then
  PROJECT_DIR="."
fi

cd "$PROJECT_DIR"
pwd
