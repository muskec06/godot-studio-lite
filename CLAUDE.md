# Godot Studio Lite

A lean Claude Code setup for making a Godot 4 game, solo or with a small team.
The user decides; you propose, build, verify and report.

## Project facts

- Engine, version, mode and test tool live in `project.yaml`. Read it, don't guess.
- Godot project root: `game/` (contains `project.godot`). Tests: `game/tests/`
  (gdUnit4; they must live inside the Godot project to run).
- Your Godot knowledge predates 4.5. Before writing engine API you are unsure
  of, consult the `godot-api` skill (it loads on its own for `.gd` work).

## Where things live

| What | File |
|---|---|
| Game brief (pillars, core loop, out of scope) | `docs/brief.md` |
| Backlog: every story and its status | `docs/backlog.md` |
| Architecture decisions | `docs/adr/NNNN-title.md` |
| Playtest notes | `docs/playtests/YYYY-MM-DD.md` |
| Session checkpoint | `production/state.md` |
| Visual proof of done stories | `production/evidence/` |
| Art style (prompt, sizes, palette, references) | `docs/art-style.md` |
| Every shipped asset: source, prompt, cost | `game/assets/ASSETS.md` |
| Player-facing text, all languages (`tr("KEY")`) | `game/locale/strings.csv` |

## The loop

`/brief` → `/art-style` → `/plan` → (`/asset` → `/story` → `/done`)* → `/playtest` → `/release`

- One story at a time. A story is done only when `/done` passes.
- `mode: jam` — no ADRs, no mandatory review, tests optional.
- `mode: project` — `/review` before `/done`, ADR for any decision that
  touches more than one system, tests required for game logic.

## Working rules

1. Ask before changing files outside the current story's scope, and before
   any commit, push, delete or dependency install.
2. Implementation goes to the `gdscript-dev` agent with the story text and the
   file list; keep the main session for choosing, verifying and recording.
3. Anything the player can see is not done until the game ran and a
   screenshot is in `production/evidence/`. A parse check is not a run.
4. Prefer small scenes, signals over hard references, `@export` for tunables,
   typed GDScript. Data that designers tune goes in `.tres` resources.
5. Stuck after two failed fixes: stop, say what you tried, ask.
6. Assets come through `/asset` or `/art-style`. Default route for visuals:
   `vector-artist` draws SVG templates from `game/assets/_style/tokens.json`
   ($0; build with `tools/svg-build.sh`). fal.ai (paid, `artist`) is for sound,
   music and images vector can't do — estimate and approval first. Every file
   in `game/assets/` has an ASSETS.md row. Never bake text into images.

## Context discipline

- `production/state.md` is the memory, not this conversation. Update its
  CHECKPOINT block (overwrite, ≤ 25 lines) after every finished story,
  decision or blocker. After `/clear` or compaction, read it first.
- Read long docs by section: Grep the heading, then Read with offset/limit.
  Files over 40 KB in `docs/` and `production/` are refused whole.
- Use `godot-docs` (cheap) for API lookups instead of reading the reference
  yourself when you only need one answer.
