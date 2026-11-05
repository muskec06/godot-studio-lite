#!/bin/bash
# Tests for tools/setup-godot.sh settings and tools/apply-profile.sh, on
# throwaway copies of this repo. No Godot needed (import is skipped).
# Usage: bash tools/tests/profile.test.sh
set -u
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
pass=0; fail=0
ok()  { pass=$((pass+1)); }
bad() { fail=$((fail+1)); echo "  FAIL: $1"; }
has() { if grep -qF -- "$2" "$3"; then ok; else bad "$1 (missing: $2)"; fi; }
hasnt() { if grep -qF -- "$2" "$3"; then bad "$1 (unexpected: $2)"; else ok; fi; }
count() { local n; n=$(grep -cF -- "$2" "$3"); if [ "$n" = "$4" ]; then ok; else bad "$1 ($2 appears $n times, expected $4)"; fi; }

fresh() {
  T="$(mktemp -d 2>/dev/null || mktemp -d -t gsl)"
  cp -R "$SRC/." "$T/"; rm -rf "$T/.git" "$T/game/project.godot" "$T/game/.godot"
  sed -i.bak 's/^godot_bin:.*/godot_bin: "\/nonexistent"  # test/' "$T/project.yaml" && rm -f "$T/project.yaml.bak"
  unset CLAUDE_PROJECT_DIR
}

echo "[desktop, pixel art]"
fresh
( cd "$T" && PATH=/usr/bin:/bin bash tools/setup-godot.sh >/dev/null 2>&1 )
P="$T/game/project.godot"
has "desktop creates project.godot" 'config_version=5' "$P"
has "desktop is landscape 1280" 'window/size/viewport_width=1280' "$P"
has "pixel art uses integer scaling on desktop" 'window/stretch/scale_mode="integer"' "$P"
has "pixel art uses nearest filtering" 'textures/canvas_textures/default_texture_filter=0' "$P"
hasnt "desktop has no handheld orientation" 'window/handheld/orientation' "$P"
[ -d "$T/game/assets/store" ] && ok || bad "setup creates game/assets/store"
rm -rf "$T"

echo "[mobile portrait, illustrated]"
fresh
sed -i.bak 's/^art_style:[^#]*/art_style: illustrated  /' "$T/project.yaml" && rm -f "$T/project.yaml.bak"
( cd "$T" && PATH=/usr/bin:/bin bash tools/setup-godot.sh >/dev/null 2>&1 )
out="$(cd "$T" && PATH=/usr/bin:/bin bash tools/apply-profile.sh mobile portrait 2>&1)"
P="$T/game/project.godot"; Y="$T/project.yaml"
has "profile sets platform" 'platform: mobile' "$Y"
has "profile sets orientation" 'orientation: portrait' "$Y"
has "profile keeps yaml comments" 'platform: mobile        # desktop | mobile' "$Y"
for f in .claude/rules/mobile.md .claude/skills/monetize/SKILL.md game/scripts/mobile/app.gd game/scripts/mobile/safe_area_container.gd \
         game/scripts/monetization/ads.gd game/scripts/monetization/purchases.gd game/scripts/monetization/ads_policy.gd \
         game/tests/scripts/monetization/test_ads_policy.gd; do
  [ -f "$T/$f" ] && ok || bad "profile copies $f"
done
[ -f "$T/autoloads.txt" ] && bad "profile must not copy autoloads.txt" || ok
has "mobile portrait is 720 wide" 'window/size/viewport_width=720' "$P"
has "mobile portrait is 1280 tall" 'window/size/viewport_height=1280' "$P"
has "mobile orientation portrait" 'window/handheld/orientation=1' "$P"
has "mobile stretch aspect expand" 'window/stretch/aspect="expand"' "$P"
has "mobile uses compatibility renderer" 'renderer/rendering_method="gl_compatibility"' "$P"
has "mobile imports ETC2/ASTC" 'textures/vram_compression/import_etc2_astc=true' "$P"
has "mobile back button does not quit" 'config/quit_on_go_back=false' "$P"
has "mobile emulates touch" 'pointing/emulate_touch_from_mouse=true' "$P"
has "autoload App registered" 'App="*res://scripts/mobile/app.gd"' "$P"
has "autoload Ads registered" 'Ads="*res://scripts/monetization/ads.gd"' "$P"
if awk '/^Purchases=/{p=NR} /^Ads=/{a=NR} END{exit !(p && a && p<a)}' "$P"; then ok; else bad "Purchases autoload loads before Ads"; fi
hasnt "illustrated mobile has no nearest filter" 'default_texture_filter=0' "$P"

# Run again: idempotent.
out2="$(cd "$T" && PATH=/usr/bin:/bin bash tools/apply-profile.sh mobile portrait 2>&1)"
count "re-run does not duplicate viewport width" 'window/size/viewport_width=' "$P" 1
count "re-run does not duplicate autoloads" 'Ads="*res://' "$P" 1
count "re-run does not duplicate [display]" '[display]' "$P" 1
if printf '%s' "$out2" | grep -q 'kept existing'; then ok; else bad "re-run reports kept files"; fi

# User edits survive a re-run.
printf '\n# my change\n' >> "$T/game/scripts/monetization/ads.gd"
( cd "$T" && PATH=/usr/bin:/bin bash tools/apply-profile.sh mobile portrait >/dev/null 2>&1 )
has "re-run never overwrites a game file" '# my change' "$T/game/scripts/monetization/ads.gd"

