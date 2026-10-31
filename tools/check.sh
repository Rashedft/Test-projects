#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export XDG_DATA_HOME="${XDG_DATA_HOME:-/workspace/.runtime/godot/data}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-/workspace/.runtime/godot/config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/workspace/.runtime/godot/cache}"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
python3 tools/build_catalog.py
python3 tools/validate_data.py
log_file=$(mktemp)
trap 'rm -f "$log_file"' EXIT
run_godot() {
  if ! godot "$@" >"$log_file" 2>&1; then cat "$log_file"; return 1; fi
  cat "$log_file"
  if rg -q 'SCRIPT ERROR:|SHADER ERROR:|^ERROR:' "$log_file"; then return 1; fi
}
run_godot --headless --editor --path . --import --quit
run_godot --headless --path . --script res://tests/test_runner.gd
run_godot --headless --path . --script res://tests/visual_checks.gd
run_godot --headless --path . --quit-after 120
