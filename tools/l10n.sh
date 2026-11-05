#!/bin/bash
# Localization helper. Strings live in one CSV that Godot imports into one
# .translation file per language (game/locale/strings.<lang>.translation).
#
#   bash tools/l10n.sh setup   create game/locale/strings.csv (columns from
#                              `languages` in project.yaml, first = source)
#                              and register the translations in project.godot
#   bash tools/l10n.sh check   report: missing languages, empty cells,
#                              placeholder mismatches, keys used in code but
#                              not in the CSV, possibly unused keys,
#                              hard-coded player-facing text
#
# Keys are UPPER_SNAKE_CASE ("MENU_PLAY"). Use them as tr("MENU_PLAY") in
# code, or as the text of a Label/Button in a scene (Godot translates it).
# check exits 1 on errors (missing key, empty cell, placeholder mismatch,
# unregistered language), 0 otherwise; warnings never fail.
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 2

CSV=game/locale/strings.csv
langs="$(cfg languages en)"
src_lang="${langs%% *}"

# csv_rows: print the CSV as tab-separated fields (handles "quoted, fields"
# and "" escapes; no newlines inside fields).
csv_rows() {
  awk '
    {
      line = $0; out = ""; field = ""; q = 0
      for (i = 1; i <= length(line); i++) {
        ch = substr(line, i, 1)
        if (q) {
          if (ch == "\"") { if (substr(line, i + 1, 1) == "\"") { field = field "\""; i++ } else q = 0 }
          else field = field ch
        } else if (ch == "\"") q = 1
        else if (ch == ",") { out = out field "\t"; field = "" }
        else field = field ch
      }
      sub(/\r$/, "", field)
      print out field
    }' "$1"
}

