#!/bin/bash
# Download the kit's fonts into game/assets/fonts/ from Google Fonts' GitHub
# repository: Baloo 2 (headings) and Rubik (body), variable TTFs, both under
# the SIL Open Font License 1.1 (licence files saved next to them; the OFL
# allows bundling them in a commercial game). Network: github.com only.
# Ask the user before running. Usage: bash tools/install-fonts.sh
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 1
base="https://raw.githubusercontent.com/google/fonts/main/ofl"
mkdir -p game/assets/fonts
get() { # url dest
  if [ -s "$2" ]; then echo "kept $2"; return 0; fi
  curl -fsSL --retry 2 "$1" -o "$2" && echo "downloaded $2" || { echo "download failed: $1"; rm -f "$2"; return 1; }
}
ok=0
get "$base/baloo2/Baloo2%5Bwght%5D.ttf" game/assets/fonts/Baloo2.ttf || ok=1
get "$base/baloo2/OFL.txt" game/assets/fonts/Baloo2-OFL.txt || ok=1
get "$base/rubik/Rubik%5Bwght%5D.ttf" game/assets/fonts/Rubik.ttf || ok=1
get "$base/rubik/OFL.txt" game/assets/fonts/Rubik-OFL.txt || ok=1
if [ $ok -eq 0 ] && [ -f game/assets/ASSETS.md ]; then
  for f in Baloo2.ttf Rubik.ttf; do
    grep -qF "| fonts/$f |" game/assets/ASSETS.md || \
      printf '| fonts/%s | Google Fonts | - | none | 0 | %s | SIL OFL 1.1, licence in fonts/%s |\n' "$f" "$(date '+%Y-%m-%d')" "${f%.ttf}-OFL.txt" >> game/assets/ASSETS.md
  done
fi
exit $ok
