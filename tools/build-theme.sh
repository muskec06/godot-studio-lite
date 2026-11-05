#!/bin/bash
# Build the Godot UI theme from the design tokens and make it the project's
# default theme (Project Settings → GUI → Theme → Custom).
#   bash tools/build-theme.sh
# Exit: 0 written · 1 failed · 3 cannot run here (no Godot / not set up)
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 3
gb="$(godot_bin)"; [ -n "$gb" ] || { echo "build-theme: cannot run, Godot executable not found"; exit 3; }
[ -f game/addons/gsl_tools/build_theme.gd ] && [ -d game/.godot ] || { echo "build-theme: run tools/setup-godot.sh first"; exit 3; }
"$gb" --headless --path game -s res://addons/gsl_tools/build_theme.gd 2>&1 | grep -E 'wrote|build_theme|ERROR'
[ "${PIPESTATUS[0]}" -eq 0 ] || exit 1
godot_ini_set game/project.godot gui theme/custom '"res://resources/theme.tres"'
echo "theme set as the project default"
