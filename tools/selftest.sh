#!/bin/bash
# Self-test for the Godot Studio Lite setup itself (not the game).
# Checks structure, frontmatter, references and shell syntax, runs the hook
# tests, and estimates the context loaded at every session start.
# Usage: bash tools/selftest.sh            Exit 0 = all checks passed.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1
fails=0; checks=0
check() { checks=$((checks+1)); if eval "$2" >/dev/null 2>&1; then :; else fails=$((fails+1)); echo "FAIL: $1"; fi; }

# Frontmatter field: fm FILE KEY -> value of `KEY:` inside the first --- block.
fm() { awk -v k="$2" 'NR==1&&$0!="---"{exit} NR>1&&$0=="---"{exit} NR>1{ if (index($0, k":")==1) { sub("^"k":[ ]*",""); print; exit } }' "$1"; }

echo "== agents"
for f in .claude/agents/*.md; do
  n="$(basename "$f" .md)"
  check "$f: name matches file" '[ "$(fm "$f" name)" = "$n" ]'
  check "$f: has description" '[ -n "$(fm "$f" description)" ]'
  check "$f: has tools" '[ -n "$(fm "$f" tools)" ]'
  check "$f: valid model" 'case "$(fm "$f" model)" in sonnet|opus|haiku|inherit|fable) true;; *) false;; esac'
  check "$f: no Agent tool (no nested fan-out)" '! fm "$f" tools | grep -qw Agent'
  for s in $(fm "$f" skills | tr -d '[],'); do
    check "$f: preloaded skill $s exists" '[ -f ".claude/skills/$s/SKILL.md" ]'
  done
done

echo "== skills"
for d in .claude/skills/*/ tools/profiles/*/.claude/skills/*/; do
  s="$(basename "$d")"; f="$d/SKILL.md"
  check "$s: SKILL.md exists" '[ -f "$f" ]'
  check "$s: has description" '[ -n "$(fm "$f" description)" ]'
  check "$s: description ≤ 1536 chars" '[ "$(fm "$f" description | wc -c)" -le 1536 ]'
  a="$(fm "$f" agent)"; [ -n "$a" ] && check "$s: forked agent $a exists" '[ -f ".claude/agents/$a.md" ]'
  for t in $(grep -oE 'tools/[a-z0-9_-]+\.sh' "$f" | sort -u); do
    check "$s: references existing $t" '[ -f "$t" ]'
  done
  for ag in $(grep -oE '`(gdscript-dev|reviewer|architect|designer|qa|shader-vfx|godot-docs|writer|audio|artist|vector-artist)`' "$f" | tr -d '`' | sort -u); do
    check "$s: references existing agent $ag" '[ -f ".claude/agents/$ag.md" ]'
  done
done

