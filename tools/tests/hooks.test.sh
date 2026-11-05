#!/bin/bash
# Hook tests: run each hook against a throwaway copy of this project with
# crafted JSON input, and check exit codes and output. Runs twice: with jq and
# with the sed fallback (GSL_NO_JQ=1). Usage: bash tools/tests/hooks.test.sh
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pass=0; fail=0

ok()   { pass=$((pass+1)); }
bad()  { fail=$((fail+1)); echo "  FAIL: $1"; }
expect_code() { # name expected actual
  if [ "$2" = "$3" ]; then ok; else bad "$1 (expected exit $2, got $3)"; fi
}
expect_out() { # name pattern text
  if printf '%s' "$3" | grep -qE -- "$2"; then ok; else bad "$1 (output lacks /$2/)"; fi
}

run_suite() {
  local label="$1"
  T="$(mktemp -d 2>/dev/null || mktemp -d -t gsl)"
  cp -R "$SRC/." "$T/"
  rm -rf "$T/.git"
  export CLAUDE_PROJECT_DIR="$T"
  H="$T/.claude/hooks"
  echo "[$label]"

  # --- session-start -------------------------------------------------------
  out="$(bash "$H/session-start.sh" < /dev/null)"; c=$?
  expect_code "session-start exits 0" 0 $c
  expect_out "session-start shows mode" 'Mode: jam' "$out"
  expect_out "session-start shows checkpoint" 'Next step: run /start' "$out"
  expect_out "session-start flags missing project.godot" 'run /start' "$out"

  # --- read-guard ----------------------------------------------------------
  big="$T/docs/big.md"
  { echo "# Big doc"; for i in $(seq 1 900); do echo "## Section $i"; echo "Line of filler text to make this file large enough for the guard to fire."; done; } > "$big"
  small="$T/docs/brief.md"; echo "# Brief" > "$small"

  err="$(printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$big" | bash "$H/read-guard.sh" 2>&1 >/dev/null)"; c=$?
  expect_code "read-guard refuses big whole read" 2 $c
  expect_out "read-guard lists headings" 'Section 1' "$err"

  printf '{"tool_name":"Read","tool_input":{"file_path":"%s","offset":10,"limit":40}}' "$big" | bash "$H/read-guard.sh" >/dev/null 2>&1; c=$?
  expect_code "read-guard allows ranged read" 0 $c

  printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$small" | bash "$H/read-guard.sh" >/dev/null 2>&1; c=$?
  expect_code "read-guard allows small doc" 0 $c

  cp "$big" "$T/game/big.md"
  printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$T/game/big.md" | bash "$H/read-guard.sh" >/dev/null 2>&1; c=$?
  expect_code "read-guard ignores files outside docs/production" 0 $c

  # --- gd-check ------------------------------------------------------------
  mkdir -p "$T/game/scripts"
  good="$T/game/scripts/good.gd"
  cat > "$good" <<'GD'
extends CharacterBody2D

@export var speed: float = 300.0
@onready var sprite: Sprite2D = $Sprite2D

# onready var old_comment_should_not_trigger
func _physics_process(delta: float) -> void:
	velocity.x = Input.get_axis("ui_left", "ui_right") * speed
	move_and_slide()
	await get_tree().create_timer(0.1).timeout
	var a := deg_to_rad(90.0)
	var p := PackedStringArray()
	died.connect(_on_died)
	connect("died", _on_died)
	var s := Sprite2D.new()
GD
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$good" | bash "$H/gd-check.sh" >/dev/null 2>&1; c=$?
  expect_code "gd-check passes Godot 4 code" 0 $c

  old="$T/game/scripts/old.gd"
  cat > "$old" <<'GD'
tool
extends KinematicBody2D
export var speed = 200
onready var sprite = $Sprite
var hp = 10 setget set_hp
func _physics_process(delta):
	velocity = move_and_slide(velocity, Vector2.UP)
	yield(get_tree().create_timer(1.0), "timeout")
	var a = deg2rad(90)
	var p = PoolStringArray()
	connect("died", self, "_on_died")
	var n = scene.instance()
	var t = OS.get_ticks_msec()
	$Label.rect_position = Vector2.ZERO
GD
  err="$(printf '{"tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"a","new_string":"b"}}' "$old" | bash "$H/gd-check.sh" 2>&1 >/dev/null)"; c=$?
  expect_code "gd-check flags Godot 3 code" 2 $c
  for pat in '@onready' '@export' '@tool' 'await' 'setget' 'move_and_slide' 'CharacterBody2D' 'deg_to_rad' 'Packed' 'signal_name.connect' 'instantiate' 'Time.get_ticks' 'custom_minimum_size'; do
    expect_out "gd-check mentions $pat" "$pat" "$err"
  done

  printf '{"tool_name":"Write","tool_input":{"file_path":"%s"}}' "$T/docs/brief.md" | bash "$H/gd-check.sh" >/dev/null 2>&1; c=$?
  expect_code "gd-check ignores non-.gd files" 0 $c

  # --- session-stop --------------------------------------------------------
  printf '{"stop_hook_active":false}' | bash "$H/session-stop.sh" >/dev/null 2>&1; c=$?
  expect_code "session-stop is quiet with no story in progress" 0 $c

  cat >> "$T/docs/backlog.md" <<'MD'
