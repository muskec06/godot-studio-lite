---
name: plan
description: Turn the brief (or a feature description) into small, testable stories in docs/backlog.md.
argument-hint: "[feature to plan, or empty for the first playable]"
disable-model-invocation: true
---

# /plan — stories into the backlog

Input: `$ARGUMENTS` — a feature to plan. Empty means "the First playable
section of `docs/brief.md`".

1. Read `docs/brief.md` (pillars, core loop, first playable, out of scope)
   and the table in `docs/backlog.md`. Read story sections only if needed.

2. **Slice** the work into stories. Each story:
   - delivers something the player (or the developer, for tooling) can see
     or test on its own; vertical, not "write the class";
   - fits one sitting: size S (< 1 h of agent work), M (a few hours). L means
     split it;
   - has 2–4 acceptance criteria a person can check in the running game;
   - lists the files it will create or change, the test it needs (`mode:
     project` → required for logic; `jam` → optional), and `Visual: yes/no`;
   - lists the art and sound it needs as `Assets:` with destination paths
     under `game/assets/` and sizes (or `none`). Reuse files already in
     `game/assets/ASSETS.md`. Code can start on placeholders, so assets never
     block a story's order.
   Order by dependency, then by risk: the scariest unknown first.
   The first plan of a game also gets one settings story covering the
   accessibility options in `.claude/rules/accessibility.md`, the language
   selector when `languages` lists more than one, and the analytics toggle
   when the Analytics autoload exists.
   Prefer 5–12 stories per run; more means the feature is too big.

3. If a mechanic is underspecified (no numbers, unclear rules), stop and ask
   the user, or offer to run the `designer` agent on it first. Don't invent
   game design silently.

4. Show the proposed table (ID, story, size, visual, depends on) and ask
   "Add these N stories?" (Add / Change / Cancel).

5. **Write**: append rows to the table and a `### S-NNN Title` section per
   story under "Story details" (format shown in the file's comment). IDs
   continue from the highest existing one. Status `todo`.

6. Update the CHECKPOINT (next step: `/story S-NNN` for the first one).
   Report in ≤ 5 lines.

Never reorder or rewrite existing stories here; that is the user's call.
