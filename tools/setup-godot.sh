#!/bin/bash
# Prepare game/ as a Godot 4 project for this workflow. Safe to run again.
#   - creates game/project.godot if missing (name and version from project.yaml)
#   - applies display/render settings for platform (desktop|mobile),
#     orientation and art_style from project.yaml — on every run, so changing
#     project.yaml and re-running brings an existing project in line
#   - creates the standard folders, installs helper scripts to
#     game/addons/gsl_tools/, runs a first headless import when Godot exists
# No network access. Usage: bash tools/setup-godot.sh
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 1

name="$(cfg name)"; [ -n "$name" ] || name="New Game"
ver="$(cfg godot_version 4.7)"
platform="$(cfg platform desktop)"
orient="$(cfg orientation landscape)"
art="$(cfg art_style pixel)"

mkdir -p game/scenes game/scripts game/resources game/tests game/addons/gsl_tools game/assets/{sprites,ui,backgrounds,tiles,sfx,music,store,_style}
: > game/assets/_style/.gdignore   # style references are for generation, not the game

P=game/project.godot
if [ ! -f "$P" ]; then
  cat > "$P" <<EOF
; Engine configuration file. Created by tools/setup-godot.sh.

config_version=5

[application]

config/name="$name"
config/features=PackedStringArray("$ver")
EOF
  echo "created $P ($name, Godot $ver)"
fi

set_() { godot_ini_set "$P" "$1" "$2" "$3"; }

# Resolution and orientation.
if [ "$platform" = "mobile" ] && [ "$orient" = "portrait" ]; then w=720; h=1280; else w=1280; h=720; fi
set_ display window/size/viewport_width "$w"
set_ display window/size/viewport_height "$h"
set_ display window/stretch/mode '"canvas_items"'

if [ "$platform" = "mobile" ]; then
  # Fill any phone aspect ratio (no letterboxing); the UI anchors to the edges
  # and the safe area. Integer scaling would leave bars on most phones.
  set_ display window/stretch/aspect '"expand"'
  set_ display window/stretch/scale_mode '"fractional"'
  if [ "$orient" = "portrait" ]; then set_ display window/handheld/orientation 1; else set_ display window/handheld/orientation 0; fi
  set_ input_devices pointing/emulate_touch_from_mouse true
  set_ application config/quit_on_go_back false
  # Compatibility renderer: widest device support, lowest overhead for 2D.
  set_ rendering renderer/rendering_method '"gl_compatibility"'
  set_ rendering renderer/rendering_method.mobile '"gl_compatibility"'
  set_ rendering textures/vram_compression/import_etc2_astc true
elif [ "$art" = "pixel" ]; then
  set_ display window/stretch/scale_mode '"integer"'
fi

if [ "$art" = "pixel" ]; then
  set_ rendering textures/canvas_textures/default_texture_filter 0
  set_ rendering 2d/snap/snap_2d_transforms_to_pixel true
fi
echo "settings: platform $platform, ${w}x${h}, art_style $art$([ "$platform" = mobile ] && echo ", $orient")"

# Autoloads of every applied profile (tools/profiles/*/autoloads.txt): an
# autoload is registered when its script is in game/, i.e. the profile was applied.
for al in tools/profiles/*/autoloads.txt; do
  [ -f "$al" ] || continue
  while read -r an ap; do
    [ -n "$an" ] && [ "${an#\#}" = "$an" ] || continue
    [ -f "game/${ap#res://}" ] || continue
    godot_ini_set "$P" autoload "$an" "\"*$ap\""
  done < "$al"
done

cp tools/godot/*.gd game/addons/gsl_tools/
echo "installed game/addons/gsl_tools/ (parse_check, screenshot, image_tool)"

gb="$(godot_bin)"
if [ -z "$gb" ]; then
  echo "Godot executable not found: set godot_bin in project.yaml, then run this again to import."
  exit 0
fi

echo "importing with $gb ..."
for attempt in 1 2; do
  "$gb" --headless --path game --import >/tmp/gsl-import.log 2>&1
  code=$?
  # 4.7.1/4.7.2 sometimes segfault (139) on exit of a first import after the
  # files are written; a second run exits cleanly.
  [ $code -eq 0 ] && break
  echo "import exited $code (attempt $attempt)"
done
if [ -d game/.godot ]; then echo "import done (game/.godot present)"; else echo "import failed: see /tmp/gsl-import.log"; exit 1; fi
