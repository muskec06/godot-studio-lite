#!/bin/bash
# Download gdUnit4 into game/addons/gdUnit4 from its GitHub release.
# Network access: only github.com. Ask the user before running this.
# Usage: bash tools/install-gdunit4.sh [tag]   (default v6.2.2, verified on Godot 4.7.2)
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 1

tag="${1:-v6.2.2}"
url="https://github.com/godot-gdunit-labs/gdUnit4/archive/refs/tags/${tag}.zip"
[ -f game/project.godot ] || { echo "run tools/setup-godot.sh first"; exit 1; }
if [ -d game/addons/gdUnit4 ]; then echo "game/addons/gdUnit4 already exists; remove it to reinstall"; exit 0; fi
command -v unzip >/dev/null 2>&1 || { echo "unzip is required"; exit 1; }

tmp="$(mktemp -d 2>/dev/null || mktemp -d -t gdunit)"
echo "downloading $url"
if command -v curl >/dev/null 2>&1; then curl -fsSL "$url" -o "$tmp/g.zip"; else wget -q "$url" -O "$tmp/g.zip"; fi || { echo "download failed"; exit 1; }
unzip -q "$tmp/g.zip" -d "$tmp/x" || { echo "unzip failed"; exit 1; }
src="$(find "$tmp/x" -type d -path '*/addons/gdUnit4' | head -n 1)"
[ -n "$src" ] || { echo "addons/gdUnit4 not found in the archive"; exit 1; }
mkdir -p game/addons
cp -R "$src" game/addons/
rm -rf "$tmp"
echo "installed gdUnit4 $tag to game/addons/gdUnit4"
echo "Enable it in the editor (Project > Project Settings > Plugins) for the test panel; the command-line runner works without that."
gb="$(godot_bin)"
[ -n "$gb" ] && "$gb" --headless --path game --import >/dev/null 2>&1 && echo "re-imported"
exit 0
