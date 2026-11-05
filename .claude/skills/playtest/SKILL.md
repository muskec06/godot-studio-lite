---
name: playtest
description: Record a playtest — collect what the user or testers observed, sort it into bugs, tuning and design issues, and add the actionable ones to the backlog.
argument-hint: "[raw notes, or empty to be interviewed]"
disable-model-invocation: true
---

# /playtest — from observations to backlog

Input: `$ARGUMENTS` — pasted notes. Empty: interview the user.

1. **Collect.** If no notes: one `AskUserQuestion` round — who played (you /
   a friend / a stranger), build or date, how long, did they finish the
   first playable. Then ask for free-form notes: what they did, where they
   got stuck, what they said, what surprised you.

2. **Sort** every observation into one of:
   - **Bug** — wrong behaviour (→ `qa` format, repro steps if known)
   - **Tuning** — rules fine, numbers off (name the `@export`/resource value)
   - **Design** — the rule itself does not serve a pillar
   - **Delight** — keep this; worth knowing what not to break
   Tie each to a brief pillar where it applies. Observations, not opinions:
   "died 4 times at the second gap" beats "too hard".

3. **Write** `docs/playtests/YYYY-MM-DD.md` (date, who, build, sorted lists,
   top 3 takeaways). Under ~50 lines.

4. **Propose backlog items**: bugs and tuning become stories (S size,
   acceptance = the observation no longer happens). Design issues become
   questions for the user, or a `/prototype`. Show the list and ask before
   adding (Add all / Pick / None).

5. CHECKPOINT: one line on the playtest result and the next story.
