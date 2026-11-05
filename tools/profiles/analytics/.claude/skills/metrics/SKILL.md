---
name: metrics
description: Gameplay analytics — wire level events into the game, read playtest logs as a level funnel (where players quit, which levels are too hard), turn findings into tuning stories, or choose a remote analytics provider.
argument-hint: "[setup | report <log folder or files> | provider]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Edit, Bash(bash tools/funnel.sh*)
---

# /metrics — measure, then tune

Input: `$ARGUMENTS`. Empty: `report` if logs are mentioned, else `setup`.

## setup

1. The `Analytics` autoload exists (`game/scripts/analytics/analytics.gd`);
   if not: `bash tools/apply-profile.sh analytics` (ask first).
2. Find where levels start, end and fail (Grep for the win/lose screens,
   `change_scene`, level loaders). Plan one story with `/plan` that calls
   `Analytics.level_started(n)`, `level_completed(n, {moves, stars…})`,
   `level_failed(n, {reason})` there, plus 2–5 game-specific events that
   answer a real question (e.g. `hint_used`, `shop_opened`). Each event name
   must answer "what would I change if this number were bad?" — otherwise skip it.
3. Settings story: an "Analytics" toggle calling `Analytics.set_enabled()`.
4. Logs are written in debug builds (`log_to_file`). For playtests, hand out
   a debug build or set `log_to_file = true` in the playtest build.

## report

1. Run `bash tools/funnel.sh <files or folder>` (the script's header says
   where each OS keeps the logs; Android debug builds via `adb … run-as`).
   Fewer than ~5 players: say the numbers are anecdotes and weigh them with
   the playtest notes.
2. Read the table and name, with numbers:
   - the biggest drop in "Reached" between consecutive levels;
   - levels with completion < 70% or fails/player > 2 (difficulty spikes);
   - levels that are much faster than their neighbours (too easy/boring);
   - with ads: rewarded ads per player, interstitials vs AdsPolicy settings.
3. Propose fixes as tuning stories (S size) naming the exact value to change
   (`@export`, resource field, AdsPolicy number) and the expected effect.
   Ask before adding them.
4. Append a `## Metrics` section to the latest `docs/playtests/*.md` with the
   table and the 3 main findings.

## provider

Only once real players outside friends exist. `/adr` with the architect:
candidates such as GameAnalytics or Firebase Analytics Godot plugins —
verify Godot 4.7 support, consent handling (GDPR/KVKK), data-safety
declarations for the store, and cost. The adapter `extends AnalyticsBackend`
(`track`, `flush`), is installed with `Analytics.use_backend()` on release
builds, and is gated by the same consent flow as ads. Update the privacy
policy and the store's data safety form when it ships.