echo "== rules"
for f in .claude/rules/*.md tools/profiles/*/.claude/rules/*.md; do
  check "$f: path-scoped (paths:)" 'head -n 5 "$f" | grep -q "^paths:"'
done

echo "== settings and hooks"
if command -v jq >/dev/null 2>&1; then
  check "settings.json is valid JSON" 'jq empty .claude/settings.json'
fi
for h in $(grep -oE 'hooks/[a-z0-9_-]+\.sh' .claude/settings.json | sort -u); do
  check "settings references existing .claude/$h" '[ -f ".claude/$h" ]'
done
for sh in .claude/hooks/*.sh tools/*.sh tools/tests/*.sh; do
  check "$sh: bash syntax" 'bash -n "$sh"'
done
check "CLAUDE.md under 80 lines" '[ "$(wc -l < CLAUDE.md)" -le 80 ]'
check "project.yaml has mode" 'grep -qE "^mode: (jam|project)" project.yaml'
check "project.yaml has a numeric asset budget" 'grep -qE "^asset_budget_usd: [0-9]+(\.[0-9]+)?([[:space:]]|$)" project.yaml'

echo "== fal.ai"
if command -v jq >/dev/null 2>&1; then
  check ".mcp.json is valid JSON" 'jq empty .mcp.json'
  check ".mcp.json defines fal as an http server" '[ "$(jq -r .mcpServers.fal.type .mcp.json)" = "http" ]'
fi
check "fal-models.tsv rows have 5 columns and a price" \
  '! awk -F"\t" '"'"'$1!~/^#/ && $1!="" && $1!="endpoint" && (NF!=5 || $4!~/^[0-9.]+$/)'"'"' tools/fal-models.tsv | grep -q .'
check "fal-models.tsv units are known" \
  '! awk -F"\t" '"'"'$1!~/^#/ && $1!="" && $1!="endpoint" && $3!~/^(image|second|minute|call)$/'"'"' tools/fal-models.tsv | grep -q .'
check "only the artist agent may run fal models" \
  '[ "$(grep -l "mcp__fal__run_model" .claude/agents/*.md | xargs -n1 basename)" = "artist.md" ]'
check "paid fal tools are not pre-approved" '! grep -qE "\"mcp__fal__(run_model|submit_job)\"" .claude/settings.json'
check "budget hook guards both paid fal tools (pre and post)" \
  '[ "$(grep -c "mcp__fal__run_model|mcp__fal__submit_job" .claude/settings.json)" -eq 2 ]'

echo "== CI workflows"
for w in .github/workflows/*.yml; do
  [ -f "$w" ] || continue
  for t in $(grep -oE 'tools/[a-z0-9_-]+\.sh' "$w" | sort -u); do
    check "$w references existing $t" '[ -f "$t" ]'
  done
  check "$w pins its Godot version" 'grep -qE "GODOT_VERSION: \"[0-9]+\.[0-9]+(\.[0-9]+)?\"" "$w"'
done

echo "== profiles"
for p in tools/profiles/*/; do
  pn="$(basename "$p")"
  if [ -f "$p/autoloads.txt" ]; then
    while read -r an ap; do
      [ -n "$an" ] && [ "${an#\#}" = "$an" ] || continue
      check "$pn: autoload $an script exists in the profile" '[ -f "$p/game/${ap#res://}" ]'
    done < "$p/autoloads.txt"
  fi
  for g in $(find "$p" -name '*.gd'); do
    check "$g: Godot 4 syntax (gd-check lint)" \
      'printf "{\"tool_input\":{\"file_path\":\"%s\"}}" "$ROOT/$g" | CLAUDE_PROJECT_DIR="$ROOT" bash .claude/hooks/gd-check.sh'
  done
done

echo "== tests"
for t in tools/tests/*.test.sh; do
  log="${TMPDIR:-/tmp}/gsl-$(basename "$t" .sh).log"
  if bash "$t" > "$log" 2>&1; then
    tail -n 1 "$log"
  else
    fails=$((fails+1)); echo "FAIL: $t"; grep -E 'FAIL|passed' "$log"
  fi
done

echo "== context loaded at every session start (estimate: 4 chars ≈ 1 token)"
c_md=$(wc -c < CLAUDE.md)
c_rules=0
for f in .claude/rules/*.md; do head -n 5 "$f" | grep -q '^paths:' || c_rules=$((c_rules + $(wc -c < "$f"))); done
c_agents=0
for f in .claude/agents/*.md; do c_agents=$((c_agents + $(fm "$f" description | wc -c) + ${#f})); done
c_skills=0
for d in .claude/skills/*/; do
  f="$d/SKILL.md"
  [ "$(fm "$f" disable-model-invocation)" = "true" ] && continue
  c_skills=$((c_skills + $(fm "$f" description | wc -c) + 20))
done
c_start=$(CLAUDE_PROJECT_DIR="$ROOT" bash .claude/hooks/session-start.sh < /dev/null | wc -c)
total=$((c_md + c_rules + c_agents + c_skills + c_start))
printf '  CLAUDE.md %6d chars\n  unscoped rules %d\n  agent list %d\n  skill list %d\n  session-start %d\n  total %d chars ≈ %d tokens\n' \
  "$c_md" "$c_rules" "$c_agents" "$c_skills" "$c_start" "$total" $((total / 4))
check "always-loaded context ≤ 4000 tokens" '[ $((total / 4)) -le 4000 ]'

echo ""
echo "selftest: $((checks - fails))/$checks checks passed"
[ "$fails" -eq 0 ]