| S-001 | Player walks | doing | S | yes | - |
MD
  touch -t 202001010000 "$T/production/state.md"
  err="$(printf '{"stop_hook_active":false}' | bash "$H/session-stop.sh" 2>&1 >/dev/null)"; c=$?
  expect_code "session-stop asks for checkpoint when stale" 2 $c
  expect_out "session-stop names changed files" 'game/' "$err"

  printf '{"stop_hook_active":true}' | bash "$H/session-stop.sh" >/dev/null 2>&1; c=$?
  expect_code "session-stop never blocks twice" 0 $c

  out="$(bash "$H/session-start.sh" < /dev/null)"
  expect_out "session-start shows story in progress" 'In progress: S-001' "$out"

  # --- pre-compact ---------------------------------------------------------
  printf '{"trigger":"auto"}' | bash "$H/pre-compact.sh" >/dev/null 2>&1; c=$?
  expect_code "pre-compact exits 0" 0 $c
  if grep -q 'compaction (auto)' "$T/production/state.md"; then ok; else bad "pre-compact logs the compaction"; fi

  # --- fal-budget ----------------------------------------------------------
  F="$H/fal-budget.sh"; L="$T/production/asset-ledger.tsv"; rm -f "$L"
  img='{"tool_name":"mcp__fal__run_model","tool_input":{"model_id":"fal-ai/nano-banana-2/edit","input":{"prompt":"knight","num_images":2,"resolution":"2K"}}}'
  printf '%s' "$img" | bash "$F" pre >/dev/null 2>&1; c=$?
  expect_code "fal-budget allows a listed model within budget" 0 $c
  printf '%s' "$img" | bash "$F" post >/dev/null 2>&1
  expect_out "fal-budget logs the call" 'fal-ai/nano-banana-2/edit	0.2400' "$(cat "$L" 2>/dev/null)"

  err="$(printf '{"tool_name":"mcp__fal__run_model","tool_input":{"model_id":"fal-ai/flux/dev"}}' | bash "$F" pre 2>&1 >/dev/null)"; c=$?
  expect_code "fal-budget refuses an unlisted model" 2 $c
  expect_out "fal-budget lists allowed models" 'nano-banana-2/edit' "$err"

  printf '{"tool_name":"mcp__fal__run_model","tool_input":{"model_id":"fal-ai/nano-banana-2"}}' | bash "$F" post >/dev/null 2>&1
  expect_out "fal-budget prefers exact endpoint (no /edit)" 'fal-ai/nano-banana-2	0.0800' "$(tail -n 1 "$L")"

  printf '{"tool_name":"mcp__fal__submit_job","tool_input":{"endpoint_id":"fal-ai/elevenlabs/sound-effects/v2","input":{"text":"zap","duration_seconds":3}}}' | bash "$F" post >/dev/null 2>&1
  expect_out "fal-budget prices sound by seconds" 'sound-effects/v2	0.0060' "$(tail -n 1 "$L")"

  printf '{"tool_input":{"model":"fal-ai/elevenlabs/music","input":{"music_length_ms":90000}}}' | bash "$F" post >/dev/null 2>&1
  expect_out "fal-budget rounds music up to whole minutes" 'elevenlabs/music	1.6000' "$(tail -n 1 "$L")"

  sed -i.bak 's/^asset_budget_usd:.*/asset_budget_usd: 1/' "$T/project.yaml"
  err="$(printf '%s' "$img" | bash "$F" pre 2>&1 >/dev/null)"; c=$?
  expect_code "fal-budget refuses past the budget" 2 $c
  expect_out "fal-budget names spend and budget" 'of \$1' "$err"
  mv "$T/project.yaml.bak" "$T/project.yaml"

  out="$(bash "$H/session-start.sh" < /dev/null)"
  expect_out "session-start shows asset spend" 'Asset spend: ~\$1\.93 of \$20' "$out"
  out="$(bash "$T/tools/fal-cost.sh")"
  expect_out "fal-cost reports spend" 'spent of \$20' "$out"
  out="$(bash "$T/tools/fal-cost.sh" estimate fal-ai/bria/background/remove 10)"
  expect_out "fal-cost estimates a batch" '~\$0\.18' "$out"

  # --- import-asset --------------------------------------------------------
  src="$T/tmp-src.mp3"; printf 'ID3fake' > "$src"
  out="$(bash "$T/tools/import-asset.sh" "$src" sfx/jump.mp3 --model fal-ai/elevenlabs/sound-effects/v2 --prompt 'short | bouncy jump' --cost 0.002)"; c=$?
  expect_code "import-asset imports a local file" 0 $c
  [ -f "$T/game/assets/sfx/jump.mp3" ] && [ -f "$T/game/assets/_raw/sfx/jump.mp3" ] && ok || bad "import-asset writes file and raw copy"
  [ -f "$T/game/assets/_raw/.gdignore" ] && ok || bad "import-asset hides _raw from Godot"
  expect_out "import-asset records the asset" '\| sfx/jump.mp3 \| fal-ai/elevenlabs/sound-effects/v2 \| short \\\| bouncy jump' "$(cat "$T/game/assets/ASSETS.md")"
  bash "$T/tools/import-asset.sh" "file://$src" game/assets/sfx/jump.mp3 --cost 0.004 >/dev/null 2>&1
  n="$(grep -c '| sfx/jump.mp3 |' "$T/game/assets/ASSETS.md")"
  expect_code "import-asset replaces the row on re-import" 1 "$n"
  bash "$T/tools/import-asset.sh" "$src" ../../escape.mp3 >/dev/null 2>&1; c=$?
  expect_code "import-asset refuses paths outside game/assets" 2 $c
  printf 'PNG' > "$T/tmp.png"
  out="$(bash "$T/tools/import-asset.sh" "$T/tmp.png" sprites/a.png --trim --pixel 32 2>&1)"
  expect_out "import-asset says when processing is skipped" 'processing skipped' "$out"

  rm -rf "$T"
}

run_suite "with jq"
export GSL_NO_JQ=1
run_suite "without jq"
unset GSL_NO_JQ CLAUDE_PROJECT_DIR

echo ""
echo "hooks: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