case "${1:-}" in
  setup)
    mkdir -p game/locale
    if [ ! -f "$CSV" ]; then
      header="keys"; for l in $langs; do header="$header,$l"; done
      {
        echo "$header"
        row="MENU_PLAY"; for l in $langs; do case "$l" in en) row="$row,Play";; tr) row="$row,Oyna";; *) row="$row,";; esac; done; echo "$row"
        row="MENU_SETTINGS"; for l in $langs; do case "$l" in en) row="$row,Settings";; tr) row="$row,Ayarlar";; *) row="$row,";; esac; done; echo "$row"
      } > "$CSV"
      echo "created $CSV ($langs)"
    else
      echo "$CSV exists, left unchanged"
    fi
    if [ -f game/project.godot ]; then
      list=""; for l in $langs; do list="$list${list:+, }\"res://locale/strings.$l.translation\""; done
      godot_ini_set game/project.godot internationalization locale/translations "PackedStringArray($list)"
      godot_ini_set game/project.godot internationalization locale/fallback "\"$src_lang\""
      echo "registered translations: $langs (fallback $src_lang)"
      echo "Godot imports the CSV on the next editor start or: bash tools/setup-godot.sh"
    else
      echo "game/project.godot missing: run tools/setup-godot.sh, then this again"
    fi
    ;;

  check)
    [ -f "$CSV" ] || { echo "l10n: $CSV missing (bash tools/l10n.sh setup)"; exit 1; }
    tmp="$(mktemp -d 2>/dev/null || mktemp -d -t l10n)"
    csv_rows "$CSV" > "$tmp/rows.tsv"
    errors=0; warnings=0
    err()  { errors=$((errors+1)); echo "ERROR: $*"; }
    warn() { warnings=$((warnings+1)); echo "warn:  $*"; }

    # Columns.
    header="$(head -n 1 "$tmp/rows.tsv")"
    for l in $langs; do
      printf '%s\n' "$header" | tr '\t' '\n' | grep -qx "$l" || err "language column '$l' (from project.yaml) missing in $CSV"
    done

    # Duplicates, empty cells, placeholder mismatches.
    awk -F'\t' -v src="$src_lang" '
      NR == 1 { ncol = NF; for (i = 2; i <= NF; i++) { col[i] = $i; if ($i == src) s = i } ; next }
      $1 == "" || $1 ~ /^#/ { next }
      {
        if ($1 in seen) print "ERROR: duplicate key " $1; seen[$1] = 1
        for (i = 2; i <= ncol; i++) {
          if ($i == "") print "ERROR: " $1 " has no " col[i] " text"
        }
        if (s) {
          ref = ph($s)
          for (i = 2; i <= ncol; i++) if (i != s && $i != "" && ph($i) != ref)
            print "ERROR: " $1 " placeholders differ: " col[s] " [" ref "] vs " col[i] " [" ph($i) "]"
        }
      }
      function ph(t,   n, a, i, j, out, m) {
        n = 0
        while (match(t, /%[-0-9.]*[sdif]|\{[A-Za-z_][A-Za-z0-9_]*\}/)) { a[++n] = substr(t, RSTART, RLENGTH); t = substr(t, RSTART + RLENGTH) }
        # sort so order differences between languages are allowed
        for (i = 2; i <= n; i++) { m = a[i]; j = i - 1; while (j > 0 && a[j] > m) { a[j+1] = a[j]; j-- } a[j+1] = m }
        out = ""; for (i = 1; i <= n; i++) out = out (i > 1 ? " " : "") a[i]
        return out
      }' "$tmp/rows.tsv" > "$tmp/csv-issues.txt"
    while IFS= read -r l; do [ -n "$l" ] && { echo "$l"; errors=$((errors+1)); }; done < "$tmp/csv-issues.txt"

    tail -n +2 "$tmp/rows.tsv" | cut -f1 | grep -vE '^(#|$)' | sort -u > "$tmp/keys.txt"

    # Keys referenced in code and scenes.
    { grep -rhoE "tr(_n)?\(&?\"[A-Z0-9_]+\"" game --include='*.gd' 2>/dev/null | sed -E 's/.*"([A-Z0-9_]+)"/\1/'
      grep -rhoE '^(text|placeholder_text|tooltip_text) = "[A-Z][A-Z0-9_]+"$' game --include='*.tscn' 2>/dev/null | sed -E 's/.*"([A-Z0-9_]+)"/\1/'
    } | grep -v '^$' | sort -u > "$tmp/used.txt"
    # Prototypes and addons are not shipped text.
    while IFS= read -r k; do err "key $k is used in the game but missing from $CSV"; done < <(comm -13 "$tmp/keys.txt" "$tmp/used.txt")
    unused="$(comm -23 "$tmp/keys.txt" "$tmp/used.txt" | tr '\n' ' ')"
    [ -n "$unused" ] && warn "possibly unused keys (fine if built dynamically): $unused"

    # Hard-coded player-facing text: scene text that is not a key, and
    # `.text = "..."` assignments in scripts. Prototypes and addons excluded.
    grep -rnE '^(text|placeholder_text|tooltip_text) = "[^"]*[a-z][^"]*"$' game --include='*.tscn' 2>/dev/null \
      | grep -vE '^game/(addons|prototypes)/' | head -n 20 | while IFS= read -r l; do echo "warn:  hard-coded scene text: $l"; done
    grep -rnE '\.(text|tooltip_text|placeholder_text)[[:space:]]*=[[:space:]]*"[^"]*[a-z][^"]*"' game --include='*.gd' 2>/dev/null \
      | grep -vE '^game/(addons|prototypes|tests)/' | grep -v 'tr(' | head -n 20 | while IFS= read -r l; do echo "warn:  hard-coded script text: $l"; done

    # Registration in project.godot.
    if [ -f game/project.godot ]; then
      for l in $langs; do
        grep -q "res://locale/strings.$l.translation" game/project.godot || err "strings.$l.translation not registered (bash tools/l10n.sh setup)"
      done
    fi

    nk="$(wc -l < "$tmp/keys.txt" | tr -d ' ')"
    echo "l10n: $nk keys, languages: $langs; $errors error(s)"
    rm -rf "$tmp"
    [ "$errors" -eq 0 ]
    ;;

  *) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
