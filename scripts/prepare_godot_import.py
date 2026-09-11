#!/usr/bin/env python3
"""Prépare un checkout ForgottenKingdom avant l'import Godot.

- Les CSV de progression sont des données métier, pas des traductions.
- Godot traite les .csv comme traductions par défaut : on force importer=keep.
- Les .translation générés historiquement dans data/progression sont supprimés.
- L'encodage UTF-8 des CSV est validé avant que Godot puisse les lire.
"""
from __future__ import annotations

import sys
from pathlib import Path


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> int:
    if len(sys.argv) != 2:
        fail("usage: prepare_godot_import.py <project_dir>")

    project = Path(sys.argv[1]).resolve()
    progression = project / "data" / "progression"
    if not (project / "project.godot").is_file():
        fail(f"project.godot introuvable dans {project}")
    if not progression.is_dir():
        fail(f"dossier de progression introuvable: {progression}")

    csv_files = sorted(progression.glob("*.csv"))
    if not csv_files:
        fail(f"aucun CSV de progression trouvé dans {progression}")

    invalid: list[str] = []
    rewritten = 0
    for csv_path in csv_files:
        raw = csv_path.read_bytes()
        try:
            raw.decode("utf-8-sig")
        except UnicodeDecodeError as exc:
            invalid.append(f"{csv_path.name}: {exc}")
            continue

        import_path = csv_path.with_name(csv_path.name + ".import")
        expected = '[remap]\n\nimporter="keep"\n'
        current = import_path.read_text(encoding="utf-8", errors="replace") if import_path.exists() else ""
        if current != expected:
            import_path.write_text(expected, encoding="utf-8", newline="\n")
            rewritten += 1

    if invalid:
        print("CSV non UTF-8 détectés :", file=sys.stderr)
        for item in invalid:
            print(f" - {item}", file=sys.stderr)
        fail("corriger l'encodage des CSV ci-dessus avant l'import Godot")

    translations = sorted(progression.glob("*.translation"))
    for path in translations:
        path.unlink()

    print(f"CSV métier: {len(csv_files)}")
    print(f".csv.import forcés en Keep File: {rewritten}")
    print(f".translation historiques supprimés: {len(translations)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