# Switch to landscape.
( cd "$T" && PATH=/usr/bin:/bin bash tools/apply-profile.sh mobile landscape >/dev/null 2>&1 )
has "landscape switch updates width" 'window/size/viewport_width=1280' "$P"
has "landscape switch updates orientation" 'window/handheld/orientation=0' "$P"

( cd "$T" && bash tools/apply-profile.sh nope >/dev/null 2>&1 ); c=$?
[ $c -eq 2 ] && ok || bad "unknown profile exits 2 (got $c)"
rm -rf "$T"

echo "[analytics profile + funnel]"
fresh
( cd "$T" && PATH=/usr/bin:/bin bash tools/setup-godot.sh >/dev/null 2>&1 )
( cd "$T" && PATH=/usr/bin:/bin bash tools/apply-profile.sh analytics >/dev/null 2>&1 )
P="$T/game/project.godot"
has "analytics autoload registered" 'Analytics="*res://scripts/analytics/analytics.gd"' "$P"
[ -f "$T/.claude/skills/metrics/SKILL.md" ] && ok || bad "analytics adds /metrics"
hasnt "analytics leaves platform alone" 'platform: mobile' "$T/project.yaml"
( cd "$T" && PATH=/usr/bin:/bin bash tools/apply-profile.sh mobile >/dev/null 2>&1 )
has "two profiles: mobile autoloads added" 'Ads="*res://scripts/monetization/ads.gd"' "$P"
has "two profiles: analytics autoload kept" 'Analytics="*res://' "$P"
out="$(bash "$T/tools/funnel.sh" "$T/tools/tests/fixtures")"
if printf '%s' "$out" | grep -q 'Players: 3 · Sessions: 3'; then ok; else bad "funnel counts players and sessions"; fi
if printf '%s' "$out" | grep -qF '| 1 | 3 | 2 | 66% | 20 | 0.0 | 100% |'; then ok; else bad "funnel level 1 row"; fi
if printf '%s' "$out" | grep -qF '| 2 | 2 | 1 | 50% | 50 | 1.5 | 66% |'; then ok; else bad "funnel level 2 row (repeat starts counted once, fails per player)"; fi
if printf '%s' "$out" | grep -q 'ad_rewarded=1'; then ok; else bad "funnel counts ad events"; fi
bash "$T/tools/funnel.sh" "$T/nope" >/dev/null 2>&1; c=$?
[ $c -eq 2 ] && ok || bad "funnel exits 2 on a missing path"
rm -rf "$T"

echo "[cay-ocagi-art kit]"
fresh
( cd "$T" && PATH=/usr/bin:/bin bash tools/setup-godot.sh >/dev/null 2>&1 )
out="$(cd "$T" && PATH=/usr/bin:/bin bash tools/apply-profile.sh cay-ocagi-art 2>&1)"
has "kit sets art_style" 'art_style: illustrated' "$T/project.yaml"
[ -f "$T/settings.txt" ] && bad "kit must not copy settings.txt" || ok
out="$(cd "$T" && bash tools/svg-build.sh 2>&1)"; c=$?
[ $c -eq 0 ] && ok || bad "kit builds: $out"
n="$(find "$T/game/assets" -name '*.svg' -not -path '*/_src/*' | wc -l | tr -d ' ')"
[ "$n" -ge 27 ] && ok || bad "kit builds all SVGs (got $n)"
for f in glass/glass_mask.svg glass/glass_front.svg symbols/sym_bean.svg props/semaver.svg brand/logo.svg brand/app_icon_512.svg backgrounds/cafe_counter.svg; do
  [ -f "$T/game/assets/$f" ] && ok || bad "kit built $f"
done
out="$(cd "$T" && bash tools/svg-check.sh $(find game/assets -name '*.svg' -not -path '*/_src/*') 2>&1)"; c=$?
[ $c -eq 0 ] && ok || bad "every built kit SVG passes svg-check: $out"
if printf '%s' "$out" | grep -q '^warn'; then bad "kit SVGs use only token colours: $(printf '%s' "$out" | grep '^warn' | head -n 3)"; else ok; fi
has "DesignTokens has the drink colours" '&"drink_kusburnu": Color(0.8510, 0.2275, 0.3451),' "$T/game/scripts/generated/design_tokens.gd"
has "kit brings GlassView" 'class_name GlassView' "$T/game/scripts/glass/glass_view.gd"
[ "$(grep -c '| claude-vector |' "$T/game/assets/ASSETS.md")" -ge 27 ] && ok || bad "kit assets recorded"
rm -rf "$T"

echo "[mobile before project exists]"
fresh
out="$(cd "$T" && PATH=/usr/bin:/bin bash tools/apply-profile.sh mobile 2>&1)"
if printf '%s' "$out" | grep -q 'registered after game/project.godot exists'; then ok; else bad "profile explains deferred autoloads"; fi
( cd "$T" && PATH=/usr/bin:/bin bash tools/setup-godot.sh >/dev/null 2>&1 )
has "setup registers profile autoloads later" 'Purchases="*res://scripts/monetization/purchases.gd"' "$T/game/project.godot"
has "setup applies mobile settings later" 'window/handheld/orientation=1' "$T/game/project.godot"
rm -rf "$T"

echo ""
echo "profile: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
