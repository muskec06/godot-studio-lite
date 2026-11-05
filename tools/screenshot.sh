#!/bin/bash
# Run a scene and save a screenshot to production/evidence/.
# Usage: bash tools/screenshot.sh <story-id> [res://scene.tscn] [frames] [actions]
#   scene defaults to main_scene in project.yaml; frames to 60.
#   actions: comma list of input actions to hold, e.g. ui_right
# Prints the PNG path; open it with the Read tool to look at it.
# Needs a display: on a headless server it exits 3.
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 3

id="${1:-}"; [ -n "$id" ] || { echo "usage: tools/screenshot.sh <story-id> [scene] [frames] [actions]"; exit 2; }
scene="${2:-$(cfg main_scene)}"; [ -n "$scene" ] || { echo "no scene given and main_scene is empty in project.yaml"; exit 2; }
frames="${3:-60}"
actions="${4:-}"
gb="$(godot_bin)"; [ -n "$gb" ] || { echo "Godot executable not found"; exit 3; }
[ -f game/addons/gsl_tools/screenshot.gd ] || { echo "run tools/setup-godot.sh first"; exit 3; }

mkdir -p production/evidence
out="$ROOT/production/evidence/${id}-$(date '+%Y%m%d-%H%M%S').png"
if command -v timeout >/dev/null 2>&1; then T="timeout 60"; else T=""; fi
$T "$gb" --path game -s res://addons/gsl_tools/screenshot.gd -- "$scene" "$out" "$frames" "$actions" 2>&1 | grep -vE '^\s*$' | tail -n 8
code=${PIPESTATUS[0]}
if [ "$code" -eq 0 ] && [ -f "$out" ]; then
  echo "screenshot: $out"
  exit 0
fi
echo "screenshot: failed (exit $code). On a machine without a display, ask the user to run the game and send a screenshot."
exit 3
