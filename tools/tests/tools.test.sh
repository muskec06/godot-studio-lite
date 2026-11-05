#!/bin/bash
# Tests for tools that need no Godot: l10n.sh, and the "cannot run" paths of
# the Godot-backed tools. Usage: bash tools/tests/tools.test.sh
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }
out_has() { if printf '%s' "$3" | grep -qF -- "$2"; then ok; else bad "$1 (output lacks: $2)"; fi; }
out_hasnt() { if printf '%s' "$3" | grep -qF -- "$2"; then bad "$1 (unexpected: $2)"; else ok; fi; }

T="$(mktemp -d 2>/dev/null || mktemp -d -t gsl)"
cp -R "$SRC/." "$T/"; rm -rf "$T/.git" "$T/game/project.godot" "$T/game/.godot" "$T/game/locale"
sed -i.bak 's/^godot_bin:.*/godot_bin: "\/nonexistent"  # test/' "$T/project.yaml" && rm -f "$T/project.yaml.bak"
unset CLAUDE_PROJECT_DIR
cd "$T" || exit 1
PATH=/usr/bin:/bin bash tools/setup-godot.sh >/dev/null 2>&1

echo "[l10n setup]"
out="$(bash tools/l10n.sh setup)"
out_has "setup creates the CSV" 'created game/locale/strings.csv (en tr)' "$out"
[ "$(head -n 1 game/locale/strings.csv)" = "keys,en,tr" ] && ok || bad "CSV header from languages"
grep -qF 'locale/translations=PackedStringArray("res://locale/strings.en.translation", "res://locale/strings.tr.translation")' game/project.godot && ok || bad "translations registered"
grep -qF 'locale/fallback="en"' game/project.godot && ok || bad "fallback is the source language"
bash tools/l10n.sh setup >/dev/null
[ "$(grep -c 'locale/translations=' game/project.godot)" = "1" ] && ok || bad "setup is idempotent"

echo "[l10n check: clean]"
mkdir -p game/scripts game/scenes
printf 'extends Node\nfunc _ready() -> void:\n\t$A.text = tr("MENU_PLAY")\n' > game/scripts/menu.gd
printf '[node name="L" type="Label"]\ntext = "MENU_SETTINGS"\n' > game/scenes/menu.tscn
out="$(bash tools/l10n.sh check)"; c=$?
[ $c -eq 0 ] && ok || bad "clean project passes (exit $c): $out"
out_hasnt "no unused warning when keys are used" 'possibly unused' "$out"

echo "[l10n check: problems]"
cat >> game/locale/strings.csv <<'EOF'
LEVEL_N,"Level %d, go!",Seviye %d
COINS,You have {count} coins,{count} jeton
ORDER,%s beat %d,%d yendi %s
BAD_PH,Score %d of %d,Skor %d
EMPTY_TR,Hello,
LEVEL_N,dup,dup
EOF
printf '\t$B.text = tr("MISSING_KEY")\n\t$C.text = "Hello world"\n' >> game/scripts/menu.gd
printf '[node name="B" type="Button"]\ntext = "Start game"\n' >> game/scenes/menu.tscn
mkdir -p game/prototypes/p && printf 'extends Node\nfunc f() -> void:\n\t$X.text = "proto text"\n' > game/prototypes/p/x.gd
out="$(bash tools/l10n.sh check)"; c=$?
[ $c -eq 1 ] && ok || bad "problems exit 1 (got $c)"
out_has "placeholder mismatch found" 'BAD_PH placeholders differ' "$out"
out_hasnt "quoted comma does not break a row" 'LEVEL_N placeholders' "$out"
out_hasnt "named placeholders match" 'COINS placeholders' "$out"
out_hasnt "placeholder order may differ" 'ORDER placeholders' "$out"
out_has "empty translation found" 'EMPTY_TR has no tr text' "$out"
out_has "duplicate key found" 'duplicate key LEVEL_N' "$out"
out_has "key used but missing" 'MISSING_KEY is used in the game but missing' "$out"
out_has "hard-coded scene text" 'hard-coded scene text: game/scenes/menu.tscn' "$out"
out_has "hard-coded script text" 'hard-coded script text: game/scripts/menu.gd' "$out"
out_hasnt "prototypes are ignored" 'proto text' "$out"
out_has "summary line" 'l10n: 7 keys, languages: en tr; 4 error(s)' "$out"

echo "[l10n check: language added in project.yaml]"
sed -i.bak 's/^languages:.*/languages: en tr de  # test/' project.yaml && rm -f project.yaml.bak
out="$(bash tools/l10n.sh check)"
out_has "missing language column" "language column 'de'" "$out"
out_has "unregistered language" 'strings.de.translation not registered' "$out"

