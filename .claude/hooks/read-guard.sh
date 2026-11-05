#!/bin/bash
# PreToolUse(Read): refuse a whole-file read of a large Markdown doc in docs/
# or production/ and hand back its headings with line numbers, so the retry
# reads only the section it needs. A read with offset or limit always passes.
#
# exit 0 = allow · exit 2 = refuse (stderr is shown to Claude)
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
INPUT="$(cat 2>/dev/null)"

path="$(json_get file_path)"
[ -n "$path" ] || exit 0
[ -n "$(json_get offset)" ] && exit 0
[ -n "$(json_get limit)" ] && exit 0

rel="$(rel_to_root "$path")"
case "$rel" in
  docs/*.md|production/*.md) ;;
  *) exit 0 ;;
esac

abs="$ROOT/$rel"
[ -f "$abs" ] || exit 0
limit_kb="$(cfg read_guard_kb 40)"
kb="$(file_kb "$abs")"
[ "$kb" -gt "$limit_kb" ] 2>/dev/null || exit 0

{
  echo "Refused: $rel is ${kb} KB (limit ${limit_kb} KB). Read only the section you need, with offset and limit."
  echo "Headings (line: heading):"
  grep -n -E '^#{1,4} ' "$abs" | head -n 60 | sed -E 's/^([0-9]+):/  \1: /'
} >&2
exit 2
