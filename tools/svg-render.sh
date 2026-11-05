#!/bin/bash
# Rasterize an SVG to PNG with Godot's own SVG renderer (what the game will
# show). Use it to look at a vector asset, and to make the store's PNG icons.
#
#   bash tools/svg-render.sh <in.svg> [out.png] [width]
#     out.png defaults to production/previews/<name>.png; width defaults to
#     the SVG's own width. Open the PNG with Read to look at it.
# Exit: 0 written · 1 render failed · 2 bad arguments · 3 cannot run here
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 3

in="${1:-}"; [ -f "$in" ] || { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
out="${2:-production/previews/$(basename "${in%.svg}").png}"
width="${3:-0}"
gb="$(godot_bin)"; [ -n "$gb" ] || { echo "svg-render: cannot run, Godot executable not found"; exit 3; }
[ -f game/addons/gsl_tools/image_tool.gd ] || { echo "svg-render: run tools/setup-godot.sh first"; exit 3; }
abs() { case "$1" in /*) printf '%s' "$1" ;; *) printf '%s/%s' "$ROOT" "$1" ;; esac; }
mkdir -p "$(dirname "$out")"
"$gb" --headless --path game -s res://addons/gsl_tools/image_tool.gd -- svg "$(abs "$in")" "$(abs "$out")" "$width" 2>&1 | grep -E 'wrote|image_tool|ERROR'
[ "${PIPESTATUS[0]}" -eq 0 ] && [ -f "$out" ] || exit 1
echo "$out"
