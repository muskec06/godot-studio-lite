---
name: story
description: Implement one backlog story through the gdscript-dev agent (or shader-vfx/audio/writer when the story is theirs).
argument-hint: "[S-NNN, or empty for the next todo story]"
disable-model-invocation: true
---

# /story — build one story

Input: `$ARGUMENTS` — a story ID. Empty: the first `todo` story whose
dependencies are `done`.

1. **Pick.** From the `docs/backlog.md` table. If another story is `doing`,
   ask whether to continue that one instead. Read only the chosen story's
   section (Grep its `### S-NNN` heading, Read that range).

2. **Readiness check** (do not skip): acceptance criteria are checkable,
   files are listed, dependencies are `done`. In `mode: project`, if the
   story touches 3+ systems or adds an autoload, ask whether an `/adr` is
   needed first. Missing something: ask the user one question, don't guess.
   **Assets:** if the story lists assets not yet in `game/assets/ASSETS.md`,
   ask: generate now with `/asset S-NNN` (shows the cost first), or build with
   placeholders and generate later. Placeholders are fine in either mode.

3. **Mark `doing`** in the table. Overwrite the CHECKPOINT: current story,
   next step "gdscript-dev building", files in scope.

4. **Delegate** to the agent that owns the work — usually `gdscript-dev`;
   `shader-vfx` for effects, `audio` for sound, `writer` for text. The prompt
   contains, in full: the story section text, the mode, the files in scope and
   the folders where new files may go, whether tests are required, the asset
   paths (with "missing assets: use a placeholder — PlaceholderTexture2D or a
   ColorRect of the right size — loaded from an `@export` so the real file
   drops in without code changes"), and "Report in your RESULT format."

5. **Handle the result.**
   - `DONE`: show the user the file list and the acceptance lines (≤ 15
     lines). Next: `/review` (project mode) or `/done` (jam mode).
   - `BLOCKED` / `NEEDS SCOPE`: put the question to the user, then resume the
     same agent with the answer if your tools allow resuming it; otherwise
     run it again with the full prompt plus the answer.
   - Two failed rounds on the same problem: stop, summarise what was tried,
     ask the user how to proceed.

6. Update the CHECKPOINT (files changed, next step). Do not mark the story
   `done` here — only `/done` does that.
