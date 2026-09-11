#!/usr/bin/env bash
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 "$repo_dir/scripts/audit_mvp_paths.py"
bash "$repo_dir/scripts/test_memorial_prologue.sh" --all
