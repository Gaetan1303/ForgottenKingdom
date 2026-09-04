#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION_FULL="$(godot --version | head -n1 | tr -d '\r')"
GODOT_TEMPLATE_VERSION="$(echo "$GODOT_VERSION_FULL" | awk -F. '{print $1"."$2"."$3}')"

EXPECTED_ROOT="${HOME}/.local/share/godot/export_templates"
EXPECTED_DIR="${EXPECTED_ROOT}/${GODOT_TEMPLATE_VERSION}"

echo "Godot détecté : $GODOT_VERSION_FULL"
echo "Version de templates attendue : $GODOT_TEMPLATE_VERSION"
echo "HOME GitHub Actions : $HOME"
echo "Chemin attendu : $EXPECTED_DIR"

if [[ -f "$EXPECTED_DIR/web_nothreads_release.zip" ]]; then
  echo "Templates Web déjà disponibles au bon emplacement."
  exit 0
fi

mkdir -p "$EXPECTED_ROOT"

SEARCH_ROOTS=(
  "/root/.local/share/godot/export_templates"
  "/github/home/.local/share/godot/export_templates"
  "/usr/local/share/godot/export_templates"
  "/usr/share/godot/export_templates"
  "/opt/godot/export_templates"
)

FOUND_DIR=""

for root in "${SEARCH_ROOTS[@]}"; do
  [[ -d "$root" ]] || continue

  candidate="$root/$GODOT_TEMPLATE_VERSION"

  if [[ -f "$candidate/web_nothreads_release.zip" ]]; then
    FOUND_DIR="$candidate"
    break
  fi
done

if [[ -z "$FOUND_DIR" ]]; then
  FOUND_FILE="$(find /root /usr /opt /github \
    -type f \
    -name 'web_nothreads_release.zip' \
    2>/dev/null \
    | head -n1 || true)"

  if [[ -n "$FOUND_FILE" ]]; then
    FOUND_DIR="$(dirname "$FOUND_FILE")"
  fi
fi

if [[ -z "$FOUND_DIR" ]]; then
  echo "ERROR: aucun template Web Godot n'a été trouvé dans l'image Docker."
  echo
  echo "Répertoires export_templates présents :"
  find /root /usr /opt /github \
    -type d \
    -name export_templates \
    2>/dev/null \
    -print || true
  echo
  echo "Le runner utilise une image godot-ci qui ne contient probablement pas les templates d'export."
  exit 1
fi

echo "Templates trouvés dans : $FOUND_DIR"

# Évite de copier vers soi-même si HOME pointe déjà vers le bon dossier.
FOUND_REAL="$(readlink -f "$FOUND_DIR")"
EXPECTED_REAL="$(readlink -m "$EXPECTED_DIR")"

if [[ "$FOUND_REAL" == "$EXPECTED_REAL" ]]; then
  echo "Les templates sont déjà au bon emplacement."
  exit 0
fi

rm -rf "$EXPECTED_DIR"
mkdir -p "$EXPECTED_DIR"
cp -a "$FOUND_DIR"/. "$EXPECTED_DIR"/

echo "Templates copiés vers : $EXPECTED_DIR"

if [[ ! -f "$EXPECTED_DIR/web_nothreads_release.zip" ]]; then
  echo "ERROR: web_nothreads_release.zip reste introuvable après copie."
  exit 1
fi

echo "Templates Web prêts."
