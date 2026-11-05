---
name: bug
description: Report, reproduce and queue a bug — writes a repro-ready entry and a fix story in the backlog; optionally writes a failing test.
argument-hint: "[what went wrong]"
disable-model-invocation: true
---

# /bug — capture a bug properly

Input: `$ARGUMENTS` — what went wrong, in the user's words.

1. Ask only what is missing to reproduce: steps from launch, expected vs
   actual, how often, any error in Godot's Output/Debugger panel (ask them to
   paste it). One `AskUserQuestion` round or a plain question.

2. **Locate** (cheap first): Grep for the node, signal or message involved;
   read the smallest ranges that explain it. If the cause is not clear in a
   few reads, hand it to the `qa` agent: "reproduce and locate; write a
   failing test if the logic is testable".

3. **Queue** a story in `docs/backlog.md` after asking: `S-NNN Fix: <title>`,
   size S unless shown otherwise, acceptance = the repro no longer happens
   (+ the failing test passes), files = the suspects. Mark it `todo`; bugs
   that crash or block progress go first in the table order — say so.

4. Report in ≤ 6 lines: likely cause (or "unknown"), story ID, next command
   (`/story S-NNN`). Do not fix it here unless the user asks — a fix goes
   through `/story` and `/done` like any other change.
