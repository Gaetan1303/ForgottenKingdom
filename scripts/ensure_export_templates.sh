#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION_FULL="$(godot --version | head -n1 | tr -d '\r')"
# Godot export templates are stored in a directory such as 4.7.2.stable.
# Keep the release channel suffix and only strip the build metadata.
GODOT_TEMPLATE_VERSION="$(echo "$GODOT_VERSION_FULL" | sed -E 's/\.official(\.[^.]+)?$//')"

EXPECTED_ROOT="${HOME}/.local/share/godot/export_templates"
EXPECTED_DIR="${EXPECTED_ROOT}/${GODOT_TEMPLATE_VERSION}"

TEMPLATE_DEBUG="web_nothreads_debug.zip"
TEMPLATE_RELEASE="web_nothreads_release.zip"

echo "Godot détecté : $GODOT_VERSION_FULL"
echo "Version de templates attendue : $GODOT_TEMPLATE_VERSION"
echo "HOME GitHub Actions : $HOME"
echo "Chemin attendu : $EXPECTED_DIR"

if [[ -f "$EXPECTED_DIR/$TEMPLATE_RELEASE" && -f "$EXPECTED_DIR/$TEMPLATE_DEBUG" ]]; then
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

# First prefer an exact version/channel match (e.g. 4.7.2.stable).
for root in "${SEARCH_ROOTS[@]}"; do
  [[ -d "$root" ]] || continue
  candidate="$root/$GODOT_TEMPLATE_VERSION"
  if [[ -f "$candidate/$TEMPLATE_RELEASE" ]]; then
    FOUND_DIR="$candidate"
    break
  fi
done

# Fallback: locate the release template and use its containing directory.
if [[ -z "$FOUND_DIR" ]]; then
  FOUND_FILE="$(find /root /usr /opt /github \
    -type f \
    -name "$TEMPLATE_RELEASE" \
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
  exit 1
fi

echo "Templates trouvés dans : $FOUND_DIR"

FOUND_REAL="$(readlink -f "$FOUND_DIR")"
EXPECTED_REAL="$(readlink -m "$EXPECTED_DIR")"

if [[ "$FOUND_REAL" != "$EXPECTED_REAL" ]]; then
  rm -rf "$EXPECTED_DIR"
  mkdir -p "$EXPECTED_DIR"
  cp -a "$FOUND_DIR"/. "$EXPECTED_DIR"/
fi

if [[ ! -f "$EXPECTED_DIR/$TEMPLATE_RELEASE" ]]; then
  echo "ERROR: $TEMPLATE_RELEASE reste introuvable après préparation."
  exit 1
fi

if [[ ! -f "$EXPECTED_DIR/$TEMPLATE_DEBUG" ]]; then
  echo "WARNING: $TEMPLATE_DEBUG est absent ; l'export release reste disponible."
fi

echo "Templates Web prêts dans : $EXPECTED_DIR"
