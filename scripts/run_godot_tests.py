#!/usr/bin/env python3
"""Suites isolées, comparaison possible par nom, code de sortie et diagnostics."""
import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("project", type=Path)
    parser.add_argument("results", type=Path)
    args = parser.parse_args()
    args.results.mkdir(parents=True, exist_ok=True)
    checks = [("import", ["--editor", "--import", "--quit"]), ("boot", ["--quit-after", "3"])]
    checks += [(p.stem, ["--script", "res://scripts/tests/" + p.name])
               for p in sorted((args.project / "scripts/tests").glob("*.gd"))]
    results = []
    for name, flags in checks:
        env = dict(os.environ, XDG_CONFIG_HOME=str(args.results / "config"),
                   XDG_DATA_HOME=str(args.results / "user" / name))
        try:
            process = subprocess.run(["godot", "--headless", "--path", str(args.project), *flags],
                                     env=env, text=True, stdout=subprocess.PIPE,
                                     stderr=subprocess.STDOUT, timeout=90)
            code, output = process.returncode, process.stdout
        except subprocess.TimeoutExpired as error:
            code, output = 124, (error.stdout or b"").decode()
        (args.results / (name + ".log")).write_text(output)
        # Editor progress-dialog/socket warnings are baseline engine diagnostics.
        # Compiler/import failures remain blocking even if Godot returns zero.
        pattern = (r"SCRIPT ERROR|Parse Error|Compile Error|Failed loading resource|Error importing"
                   if name == "import" else r"SCRIPT ERROR|ERROR:")
        errors = [line for line in output.splitlines() if re.search(pattern, line)]
        ok = code == 0 and not errors
        results.append(dict(name=name, exit=code, errors=errors, ok=ok))
        print(f"{name}: {'PASS' if ok else 'FAIL'} (exit {code})", flush=True)
    (args.results / "results.json").write_text(json.dumps(results, indent=2))
    passed = sum(result["ok"] for result in results)
    print(f"TEST_SUMMARY total={len(results)} passed={passed} failed={len(results) - passed}")
    return int(passed != len(results))


if __name__ == "__main__":
    sys.exit(main())
