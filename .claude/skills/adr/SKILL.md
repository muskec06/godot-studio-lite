---
name: adr
description: Make a technical decision with the architect agent and record it as an Architecture Decision Record in docs/adr/.
argument-hint: "[the decision to make, e.g. 'how to save game progress']"
disable-model-invocation: true
---

# /adr — decide and record

Input: `$ARGUMENTS` — the question. Empty: ask what needs deciding.

1. List `docs/adr/` titles (Glob). If an accepted ADR already covers the
   question, show it and ask whether to revisit; stop if not.

2. **Options.** Run the `architect` agent with the question and "give options
   and a recommendation; do not write the ADR yet".

3. **Decide.** Show the options (≤ 20 lines, keep the agent's trade-offs) and
   ask with `AskUserQuestion`: one option per choice, recommended first.

4. **Record.** Resume the same architect agent (or run it again with the
   options it gave) with the user's choice and "write the ADR now". It writes
   `docs/adr/NNNN-title.md`.

5. If the decision changes stories in `docs/backlog.md` (new work, or a
   `todo` story that is now wrong), list them and ask before editing.

6. Add one line to the CHECKPOINT ("ADR NNNN accepted: <decision>").
   Report the path and the decision in ≤ 4 lines.

In `mode: jam` this command still works, but tell the user once that jam mode
doesn't require ADRs.
