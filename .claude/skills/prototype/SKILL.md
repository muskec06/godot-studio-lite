---
name: prototype
description: Throwaway experiment to answer one design or tech question fast, in game/prototypes/, outside the backlog and its rules.
argument-hint: "[question to answer, e.g. 'does grappling feel good with rope physics?']"
disable-model-invocation: true
---

# /prototype — answer one question fast

Input: `$ARGUMENTS` — the question. A prototype answers a question; it is not
an early version of the feature.

1. Restate the question as a yes/no or a choice, plus how we will know
   ("feels good if a new player can reach the ledge in < 3 tries").

2. Build it with `gdscript-dev` in `game/prototypes/<slug>/` only: its own
   scene, minimal art (ColorRect, Polygon2D, CSG), hard-coded values allowed,
   no tests. Tell the agent: "Prototype: speed over structure; Godot 4
   syntax still required; touch nothing outside game/prototypes/<slug>/."

3. Run it: `bash tools/screenshot.sh proto-<slug> res://prototypes/<slug>/main.tscn`
   if a display exists, and ask the user to play it (F6 on that scene in the
   editor). Ask the question from step 1.

4. Write the answer to `game/prototypes/<slug>/RESULT.md` (5–10 lines:
   question, what we built, answer, numbers that worked, what to carry over).

5. If the answer is "build it": offer `/plan <feature>` using the RESULT.
   The real feature is written fresh; prototype code is not moved into the
   game.
