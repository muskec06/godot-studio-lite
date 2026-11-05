#!/bin/bash
# Parse-check every GDScript file of the game (addons excluded) the way the
# game loads them. Usage: bash tools/parse-all.sh
# Exit: 0 all load · 1 some fail · 3 cannot run (no Godot / not set up)
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 3

gb="$(godot_bin)"
[ -n "$gb" ] || { echo "parse: cannot run, Godot executable not found"; exit 3; }
[ -f game/addons/gsl_tools/parse_check.gd ] && [ -d game/.godot ] || { echo "parse: cannot run, run tools/setup-godot.sh first"; exit 3; }

list=()
while IFS= read -r f; do list+=("res://${f#game/}"); done < <(find game -name '*.gd' -not -path 'game/addons/*' -not -path 'game/.godot/*' | sort)
[ ${#list[@]} -gt 0 ] || { echo "parse: no scripts"; exit 0; }

out="$("$gb" --headless --path game -s res://addons/gsl_tools/parse_check.gd -- "${list[@]}" 2>&1)"; code=$?
fails="$(printf '%s\n' "$out" | grep -c 'PARSE FAIL')"
if [ $code -eq 0 ]; then
  echo "parse: ${#list[@]} scripts OK"
  exit 0
fi
printf '%s\n' "$out" | grep -E 'PARSE FAIL|ERROR|error|at:' | head -n 40
echo "parse: $fails of ${#list[@]} scripts failed"
exit 1
