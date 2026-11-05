---
name: scope
description: Scope check — compare remaining backlog against the time left and propose what to cut, simplify or defer to ship on time.
argument-hint: "[deadline or time left, e.g. '3 weeks, 10 h/week']"
disable-model-invocation: true
---

# /scope — fit the game into the time left

Input: `$ARGUMENTS` — time left. Empty: use the deadline in `docs/brief.md`
Scope, or ask.

1. Count `todo` + `doing` stories by size from the backlog table (S ≈ 1 h,
   M ≈ 4 h of agent work + about as much of the user's testing; say these
   are rough). Done stories in the last 7 days, if dated, give a real pace —
   prefer it over the estimate.

2. Compare against the time left with a 30% buffer. Show the arithmetic in
   three lines.

3. If it does not fit, propose cuts in this order, each with the time saved:
   1. stories serving no pillar,
   2. polish on things players see once,
   3. content quantity (8 levels → 5) before content quality,
   4. a mechanic, last — and only with the user's explicit call.
   Never propose cutting the core loop; if that is what it takes, say the
   scope or the deadline has to change.

4. Ask which cuts to apply (multi-select). Applied cuts: status `cut` with a
   one-line reason in the story section; add the cut items to "Out of scope"
   in the brief.

Output ≤ 20 lines. This command never adds stories.
