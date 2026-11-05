#!/bin/bash
# PostToolUse(Write|Edit) on *.svg / *.svg.tpl: run tools/svg-check.sh on the
# file just written. Problems go to Claude (exit 2) so the file is fixed
# before it is used. Other files: exit 0.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
INPUT="$(cat 2>/dev/null)"
path="$(json_get file_path)"
case "$path" in *.svg|*.svg.tpl) ;; *) exit 0 ;; esac
rel="$(rel_to_root "$path")"
[ -n "$rel" ] && [ -f "$ROOT/$rel" ] || exit 0
out="$(bash "$ROOT/tools/svg-check.sh" "$ROOT/$rel" 2>&1)" && { printf '%s\n' "$out" | grep '^warn' >&2; exit 0; }
{ echo "svg-check: $rel needs fixing:"; printf '%s\n' "$out" | grep -E '^(ERROR|warn)'; } >&2
exit 2
