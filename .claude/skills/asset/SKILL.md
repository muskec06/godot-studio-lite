---
name: asset
description: Make 2D art or sound for the game — one asset, a list, or everything a story needs — choosing per asset between Claude-drawn vector ($0), Godot code, or fal.ai generation, with a cost estimate and approval first.
argument-hint: "[S-NNN | 'player idle sprite' | 'sfx: jump, coin, hurt']"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Edit, Agent, AskUserQuestion, Bash(bash tools/fal-cost.sh*), Bash(bash tools/svg-build.sh*), Bash(bash tools/svg-render.sh*)
---

# /asset — make assets with approval

Input: `$ARGUMENTS` — a story ID (use its `Assets:` line), a description, or
a list. Empty: the `Assets:` line of the story in progress.

1. **Preconditions.** `docs/art-style.md` exists for visual assets (else
   `/art-style` first; sound-only requests don't need it).

2. **List and route.** One row per asset: name, type, destination, size, and
   the **route**:

   | Route | Who | Cost | Use for |
   |---|---|---|---|
   | `vector` | `vector-artist` | $0 | the default for flat, illustrated or geometric styles: sprites, props, icons, UI pieces, backgrounds, app icon, store graphic |
   | `code` | `gdscript-dev` / `shader-vfx` | $0 | buttons/panels (theme: `bash tools/build-theme.sh`), steam, glows, liquid, particles, transitions, anything animated |
   | `fal` | `artist` | per `tools/fal-models.tsv` | sound effects and music (always); painterly, photographic or highly detailed images the art style asks for; pixel-art sprites |

   Follow `Route:` in art-style.md when it names one. Skip files already in
   `game/assets/ASSETS.md` unless the user asked to redo them. Warn on weak
   spots: animation frames (consistency), tiles (seams), music (loop seam).

3. **Estimate.** `vector` and `code` rows cost $0 — list them as such. `fal`
   rows: `bash tools/fal-cost.sh estimate <endpoint> <count> [res|seconds]`,
   +50% retry margin, the total, and `bash tools/fal-cost.sh` (spent/budget).
   Over budget: say so and offer a smaller list or the vector route.

4. **Approve.** `AskUserQuestion`: Make all / Choose some / Cancel. Claude
   Code also asks before each paid fal call — that is expected. If fal tools
   are not connected and fal rows remain: "run `/mcp`, choose fal, sign in".

5. **Make.** Per route, one agent run each with its rows verbatim:
   `vector-artist` (vector), the owning code agent (code, as a small story if
   it touches game code), `artist` with the estimate and "stay within this
   list plus one retry per item" (fal). More than ~8 visual items: batches,
   showing results between them so a style miss is caught early.

6. **Review with the user.** For each new image, Read its PNG (vector: the
   preview from `tools/svg-render.sh`) and describe it in one line; list
   sounds with their paths (the user listens in Godot's FileSystem dock).
   Keep / redo (with what change) / drop. A vector redo is free: edit the
   template or a token and rebuild. Dropped files: move to
   `game/assets/_raw/rejected/` and remove their ASSETS.md row (vector: also
   delete the template).

7. If a story asked for these, add `Assets ready: <paths>` to its section.
   Report per route what was made and the fal spend in ≤ 8 lines.
