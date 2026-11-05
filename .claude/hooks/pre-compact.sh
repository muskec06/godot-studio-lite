#!/bin/bash
# PreCompact: record the compaction in the state log so a later reader can see
# where context was lost. The checkpoint itself is re-injected by
# session-start.sh after compaction, so nothing else is needed here.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
INPUT="$(cat 2>/dev/null)"
state="$ROOT/production/state.md"
[ -f "$state" ] || exit 0

trigger="$(json_get trigger)"
printf -- '- %s compaction (%s)\n' "$(date '+%Y-%m-%d %H:%M')" "${trigger:-unknown}" >> "$state"

updated="$(checkpoint | grep -E '^Updated:' | head -n 1)"
echo "Compacting. Checkpoint ${updated:-has no Updated line}. Read production/state.md after compaction."
exit 0
