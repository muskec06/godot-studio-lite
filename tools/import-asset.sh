#!/bin/bash
# Bring one generated file into the game and record it in game/assets/ASSETS.md.
#
#   bash tools/import-asset.sh <url-or-path> <dest> [options]
#
#   <url-or-path>  fal output URL (https://…fal.media/…) or a local file
#   <dest>         path under game/assets/, e.g. sprites/player_idle.png, sfx/jump.mp3
#
# Options (images; need Godot + tools/setup-godot.sh, otherwise skipped with a note):
#   --trim              crop to non-transparent pixels (after background removal)
#   --pixel <height>    downscale to <height> px tall, hard alpha, palette from
#                       game/assets/_style/palette.hex when it exists
#   --fit <w>x<h>       resize to exactly w × h (backgrounds, UI)
#   --no-raw            do not keep a copy in _raw/ (the source lives elsewhere,
#                       e.g. vector templates built by tools/svg-build.sh)
# Record keeping (all recommended):
#   --model <endpoint>  --prompt "<text>"  --cost <usd>  --note "<text>"
#
# Keeps the untouched original in game/assets/_raw/ so processing can be redone
# without paying for a new generation. Prints the final path.
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 1

src="${1:-}"; dest="${2:-}"
[ -n "$src" ] && [ -n "$dest" ] || { sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
shift 2
trim=0; pixel=""; fit=""; model=""; prompt=""; cost=""; note=""; keep_raw=1
while [ $# -gt 0 ]; do
  case "$1" in
    --trim) trim=1 ;;
    --no-raw) keep_raw=0 ;;
    --pixel) pixel="${2:-}"; shift ;;
    --fit) fit="${2:-}"; shift ;;
    --model) model="${2:-}"; shift ;;
    --prompt) prompt="${2:-}"; shift ;;
    --cost) cost="${2:-}"; shift ;;
    --note) note="${2:-}"; shift ;;
    *) echo "unknown option $1"; exit 2 ;;
  esac
  shift
done

case "$dest" in /*|*..*) echo "dest must be a relative path under game/assets/"; exit 2 ;; esac
dest="${dest#game/assets/}"
out="game/assets/$dest"
if [ "$keep_raw" -eq 1 ]; then
  raw="game/assets/_raw/$dest"
  mkdir -p "$(dirname "$raw")"
  # Godot must not import the originals.
  [ -f game/assets/_raw/.gdignore ] || : > game/assets/_raw/.gdignore
else
  # Built from a source we keep elsewhere (vector templates): no copy needed.
  raw="$(mktemp 2>/dev/null || mktemp -t raw)"
  trap 'rm -f "$raw"' EXIT
fi
mkdir -p "$(dirname "$out")"

# 1. Fetch the original.
case "$src" in
  http://*|https://*|file://*)
    if ! curl -fsSL --retry 2 "$src" -o "$raw"; then echo "download failed: $src (fal URLs expire after ~7 days)"; exit 1; fi ;;
  *)
    [ -f "$src" ] || { echo "no such file: $src"; exit 1; }
    cp "$src" "$raw" ;;
esac
[ -s "$raw" ] || { echo "downloaded file is empty"; exit 1; }

# 2. Process images with Godot when asked.
processed="none"
is_image=0; case "$dest" in *.png|*.PNG|*.webp|*.jpg|*.jpeg) is_image=1 ;; esac
wants=0; { [ $trim -eq 1 ] || [ -n "$pixel" ] || [ -n "$fit" ]; } && wants=1
cp "$raw" "$out"
if [ $is_image -eq 1 ] && [ $wants -eq 1 ]; then
  gb="$(godot_bin)"
  if [ -z "$gb" ] || [ ! -f game/addons/gsl_tools/image_tool.gd ]; then
    processed="skipped (no Godot or tools/setup-godot.sh not run)"
    echo "note: image processing skipped — the file is unprocessed. Run it again after setting up Godot."
  else
    case "$out" in *.png) ;; *) rm -f "$out"; out="${out%.*}.png" ;; esac
    tool() { "$gb" --headless --path game -s res://addons/gsl_tools/image_tool.gd -- "$@" 2>&1 | grep -E 'wrote|image_tool|ERROR' ; return "${PIPESTATUS[0]}"; }
    absraw="$ROOT/$raw"; absout="$ROOT/$out"; cur="$absraw"; steps=""
    if [ $trim -eq 1 ]; then tool trim "$cur" "$absout" 1 || exit 1; cur="$absout"; steps="$steps trim"; fi
    if [ -n "$fit" ]; then
      w="${fit%x*}"; h="${fit#*x}"
      tool fit "$cur" "$absout" "$w" "$h" || exit 1; cur="$absout"; steps="$steps fit:$fit"
    fi
    if [ -n "$pixel" ]; then
      pal=""; [ -f game/assets/_style/palette.hex ] && pal="$ROOT/game/assets/_style/palette.hex"
      tool pixelate "$cur" "$absout" "$pixel" "$pal" || exit 1; steps="$steps pixel:$pixel${pal:+ +palette}"
    fi
    processed="${steps# }"
  fi
fi

# 3. Record it.
manifest="game/assets/ASSETS.md"
if [ ! -f "$manifest" ]; then
  cat > "$manifest" <<'MD'
# Assets

Every file under game/assets/ that ships, where it came from, and what it cost.
Written by tools/import-asset.sh. Sources: `claude-vector` = drawn by Claude as
SVG templates in _src/ (built by tools/svg-build.sh); fal.ai models marked
"Commercial use" on their model pages, with originals in _raw/.

| File | Source | Prompt | Processing | Est. USD | Date | Note |
|---|---|---|---|---|---|---|
MD
fi
# Re-importing the same file replaces its row.
if grep -qF "| ${out#game/assets/} |" "$manifest"; then
  grep -vF "| ${out#game/assets/} |" "$manifest" > "$manifest.tmp" && mv "$manifest.tmp" "$manifest"
fi
esc() { printf '%s' "$1" | tr '\n' ' ' | sed 's/|/\\|/g' | cut -c1-300; }
src_label="${model:-$(case "$src" in http*) echo url;; *) echo local;; esac)}"
printf '| %s | %s | %s | %s | %s | %s | %s |\n' \
  "${out#game/assets/}" "$(esc "$src_label")" "$(esc "$prompt")" "$(esc "$processed")" \
  "${cost:--}" "$(date '+%Y-%m-%d')" "$(esc "$note")" >> "$manifest"

echo "$out"
