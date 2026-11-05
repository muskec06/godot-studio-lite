#!/bin/bash
# PostToolUse(Write|Edit) on *.gd: two checks on the file as it now is on disk.
#   1. Godot 3 syntax lint: patterns that parse in Godot 3 but not 4 (or that
#      Godot 4 renamed). Cheap, always runs, no Godot needed.
#   2. Parse check: `godot --headless --check-only` when an executable exists.
# Problems go to stderr with exit 2, so Claude sees them and fixes the file.
# exit 0 = clean or not a .gd file.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
INPUT="$(cat 2>/dev/null)"

path="$(json_get file_path)"
case "$path" in *.gd) ;; *) exit 0 ;; esac
rel="$(rel_to_root "$path")"
[ -n "$rel" ] || exit 0
abs="$ROOT/$rel"
[ -f "$abs" ] || exit 0

problems=""
add() { problems="${problems}${1}"$'\n'; }

# pattern<TAB>message. Extended regex, matched per line; comment lines skipped.
RULES='^[[:space:]]*onready[[:space:]]+var	`onready var` is Godot 3: use `@onready var`.
^[[:space:]]*export([[:space:]]*\(|[[:space:]]+var)	`export` is Godot 3: use `@export var name: Type`.
^[[:space:]]*tool[[:space:]]*$	`tool` is Godot 3: use `@tool` on the first line.
(^|[^a-zA-Z_.])yield[[:space:]]*\(	`yield()` is Godot 3: use `await signal_or_call`.
(^|[^A-Za-z0-9_])setget([^A-Za-z0-9_]|$)	`setget` is Godot 3: use `var x: T: set = _set_x, get = _get_x` or inline set/get.
move_and_slide[[:space:]]*\([[:space:]]*[^)[:space:]]	`move_and_slide(velocity, ...)` is Godot 3: set `velocity`, call `move_and_slide()` with no arguments.
(^|[^A-Za-z0-9_])connect[[:space:]]*\([[:space:]]*"[^"]+"[[:space:]]*,[[:space:]]*[^,()]+,[[:space:]]*"	String-based `connect("signal", target, "method")` is Godot 3: use `signal_name.connect(callable)`.
\.instance[[:space:]]*\([[:space:]]*\)	`PackedScene.instance()` is Godot 3: use `instantiate()`.
change_scene[[:space:]]*\(	`change_scene()` is Godot 3: use `change_scene_to_file()` or `change_scene_to_packed()`.
(^|[^A-Za-z0-9_])(KinematicBody2D|KinematicBody)([^A-Za-z0-9_]|$)	`KinematicBody*` is Godot 3: use `CharacterBody2D` / `CharacterBody3D`.
extends[[:space:]]+(Spatial|Sprite|Position2D|Position3D|Particles2D|Particles|Navigation2D|Navigation|ToolButton|YSort)[[:space:]]*$	Godot 3 node class: Spatial→Node3D, Sprite→Sprite2D, Position2D→Marker2D, Particles2D→GPUParticles2D, YSort→Node2D with y_sort_enabled.
(^|[^A-Za-z0-9_])(deg2rad|rad2deg|stepify|rand_range|range_lerp|linear2db|db2linear)[[:space:]]*\(	Renamed in Godot 4: deg_to_rad, rad_to_deg, snapped, randf_range, remap, linear_to_db, db_to_linear.
(^|[^A-Za-z0-9_])Pool(String|Int|Real|Vector2|Vector3|Color|Byte)Array([^A-Za-z0-9_]|$)	`Pool*Array` is Godot 3: use `Packed*Array` (PackedFloat32Array for PoolRealArray).
(^|[^A-Za-z0-9_])OS\.get_ticks_(msec|usec)([^A-Za-z0-9_]|$)	Moved in Godot 4: use `Time.get_ticks_msec()` / `Time.get_ticks_usec()`.
(^|[^A-Za-z0-9_])funcref[[:space:]]*\(	`funcref()` is Godot 3: use a `Callable` (`Callable(obj, "method")` or the method name directly).
^[[:space:]]*(remote|remotesync|puppet|puppetsync|master|mastersync)[[:space:]]+func	Godot 3 RPC keywords: use `@rpc(...)` above the function.
\.(rect_position|rect_size|rect_min_size|rect_rotation|rect_scale)([^A-Za-z0-9_]|$)	Control `rect_*` properties are Godot 3: use position, size, custom_minimum_size, rotation, scale.'

while IFS="$(printf '\t')" read -r pat msg; do
  [ -n "$pat" ] || continue
  hits="$(grep -nE -- "$pat" "$abs" 2>/dev/null | grep -vE '^[0-9]+:[[:space:]]*#' | cut -d: -f1 | head -n 5 | tr '\n' ',' | sed 's/,$//')"
  [ -n "$hits" ] && add "  line ${hits}: ${msg}"
done <<EOF
$RULES
EOF

# Parse check, only for scripts inside the Godot project.
parse_out=""
case "$rel" in
  game/*)
    gb="$(godot_bin)"
    checker="$ROOT/game/addons/gsl_tools/parse_check.gd"
    # Needs the Godot executable, the project, the checker script (installed by
    # tools/setup-godot.sh) and an imported project (.godot/ holds the class
    # cache that class_name lookups need). Missing any of them: skip quietly;
    # session-start.sh reports the gap once per session.
    if [ -n "$gb" ] && [ -f "$ROOT/game/project.godot" ] && [ -f "$checker" ] && [ -d "$ROOT/game/.godot" ]; then
      res="res://${rel#game/}"
      if command -v timeout >/dev/null 2>&1; then T="timeout 45"; else T=""; fi
      parse_out="$($T "$gb" --headless --path "$ROOT/game" -s res://addons/gsl_tools/parse_check.gd -- "$res" 2>&1)"
      code=$?
      if [ $code -ne 0 ]; then
        add "  Godot parse check failed for $res (exit $code):"
        add "$(printf '%s\n' "$parse_out" | grep -E 'ERROR|Error|error|at:|PARSE FAIL' | head -n 12 | sed 's/^/    /')"
      fi
    fi
    ;;
esac

if [ -n "$problems" ]; then
  {
    echo "gd-check: $rel needs fixing before you continue."
    printf '%s' "$problems"
    echo "Godot 4 API reference: the godot-api skill (breaking-changes.md)."
  } >&2
  exit 2
fi
exit 0
