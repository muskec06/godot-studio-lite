---
name: done
description: Verify the story in progress and close it — parse check, tests, run the game and look, acceptance criteria, backlog and checkpoint update.
argument-hint: "[S-NNN, or empty for the story in progress]"
disable-model-invocation: true
allowed-tools: Read, Edit, Glob, Grep, Bash(bash tools/run-tests.sh*), Bash(bash tools/screenshot.sh*), Bash(git status*), Bash(git diff*)
---

# /done — verify and close a story

Input: `$ARGUMENTS` or the story marked `doing`. Read its section only.

A story closes only when every applicable check below passes. Report each
check as PASS / FAIL / SKIPPED (reason). Never write PASS for a check you did
not run.

1. **Code is clean.** The `gd-check` hook already ran on every `.gd` write;
   if any of its reports in this session were not fixed, FAIL.

2. **Review** (`mode: project` only): a `reviewer` verdict of APPROVE for the
   current code exists in this session. If not, tell the user to run `/review`
   first and stop.

3. **Tests.** `bash tools/run-tests.sh`. Exit 0 → PASS; 1 → FAIL (show the
   failing lines); 3 → SKIPPED with its reason. In `mode: project`, a story
   whose section names a test fails this check if that test file does not exist.

4. **Run and look** (story has `Visual: yes`):
   `bash tools/screenshot.sh S-NNN [scene] [frames] [actions]` — pick the
   scene that shows the story and, for movement, an action to hold. Open the
   PNG with Read and say what you see, against the criteria. If the script
   exits 3 (no display here), ask the user to run the game (F5 in the
   editor), check the criteria, and drop a screenshot into
   `production/evidence/`; wait for their confirmation. Visual stories are
   never closed on a parse check alone.
   **Mobile** (`platform: mobile`): the desktop screenshot checks layout
   only. Stories about touch, feel, layout near screen edges, ads or
   purchases also need the user to confirm on a real phone (editor → Remote
   Deploy). Ask one yes/no question naming what to try; until then the check
   is PENDING, not PASS.

5. **Acceptance.** Walk each criterion: met (how you know) / not met.
   Criteria only a human can judge ("feels responsive") go to the user as a
   yes/no question.

5b. **Accessibility** (story has `Visual: yes`). If the screen tells the
   player something by colour: `bash tools/colorblind.sh image <screenshot>`,
   Read the `_deutan` (most common) and `_protan` previews, and check the
   distinction survives or a second signal (shape, icon, pattern) exists.
   Also look for text under the size rule and tap targets under 48 px
   (`.claude/rules/accessibility.md`). FAIL names the element and the fix;
   SKIPPED if the screen carries no colour-coded or text information.

5c. **Text** (story added or changed player-facing text):
   `bash tools/l10n.sh check` — ERRORs FAIL (missing key, empty cell,
   placeholder mismatch); new hard-coded text warnings for this story's files
   FAIL too. Empty translations may be left for `/localize translate` in `jam`
   mode: PASS with a note.

6. **Assets.** Every path on the story's `Assets:` line either exists and has
   a row in `game/assets/ASSETS.md` → PASS, or is still a placeholder →
   PASS with a note "placeholder: <path>" in `jam` mode, FAIL in `project`
   mode unless the user says the art comes later. Files under `game/assets/`
   with no ASSETS.md row: FAIL (unknown origin and licence).

7. **Close or bounce.**
   - All PASS (SKIPPED only where allowed): set status `done` in the table,
     add `Done: YYYY-MM-DD · evidence: <png or "user confirmed">` at the end of
     the story section.
   - Any FAIL: leave it `doing`, list what failed and the smallest fix, and
     suggest `/story S-NNN` to fix it.

8. Overwrite the CHECKPOINT (story closed or what is failing, next step).
   Suggest a commit message (`S-NNN: <title>`) but do not commit.

Output: the checklist and the verdict, ≤ 15 lines.
