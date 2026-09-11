#!/usr/bin/env python3
"""Contrôles rapides avant lancement de Godot.

Les warnings de doublons Unicode sont signalés mais ne provoquent pas l'échec,
car leur suppression automatique pourrait casser une référence historique.
"""
from __future__ import annotations

import re
import sys
import unicodedata
from pathlib import Path

ENCODED = re.compile(r"#U([0-9A-Fa-f]{4,6})")
AUDIO_EXT = {".mp3", ".ogg", ".wav"}


def decoded_name(name: str) -> str:
    def repl(match: re.Match[str]) -> str:
        try:
            return chr(int(match.group(1), 16))
        except (ValueError, OverflowError):
            return match.group(0)
    return unicodedata.normalize("NFC", ENCODED.sub(repl, name))


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_project_assets.py <project_dir>", file=sys.stderr)
        return 2

    project = Path(sys.argv[1]).resolve()
    errors: list[str] = []
    warnings: list[str] = []

    audio_root = project / "assets" / "audio"
    if not audio_root.is_dir():
        errors.append("assets/audio est absent")
    else:
        audio_files = [p for p in audio_root.rglob("*") if p.is_file() and p.suffix.lower() in AUDIO_EXT]
        if not audio_files:
            errors.append("aucun fichier audio mp3/ogg/wav trouvé")
        for path in audio_files:
            if path.stat().st_size == 0:
                errors.append(f"audio vide: {path.relative_to(project)}")

    # Détecte les noms de fichiers créés à partir des séquences #Uxxxx.
    all_files = [p for p in project.rglob("*") if p.is_file() and ".godot" not in p.parts]
    by_decoded: dict[str, list[Path]] = {}
    for path in all_files:
        rel = path.relative_to(project).as_posix()
        decoded = decoded_name(rel)
        by_decoded.setdefault(decoded, []).append(path)
        if "#U" in rel:
            warnings.append(f"nom Unicode encodé: {rel} -> {decoded}")

    for decoded, paths in by_decoded.items():
        if len(paths) > 1:
            rels = ", ".join(p.relative_to(project).as_posix() for p in paths)
            warnings.append(f"doublon Unicode probable [{decoded}]: {rels}")

    # Un AudioManager est indispensable au runtime actuel.
    audio_manager = project / "scripts" / "autoload" / "audio_manager.gd"
    if not audio_manager.is_file():
        errors.append("scripts/autoload/audio_manager.gd est absent")

    print("== Validation assets ==")
    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)

    if errors:
        return 1
    print("Validation assets OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
