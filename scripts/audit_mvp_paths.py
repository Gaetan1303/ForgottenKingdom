#!/usr/bin/env python3
"""Contrat de racine unique et de chemins portables, sans dépendance Godot."""
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "mvp"
TEXT_TYPES = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".json", ".yaml", ".html", ".gdshader"}
# Emplacements optionnels historiques : les lecteurs ont un rendu de remplacement.
# Aucun de ces fichiers n'est un preload ou une ext_resource.
OPTIONAL = {
    "res://assets/character.png": "texture optionnelle du contrôleur animation historique",
    "res://assets/images/Creatures/tentacle_01.png": "profil avec portrait par défaut",
    "res://assets/images/Creatures/mind_flayer_01.png": "profil avec portrait par défaut",
    "res://assets/images/Creatures/succubus_lilith.png": "profil avec portrait par défaut",
    "res://assets/images/Creatures/incubus_azrael.png": "profil avec portrait par défaut",
    "res://assets/maps/veyr_world.png": "carte procédurale existante",
    "res://assets/maps/marches_cendrees.png": "carte procédurale existante",
    "res://assets/ui/stop_icon.svg": "bouton texte existant",
}


def main():
    errors = []
    projects = [p.relative_to(ROOT).as_posix() for p in ROOT.rglob("project.godot")
                if not {".git", ".godot", "build"}.intersection(p.relative_to(ROOT).parts)]
    if projects != ["mvp/project.godot"]:
        errors.append(f"Projets Godot inattendus : {projects}")
    for name in ("Game", "game"):
        if (ROOT / name).exists():
            errors.append(f"Arbre historique encore présent : {name}/")
    for path in [*ROOT.joinpath("scripts").glob("*.sh"), *ROOT.joinpath(".github/workflows").glob("*.yml")]:
        for number, line in enumerate(path.read_text().splitlines(), 1):
            if not line.lstrip().startswith("#") and re.search(r"(?:Game|game)/|cd\s+[\"']?(?:Game|game)\b", line):
                errors.append(f"{path.relative_to(ROOT)}:{number}: outil dépendant de l'ancien projet")
    checked = 0
    referenced = set()
    names = {}
    for path in sorted(PROJECT.rglob("*")):
        relative = path.relative_to(PROJECT)
        if not path.is_file() or {".godot", "build"}.intersection(relative.parts):
            continue
        key = relative.as_posix().casefold()
        if key in names:
            errors.append(f"Collision de casse : {names[key]} / {relative}")
        names[key] = relative
        if path.suffix not in TEXT_TYPES or "tests" in relative.parts:
            continue
        checked += 1
        for number, line in enumerate(path.read_text().splitlines(), 1):
            if line.lstrip().startswith(("#", ";")):
                continue
            where = f"mvp/{relative}:{number}"
            for match in re.finditer(r'''["'](/[^"']+)["']''', line):
                absolute = match.group(1)
                prefix = line[:match.start()].rstrip()
                fragment = prefix.endswith((".contains(", ".ends_with(", ".begins_with(", "+"))
                if not fragment and not absolute.startswith("/root/"):
                    errors.append(f"{where}: chemin absolu de production : {absolute}")
            if re.search(r"(?:^|[/'\".])(?:Game|game)/|/tmp(?:/|[\"'])|/home/|OS\.get_temp_dir\s*\(|file://|[A-Za-z]:[\\/]", line):
                # res:// and user:// are URI schemes, not Windows drive letters.
                without_schemes = line.replace("res://", "").replace("user://", "").replace("uid://", "")
                if re.search(r"(?:^|[/'\".])(?:Game|game)/|/tmp(?:/|[\"'])|/home/|OS\.get_temp_dir\s*\(|file://|[A-Za-z]:[\\/]", without_schemes):
                    errors.append(f"{where}: dépendance non portable : {line.strip()}")
            for literal in re.findall(r'''["'](res://[^"']+)["']''', line):
                if "%" in literal or literal.endswith("/") or "." not in literal.rsplit("/", 1)[-1]:
                    continue  # répertoire ou modèle de chemin dynamique
                referenced.add(literal)
                if ".." in Path(literal[6:]).parts:
                    errors.append(f"{where}: sortie de res:// : {literal}")
                if not (PROJECT / literal[6:]).exists():
                    required = "preload(" in line or "ext_resource" in line
                    if required or literal not in OPTIONAL:
                        errors.append(f"{where}: ressource absente ou casse incorrecte : {literal}")
    for error in errors:
        print(error, file=sys.stderr)
    if errors:
        return 1
    print(f"MVP_PATHS_OK files={checked} resource_paths={len(referenced)} legacy=0 temp_runtime=0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