echo "[svg-check]"
mkdir -p game/assets/_style game/assets/_src/t
printf '{\n  "ink": "#2e0f07",\n  "gold": "#e9a73a"\n}\n' > game/assets/_style/tokens.json
good='<svg xmlns="http://www.w3.org/2000/svg" width="100" height="50" viewBox="0 0 100 50"><rect width="100" height="50" fill="{{gold}}"/><path d="M0,0 L10,10" stroke="{{ink}}"/></svg>'
printf '%s\n' "$good" > game/assets/_src/t/ok.svg.tpl
out="$(bash tools/svg-check.sh game/assets/_src/t/ok.svg.tpl)"; c=$?
[ $c -eq 0 ] && ok || bad "valid template passes: $out"
for bad_svg in \
  'text|<svg width="10" height="10" viewBox="0 0 10 10"><text>Hi</text></svg>' \
  'filter|<svg width="10" height="10" viewBox="0 0 10 10"><filter id="b"/><rect filter="url(#b)"/></svg>' \
  'style|<svg width="10" height="10" viewBox="0 0 10 10"><style>rect{fill:red}</style></svg>' \
  'animate|<svg width="10" height="10" viewBox="0 0 10 10"><rect><animate attributeName="x"/></rect></svg>' \
  'image|<svg width="10" height="10" viewBox="0 0 10 10"><image href="a.png"/></svg>' \
  'external|<svg width="10" height="10" viewBox="0 0 10 10"><use href="https://x.test/a.svg#b"/></svg>' \
  'script handler|<svg width="10" height="10" viewBox="0 0 10 10" onload="x()"></svg>' \
  'no viewBox|<svg width="10" height="10"></svg>' \
  'no size|<svg viewBox="0 0 10 10"></svg>'; do
  name="${bad_svg%%|*}"; printf '%s\n' "${bad_svg#*|}" > /tmp/gsl-bad.svg
  bash tools/svg-check.sh /tmp/gsl-bad.svg >/dev/null 2>&1; c=$?
  [ $c -eq 1 ] && ok || bad "svg-check rejects $name (got $c)"
done
printf '%s\n' '<svg width="10" height="10" viewBox="0 0 10 10"><rect fill="{{nope}}"/></svg>' > game/assets/_src/t/bad.svg.tpl
out="$(bash tools/svg-check.sh game/assets/_src/t/bad.svg.tpl)"; c=$?
[ $c -eq 1 ] && ok || bad "unknown token rejected"
out_has "names the missing token" 'tokens missing' "$out"
rm game/assets/_src/t/bad.svg.tpl
printf '%s\n' '<svg width="10" height="10" viewBox="0 0 10 10"><rect fill="#123456"/></svg>' > /tmp/gsl-off.svg
out="$(bash tools/svg-check.sh /tmp/gsl-off.svg)"; c=$?
[ $c -eq 0 ] && ok || bad "off-token colour is only a warning"
out_has "warns about off-token colour" 'colours not in the design tokens: #123456' "$out"

echo "[svg-guard hook]"
export CLAUDE_PROJECT_DIR="$T"
printf '%s\n' '<svg width="10" height="10" viewBox="0 0 10 10"><text>x</text></svg>' > game/assets/t.svg
err="$(printf '{"tool_input":{"file_path":"%s"}}' "$T/game/assets/t.svg" | bash .claude/hooks/svg-guard.sh 2>&1)"; c=$?
[ $c -eq 2 ] && ok || bad "svg-guard blocks a bad SVG (got $c)"
out_has "svg-guard explains" 'Godot does not draw SVG text' "$err"
printf '{"tool_input":{"file_path":"%s"}}' "$T/game/assets/_src/t/ok.svg.tpl" | bash .claude/hooks/svg-guard.sh >/dev/null 2>&1; c=$?
[ $c -eq 0 ] && ok || bad "svg-guard passes a good template"
printf '{"tool_input":{"file_path":"%s"}}' "$T/project.yaml" | bash .claude/hooks/svg-guard.sh >/dev/null 2>&1; c=$?
[ $c -eq 0 ] && ok || bad "svg-guard ignores other files"
rm -f game/assets/t.svg
unset CLAUDE_PROJECT_DIR

echo "[svg-build]"
out="$(bash tools/svg-build.sh)"; c=$?
[ $c -eq 0 ] && ok || bad "svg-build succeeds: $out"
grep -qF 'fill="#e9a73a"' game/assets/t/ok.svg && ok || bad "tokens substituted"
grep -qF '| t/ok.svg | claude-vector |' game/assets/ASSETS.md && ok || bad "built asset recorded as claude-vector"
[ ! -e game/assets/_raw/t/ok.svg ] && ok || bad "vector build keeps no _raw copy"
[ -f game/assets/_src/.gdignore ] && ok || bad "templates hidden from Godot"
grep -qF '&"gold": Color(0.9137, 0.6549, 0.2275),' game/scripts/generated/design_tokens.gd && ok || bad "DesignTokens generated with exact colours"
sed -i.bak 's/#e9a73a/#00ff00/' game/assets/_style/tokens.json && rm -f game/assets/_style/tokens.json.bak
bash tools/svg-build.sh >/dev/null
grep -qF 'fill="#00ff00"' game/assets/t/ok.svg && ok || bad "token change propagates on rebuild"
[ "$(grep -c '| t/ok.svg |' game/assets/ASSETS.md)" = "1" ] && ok || bad "rebuild replaces the ASSETS.md row"
out="$(GSL_NO_JQ=1 bash tools/svg-build.sh)"; c=$?
[ $c -eq 0 ] && ok || bad "svg-build works without jq"
printf '%s\n' '<svg width="10" height="10" viewBox="0 0 10 10"><rect fill="{{missing_one}}"/></svg>' > game/assets/_src/t/miss.svg.tpl
out="$(bash tools/svg-build.sh)"; c=$?
[ $c -eq 1 ] && ok || bad "svg-build fails on an unknown token"
out_has "svg-build names the unknown token" 'unknown tokens: missing_one' "$out"
rm -f game/assets/_src/t/miss.svg.tpl

echo "[Godot tools without Godot]"
for t in "colorblind.sh palette" "parse-all.sh" "run-tests.sh" "svg-render.sh game/assets/t/ok.svg" "build-theme.sh"; do
  bash tools/$t >/dev/null 2>&1; c=$?
  [ $c -eq 3 ] && ok || bad "$t exits 3 without Godot (got $c)"
done

cd / && rm -rf "$T"
echo ""
echo "tools: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
