#!/bin/bash
# Turn on an optional profile: copies its rules, skills and code templates into
# place and updates project.yaml. Safe to run again: never overwrites a file
# that already exists (it says which ones it kept).
#
#   bash tools/apply-profile.sh mobile [portrait|landscape]
#
# Profiles live in tools/profiles/<name>/ with the same layout as the repo:
#   .claude/rules/…   .claude/skills/…   game/…   docs/…
# A profile may add autoloads listed in tools/profiles/<name>/autoloads.txt
# (lines: Name res://path.gd); they are registered in game/project.godot now if
# it exists, and again on every tools/setup-godot.sh run.
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 1

prof="${1:-}"
[ -n "$prof" ] && [ -d "tools/profiles/$prof" ] || { echo "usage: apply-profile.sh <$(ls tools/profiles | tr '\n' '|' | sed 's/|$//')> [options]"; exit 2; }
src="tools/profiles/$prof"

# project.yaml keys (flat `key: value` lines; keep the trailing comment).
yaml_set() {
  if grep -qE "^$1:" project.yaml; then
    sed -i.bak -E "s|^($1:[[:space:]]*)[^#[:space:]]+([[:space:]]*#.*)?$|\1$2\2|" project.yaml && rm -f project.yaml.bak
  else
    echo "$1: $2" >> project.yaml
  fi
}

case "$prof" in
  mobile)
    orient="${2:-portrait}"
    case "$orient" in portrait|landscape) ;; *) echo "orientation must be portrait or landscape"; exit 2 ;; esac
    yaml_set platform mobile
    yaml_set orientation "$orient"
    ;;
esac

# Profile settings: tools/profiles/<name>/settings.txt, lines "key value".
if [ -f "$src/settings.txt" ]; then
  while read -r k v; do
    [ -n "$k" ] && [ "${k#\#}" = "$k" ] || continue
    yaml_set "$k" "$v"; echo "project.yaml: $k = $v"
  done < "$src/settings.txt"
fi

copied=0; kept=""
while IFS= read -r f; do
  rel="${f#"$src"/}"
  case "$rel" in autoloads.txt|settings.txt|README.md) continue ;; esac
  if [ -e "$rel" ]; then kept="$kept $rel"; continue; fi
  mkdir -p "$(dirname "$rel")"
  cp "$f" "$rel"
  copied=$((copied+1))
done < <(find "$src" -type f | sort)
echo "profile $prof: $copied files added"
[ -n "$kept" ] && echo "kept existing:$kept"

if [ -f "$src/autoloads.txt" ]; then
  if [ -f game/project.godot ]; then
    while read -r name path; do
      [ -n "$name" ] && [ "${name#\#}" = "$name" ] || continue
      godot_ini_set game/project.godot autoload "$name" "\"*$path\""
      echo "autoload: $name -> $path"
    done < "$src/autoloads.txt"
  else
    echo "autoloads will be registered after game/project.godot exists (run this again after tools/setup-godot.sh)"
  fi
fi

[ -f game/project.godot ] && bash tools/setup-godot.sh | grep -E '^settings:'
exit 0
