#!/bin/bash
# Colour-vision checks with Godot (no other software needed).
#
#   bash tools/colorblind.sh image <file.png>
#       writes <file>_protan.png, _deutan.png, _tritan.png next to it
#       (open them with Read: is everything the player must tell apart still
#       distinct?)
#   bash tools/colorblind.sh palette [file.hex] [min_delta_e]
#       pairs of colours that become hard to tell apart; default file is
#       game/assets/_style/gameplay_colors.hex, else _style/palette.hex
#
# About 1 in 12 men and 1 in 200 women have a colour-vision deficiency,
# deuteranomaly most often. Exit: 0 done · 2 bad arguments · 3 cannot run.
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 3

gb="$(godot_bin)"
[ -n "$gb" ] || { echo "colorblind: cannot run, Godot executable not found"; exit 3; }
[ -f game/addons/gsl_tools/image_tool.gd ] || { echo "colorblind: run tools/setup-godot.sh first"; exit 3; }
tool() { "$gb" --headless --path game -s res://addons/gsl_tools/image_tool.gd -- "$@" 2>&1 | grep -vE '^Godot Engine|^$'; return "${PIPESTATUS[0]}"; }
abs() { case "$1" in /*) printf '%s' "$1" ;; *) printf '%s/%s' "$ROOT" "$1" ;; esac; }

case "${1:-}" in
  image)
    f="${2:-}"; [ -f "$f" ] || { echo "no such image: $f"; exit 2; }
    tool cvd "$(abs "$f")" "$(abs "${f%.*}")" ;;
  palette)
    p="${2:-}"
    if [ -z "$p" ]; then
      for c in game/assets/_style/gameplay_colors.hex game/assets/_style/palette.hex; do [ -f "$c" ] && { p="$c"; break; }; done
    fi
    [ -n "$p" ] && [ -f "$p" ] || { echo "no palette: give a .hex file (one RRGGBB per line)"; exit 2; }
    tool cvdcheck "$(abs "$p")" "${3:-15}" ;;
  *) sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
