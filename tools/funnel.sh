#!/bin/bash
# Level funnel from Analytics session logs (JSON lines, one event per line).
#
#   bash tools/funnel.sh <file.jsonl | folder> ...
#
# Where the logs are (user:// of the game, folder "analytics"):
#   Windows  %APPDATA%\Godot\app_userdata\<game name>\analytics\
#   macOS    ~/Library/Application Support/Godot/app_userdata/<game name>/analytics/
#   Linux    ~/.local/share/godot/app_userdata/<game name>/analytics/
#   Android  (debug build) adb exec-out run-as <package> sh -c 'cat files/analytics/*.jsonl' > phone.jsonl
#
# Prints a Markdown table: per level, players who started it, finished it,
# completion rate, average seconds to finish, fails per player, and how many
# of the players who started level 1 got this far. Plus ad and purchase totals.
# Observations only: the reading is done by /metrics.
set -u
[ $# -gt 0 ] || { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }

files=()
for a in "$@"; do
  if [ -d "$a" ]; then
    while IFS= read -r f; do files+=("$f"); done < <(find "$a" -type f -name '*.jsonl' | sort)
  elif [ -f "$a" ]; then
    files+=("$a")
  else
    echo "not found: $a" >&2; exit 2
  fi
done
[ ${#files[@]} -gt 0 ] || { echo "no .jsonl files found" >&2; exit 2; }

cat "${files[@]}" | awk '
  function str(k,   m) { if (match($0, "\"" k "\":\"[^\"]*\"")) { m = substr($0, RSTART, RLENGTH); sub("^\"" k "\":\"", "", m); sub("\"$", "", m); return m } return "" }
  function num(k,   m) { if (match($0, "\"" k "\":-?[0-9]+(\\.[0-9]+)?")) { m = substr($0, RSTART, RLENGTH); sub("^\"" k "\":", "", m); return m } return "" }
  {
    e = str("e"); u = str("uid"); s = str("sid"); lv = num("level")
    if (e == "") next
    if (u != "") players[u] = 1
    if (s != "") sessions[s] = 1
    if (e == "level_start" && lv != "") { if (!((lv, u) in st)) { st[lv, u] = 1; nst[lv]++ } levels[lv] = 1 }
    else if (e == "level_complete" && lv != "") {
      if (!((lv, u) in cp)) { cp[lv, u] = 1; ncp[lv]++ }
      sec = num("seconds"); if (sec != "" && sec >= 0) { tsec[lv] += sec; nsec[lv]++ }
      levels[lv] = 1
    }
    else if (e == "level_fail" && lv != "") { nf[lv]++; levels[lv] = 1 }
    else if (e ~ /^ad_/ || e ~ /^purchase/) other[e]++
  }
  END {
    np = 0; for (u in players) np++
    ns = 0; for (s in sessions) ns++
    printf "Players: %d · Sessions: %d\n\n", np, ns
    n = 0; for (l in levels) lvls[++n] = l + 0
    # insertion sort, levels are few
    for (i = 2; i <= n; i++) { v = lvls[i]; j = i - 1; while (j > 0 && lvls[j] > v) { lvls[j+1] = lvls[j]; j-- } lvls[j+1] = v }
    first = (n > 0) ? nst[lvls[1]] : 0
    print "| Level | Started | Finished | Completion | Avg s to finish | Fails/player | Reached (of first level) |"
    print "|---:|---:|---:|---:|---:|---:|---:|"
    for (i = 1; i <= n; i++) {
      l = lvls[i]; a = nst[l] + 0; c = ncp[l] + 0
      comp = (a > 0) ? sprintf("%d%%", 100 * c / a) : "-"
      avg = (nsec[l] > 0) ? sprintf("%.0f", tsec[l] / nsec[l]) : "-"
      fpp = (a > 0) ? sprintf("%.1f", nf[l] / a) : "-"
      reach = (first > 0) ? sprintf("%d%%", 100 * a / first) : "-"
      printf "| %d | %d | %d | %s | %s | %s | %s |\n", l, a, c, comp, avg, fpp, reach
    }
    m = 0; for (k in other) m++
    if (m > 0) { print ""; printf "Ads and purchases:"; for (k in other) printf " %s=%d", k, other[k]; print "" }
  }'
