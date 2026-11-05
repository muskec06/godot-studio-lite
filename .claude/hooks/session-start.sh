#!/bin/bash
# SessionStart: inject a short project status. Runs on startup, resume, /clear
# and after compaction. Must stay fast and small: everything printed here
# lands in context every session.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
cd "$ROOT" 2>/dev/null || exit 0

echo "## Godot Studio Lite — session context"
echo "Mode: $(cfg mode jam) · $(cfg platform desktop)$([ "$(cfg platform desktop)" = mobile ] && echo " $(cfg orientation portrait)") · Godot $(cfg godot_version '?') · $(cfg language gdscript) · tests: $(cfg test_framework gdunit4)"

if [ -f production/asset-ledger.tsv ]; then
  . "$(dirname "${BASH_SOURCE[0]}")/fal-lib.sh"
  echo "Asset spend: ~\$$(fal_spent) of \$$(cfg asset_budget_usd 20) (fal.ai, estimated)"
fi

story="$(doing_story)"
[ -n "$story" ] && echo "In progress: $story"

cp="$(checkpoint)"
if [ -n "$cp" ]; then
  echo ""
  echo "Checkpoint (production/state.md):"
  printf '%s\n' "$cp"
fi

# Setup gaps, one line each, only when present.
notes=""
[ -f game/project.godot ] || notes="$notes\n- No game/project.godot yet: run /start."
[ -n "$(godot_bin)" ] || notes="$notes\n- Godot executable not found (set godot_bin in project.yaml): parse checks and test runs are skipped."
if [ -f game/project.godot ] && [ ! -f game/addons/gsl_tools/parse_check.gd ]; then
  notes="$notes\n- Helper scripts missing in game/addons/gsl_tools: run bash tools/setup-godot.sh."
fi
command -v jq >/dev/null 2>&1 || notes="$notes\n- jq not installed: hooks use a simpler JSON parser."
if [ "$(cfg test_framework gdunit4)" = "gdunit4" ] && [ -f game/project.godot ] && [ ! -d game/addons/gdUnit4 ]; then
  notes="$notes\n- gdUnit4 is not installed (game/addons/gdUnit4): /start can install it."
fi
if [ -n "$notes" ]; then
  echo ""
  echo "Setup notes:"
  printf "%b\n" "${notes#\\n}"
fi
exit 0
