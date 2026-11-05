#!/bin/bash
# Shared helpers for Godot Studio Lite hooks. Source this file; it defines
# functions only and never exits. Bash 3.2+ (macOS), Git Bash and Linux.

# Project root: CLAUDE_PROJECT_DIR when it holds project.yaml, else two levels
# above this file (.claude/hooks/ -> root).
gsl_root() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "$CLAUDE_PROJECT_DIR/project.yaml" ]; then
    printf '%s' "$CLAUDE_PROJECT_DIR"
  else
    (cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)
  fi
}
ROOT="$(gsl_root)"

# cfg KEY [DEFAULT] -> value of a flat `key: value` line in project.yaml.
# Strips a trailing `# comment` and surrounding double quotes.
cfg() {
  local key="$1" def="${2:-}" v
  v=$(grep -E "^${key}:" "$ROOT/project.yaml" 2>/dev/null | head -n 1 \
      | sed -E "s/^${key}:[[:space:]]*//; s/[[:space:]]+#.*$//; s/^\"(.*)\"$/\1/; s/[[:space:]]+$//")
  if [ -n "$v" ]; then printf '%s' "$v"; else printf '%s' "$def"; fi
}

# json_get KEY -> first string or number value of "KEY" in $INPUT.
# Uses jq when present; otherwise a sed fallback that is good enough for the
# simple fields hooks need (file_path, offset, limit, stop_hook_active).
json_get() {
  local key="$1"
  if [ -z "${GSL_NO_JQ:-}" ] && command -v jq >/dev/null 2>&1; then
    printf '%s' "$INPUT" | jq -r --arg k "$key" '[.. | objects | select(has($k)) | .[$k]] | first // empty' 2>/dev/null
  else
    printf '%s' "$INPUT" | tr '\n' ' ' \
      | sed -n -E "s/.*\"${key}\"[[:space:]]*:[[:space:]]*(\"([^\"\\\\]|\\\\.)*\"|[0-9]+|true|false|null).*/\1/p" \
      | head -n 1 | sed -E 's/^"//; s/"$//; s/^null$//'
  fi
}

# Normalise a path to forward slashes (Git Bash may hand us C:\...).
norm_path() { printf '%s' "$1" | sed 's#\\#/#g'; }

# rel_to_root PATH -> PATH relative to $ROOT, or empty if outside it.
rel_to_root() {
  local p r
  p="$(norm_path "$1")"
  r="$(norm_path "$ROOT")"
  case "$p" in
    "$r"/*) printf '%s' "${p#"$r"/}" ;;
    /*|[A-Za-z]:/*) printf '' ;;
    *) printf '%s' "$p" ;;
  esac
}

# file_kb PATH -> size in whole KB (portable: wc, not stat).
file_kb() { local b; b=$(wc -c < "$1" 2>/dev/null | tr -d ' '); echo $(( ${b:-0} / 1024 )); }

# godot_bin -> path to a Godot executable, or empty.
godot_bin() {
  local b
  b="$(cfg godot_bin)"
  if [ -n "$b" ] && [ -x "$b" ]; then printf '%s' "$b"; return; fi
  for b in godot godot4 Godot godot.exe Godot.exe; do
    if command -v "$b" >/dev/null 2>&1; then command -v "$b"; return; fi
  done
}

# godot_ini_set FILE SECTION KEY VALUE -> set KEY=VALUE under [SECTION] of a
# Godot .godot/.cfg file: replaces an existing key in that section, else adds
# it at the end of the section, else appends the section. VALUE is written as
# given (quote strings yourself: '"portrait"').
godot_ini_set() {
  local f="$1" sec="$2" key="$3" val="$4" tmp
  [ -f "$f" ] || return 1
  tmp="$f.tmp.$$"
  awk -v sec="[$sec]" -v key="$key" -v val="$val" '
    /^\[/ {
      if (insec && !done) { print key "=" val; print ""; done=1 }
      insec = ($0 == sec)
      print; next
    }
    insec && index($0, key "=") == 1 { if (!done) { print key "=" val; done=1 } ; next }
    { print }
    END {
      if (insec && !done) { print key "=" val; done=1 }
      if (!done) { print ""; print sec; print ""; print key "=" val }
    }' "$f" > "$tmp" && mv "$tmp" "$f"
}

# checkpoint -> the lines between <!-- CHECKPOINT --> and <!-- /CHECKPOINT -->,
# capped at 25 lines.
checkpoint() {
  awk '/<!-- CHECKPOINT -->/{f=1;next} /<!-- \/CHECKPOINT -->/{f=0} f' \
    "$ROOT/production/state.md" 2>/dev/null | head -n 25
}

# doing_story -> the backlog table row whose status is `doing`, if any.
doing_story() {
  grep -E '^\|[^|]*\|[^|]*\|[[:space:]]*doing[[:space:]]*\|' "$ROOT/docs/backlog.md" 2>/dev/null \
    | head -n 1 | awk -F'|' '{gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$3); print $2" "$3}'
}
