---
name: brief
description: Write or revise the one-page game brief — fantasy, pillars, core loop, scope, out of scope.
argument-hint: "[idea in a sentence, or 'revise']"
disable-model-invocation: true
---

# /brief — one-page game brief

Input: `$ARGUMENTS` (an idea, or `revise` to edit the existing brief).

1. If `docs/brief.md` exists and the argument is not `revise`, show its
   pillars in three lines and ask whether to revise or keep it. Stop if keep.

2. **Interview** with one `AskUserQuestion` round (≤ 4 questions), only what
   the idea does not already answer: genre/reference games, target length
   and platform, what the player does most of the time, the time and team
   available. Offer concrete options, not open questions.

3. **Draft with the `designer` agent.** Pass the idea, the answers and this
   template; ask for the draft back as text (not written yet):

   ```
   # <Title>
   One line: <player fantasy in one sentence>
   ## Pillars (3, each: name — one sentence — a design test "we choose X over Y")
   ## Core loop (verbs, in order, with the minute-to-minute reward)
   ## Scope (platform, length, team, deadline, art style in 3 words)
   ## First playable (the smallest version that tests the core loop)
   ## Out of scope (at least 5 tempting things we will not do)
   ## Open questions
   ```

4. Show the draft. Ask "Write this to docs/brief.md?" with options Write /
   Change something. Apply changes, then write.

5. Update the CHECKPOINT (next step `/art-style`, then `/plan`). Report the path and the next
   command in ≤ 4 lines.

Keep the brief under ~60 lines. The "Out of scope" list is not optional: it is
what keeps a small game small.
