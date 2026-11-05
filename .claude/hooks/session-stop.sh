#!/bin/bash
# Stop: when a story is in progress, work files changed after the checkpoint,
# and the checkpoint is more than 20 minutes old, ask Claude once to refresh
# the CHECKPOINT block before ending the turn. Never blocks twice in a row
# (stop_hook_active), so it cannot loop.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
INPUT="$(cat 2>/dev/null)"
[ "$(json_get stop_hook_active)" = "true" ] && exit 0
cd "$ROOT" 2>/dev/null || exit 0

state="production/state.md"
[ -f "$state" ] || exit 0
[ -n "$(doing_story)" ] || exit 0

changed="$(find game docs -type f -newer "$state" -not -path '*/.godot/*' -not -name '*.import' 2>/dev/null | head -n 5)"
[ -n "$changed" ] || exit 0

# Age of state.md in seconds, portable: compare against a marker file.
marker="${TMPDIR:-/tmp}/gsl-stop-$$"
stamp="$(date -d '-20 minutes' '+%Y%m%d%H%M' 2>/dev/null || date -v-20M '+%Y%m%d%H%M' 2>/dev/null)"
[ -n "$stamp" ] || exit 0
touch -t "$stamp" "$marker" 2>/dev/null || exit 0
if [ "$state" -nt "$marker" ]; then rm -f "$marker"; exit 0; fi
rm -f "$marker"

{
  echo "Before stopping: update the CHECKPOINT block in production/state.md (overwrite it, ≤ 25 lines)."
  echo "Files changed since it was written:"
  printf '%s\n' "$changed" | sed 's/^/  /'
} >&2
exit 2
