---
name: start
description: First-time setup — name the game, choose platform (desktop or mobile) and mode, find Godot, create the Godot project, install helpers and gdUnit4, connect fal.ai.
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Glob, Bash(bash tools/setup-godot.sh*), Bash(bash tools/apply-profile.sh*), Bash(bash tools/l10n.sh*), Bash(command -v *), Bash(which *)
---

# /start — set up the project

Run each step; skip the ones already done (check first, don't redo).

1. **Read the state.** `project.yaml`, whether `game/project.godot` exists,
   whether `docs/brief.md` exists. If everything is set up, say so in two
   lines, suggest the next command (`/brief` or `/plan` or `/story`), and stop.

2. **Ask the user** (one `AskUserQuestion`, up to 4 questions, skip any
   already answered in `project.yaml`):
   - Game name (free text via "Other"; offer two placeholder options).
   - Mode: `jam` (fast, no ADRs or mandatory review, tests optional) or
     `project` (review before done, ADRs, tests for logic). Recommend `jam`
     for a first game or anything under ~4 weeks.
   - Platform: desktop / mobile portrait / mobile landscape.
   - Art style: pixel art or illustration/vector. For mobile recommend
     illustration: pixel art needs integer scaling, which letterboxes most
     phones.
   Language defaults to GDScript and the game to 2D; mention both in one line
   and change them only if the user objects.

3. **Find Godot.** Try `command -v godot godot4`. If none, ask the user for
   the path to the Godot 4.x executable (Windows: the `.exe`; macOS:
   `/Applications/Godot.app/Contents/MacOS/Godot`). Write it to `godot_bin`.
   If they don't have Godot yet: link https://godotengine.org/download and
   continue without it — the hooks skip Godot-only checks.

4. **Write `project.yaml`** values with Edit (name, mode, language,
   art_style, godot_bin). Ask the user which version they installed if
   `godot_version` differs.

5. **Create the Godot project**: `bash tools/setup-godot.sh`. Show its output
   lines that matter. Mobile: then `bash tools/apply-profile.sh mobile
   <portrait|landscape>` — it adds the mobile rule, the `/monetize` command,
   the `App`/`Ads`/`Purchases` autoloads with mock backends and their tests,
   and switches the project to mobile display settings. Tell the user: test on
   a real phone early (Android: enable USB debugging, then the editor's
   Remote Deploy button), and that publishing needs a Google Play developer
   account, whose first app requires a 14-day closed test with 12 testers.

5b. **Languages, analytics, CI.** Confirm `languages` (default `en tr`, first
   = source) and run `bash tools/l10n.sh setup`. Offer the analytics profile
   (`bash tools/apply-profile.sh analytics`; recommended for mobile — it
   writes local playtest logs that `/metrics report` turns into a level
   funnel). Mention that `.github/workflows/ci.yml` runs the tests on GitHub
   on every push once the folder is a GitHub repository.

6. **Tests.** If `test_framework` is `gdunit4` and `game/addons/gdUnit4` is
   missing, ask: "Install gdUnit4 v6.2.2 from GitHub into game/addons? (needs
   network)". On yes: `bash tools/install-gdunit4.sh`. On no: set
   `test_framework: none` in jam mode, or leave it and note it in project mode.

6b. **Asset generation (fal.ai).** Check whether `mcp__fal__*` tools are
   available. If not, tell the user: approve the `fal` server from `.mcp.json`
   when Claude Code asks, then run `/mcp`, choose `fal`, sign in in the
   browser (needs a fal.ai account with credits). Ask for the asset budget
   (default $20) and write `asset_budget_usd`. Skippable: the game can be
   built on placeholders and art added later.

7. **Checkpoint.** Overwrite the CHECKPOINT block in `production/state.md`:
   current story none, next step `/brief` (then `/art-style`), the mode, today's date.

8. **Report** in ≤ 8 lines: what was set up, what is missing, next command.
   Remind them to start Claude Code in this folder (hooks load only there) and
   to `git init` + commit if they want history.
