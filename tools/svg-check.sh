#!/bin/bash
# Check SVG files (and *.svg.tpl templates) against what Godot's SVG renderer
# (ThorVG) draws reliably, and against the project's design tokens.
#
#   bash tools/svg-check.sh <file.svg|file.svg.tpl> ...
#
# Errors (exit 1): no <svg> root, no viewBox/width/height, unsupported or
# unsafe content (<text>, filters, <style>, scripts, animation, external or
# embedded images, blend modes), a template token missing from tokens.json,
# a file over 150 KB. Warnings: colours that are not design tokens.
# Godot draws no SVG text: convert lettering to paths (the kit's logo shows how).
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 2
[ $# -gt 0 ] || { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

TOKENS=game/assets/_style/tokens.json
token_keys() { grep -oE '"[a-z0-9_]+"[[:space:]]*:' "$TOKENS" 2>/dev/null | sed -E 's/"([a-z0-9_]+)".*/\1/' | sort -u; }
token_colors() { grep -oiE '"#[0-9a-f]{6}"' "$TOKENS" 2>/dev/null | tr -d '"' | tr 'A-F' 'a-f' | sort -u; }

errors=0
for f in "$@"; do
  [ -f "$f" ] || { echo "ERROR: $f: no such file"; errors=$((errors+1)); continue; }
  e() { echo "ERROR: $f: $*"; errors=$((errors+1)); }
  body="$(tr '\n' ' ' < "$f")"
  root="$(printf '%s' "$body" | grep -oE '<svg[^>]*>' | head -n 1)"
  [ -n "$root" ] || { e "no <svg> root element"; continue; }
  printf '%s' "$root" | grep -q 'viewBox=' || e "root <svg> needs a viewBox"
  printf '%s' "$root" | grep -qE ' width="[0-9.]+"' || e 'root <svg> needs width="N" (Godot rasterizes at width × height)'
  printf '%s' "$root" | grep -qE ' height="[0-9.]+"' || e 'root <svg> needs height="N"'
  for pat in '<text' '<tspan' '<textPath' '<filter' 'filter=' '<foreignObject' '<animate' '<set ' '<script' '<style' '<image' 'mix-blend-mode' '@import' '[[:space:]]on[a-z]+="'; do
    if printf '%s' "$body" | grep -qiE -- "$pat"; then
      case "$pat" in
        '<text'|'<tspan'|'<textPath') e "contains text ($pat): Godot does not draw SVG text — convert it to paths, or draw the text with a Label" ;;
        '<filter'|'filter=') e "uses SVG filters (blur, drop shadow…): not reliable in Godot — fake shadows with a semi-transparent shape, blur with a shader" ;;
        '<animate'|'<set ') e "uses SVG animation: animate in Godot (Tween/AnimationPlayer) instead" ;;
        '<image') e "embeds or links an image: keep vectors only" ;;
        *) e "contains $pat: not allowed in game SVGs" ;;
      esac
    fi
  done
  printf '%s' "$body" | grep -qiE '(xlink:)?href="(https?:|data:|file:)' && e "references an external resource"
  kb="$(file_kb "$f")"; [ "$kb" -le 150 ] || e "is ${kb} KB (limit 150): simplify paths"

  if [ -f "$TOKENS" ]; then
    case "$f" in
      *.svg.tpl)
        missing="$(grep -oE '\{\{[a-z0-9_]+\}\}' "$f" | tr -d '{}' | sort -u | comm -23 - <(token_keys) | tr '\n' ' ')"
        [ -n "$missing" ] && e "tokens missing from $TOKENS: $missing"
        hard="$(grep -oiE '#[0-9a-f]{6}\b' "$f" | tr 'A-F' 'a-f' | sort -u | tr '\n' ' ')"
        [ -n "$hard" ] && echo "warn:  $f: hard-coded colours in a template (use tokens): $hard"
        ;;
      *)
        off="$(grep -oiE '#[0-9a-f]{6}\b' "$f" | tr 'A-F' 'a-f' | sort -u | comm -23 - <(token_colors) | tr '\n' ' ')"
        [ -n "$off" ] && echo "warn:  $f: colours not in the design tokens: $off"
        ;;
    esac
  fi
done
[ "$errors" -eq 0 ] && echo "svg-check: $# file(s) OK"
[ "$errors" -eq 0 ]
