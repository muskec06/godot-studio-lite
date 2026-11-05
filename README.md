# Godot Studio Lite

A lean [Claude Code](https://code.claude.com/docs/en/overview) setup for making
Godot 4 games, solo or with a small team: 11 agents, 15 commands, 7 hooks,
optional mobile and analytics profiles, and cloud CI. Claude draws the
visuals as SVG ($0); sound and music come from fal.ai.

Inspired by [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios):
it keeps that project's best ideas (session state kept in a file, a read
guard, the "run it and look" rule, a Godot 4.5–4.7 API reference) and
simplifies the rest.

## Why leaner?

| | Claude Code Game Studios | Godot Studio Lite |
|---|---|---|
| Engines | Godot, Unity, Unreal | Godot 4 only |
| Agents | 49 | 9 core + 2 optional |
| Commands (skills) | 74 | 15 + 1 reference skill |
| Markdown under `.claude/` | ~3 MB | ~124 KB |
| Context loaded every session | ~9k tokens | **~1.7k tokens** (measured by `tools/selftest.sh`; MCP tool definitions excluded) |
| Settings | `rigor` + 6 sub-settings + a local override chain | One switch: `mode: jam \| project` |
| Python | Required (silently falls back to defaults without it) | Not needed; bash is enough, jq is used when present |
| Godot 3 syntax check | Prompt text | A hook after every `.gd` write |

Every command is declared with `disable-model-invocation: true`: its
description stays out of the context and it runs only when you type `/command`.

## Setup

Requirements: [Claude Code](https://code.claude.com/docs/en/overview),
[Godot 4.7](https://godotengine.org/download), bash (Git Bash on Windows),
git, curl. jq is optional. A [fal.ai](https://fal.ai) account with credits
for sound and music generation.

1. Create your game from this repository: **Use this template** on GitHub,
   or clone it and start a fresh history.
2. Start Claude Code **in the root of that folder** (`claude`). Started in a
   subfolder, the hooks and permission rules do not load.
3. Claude Code asks you to approve the `fal` server from `.mcp.json`; approve
   it, then `/mcp` → `fal` → sign in in the browser. No API key is needed or
   written to any file.
4. Type `/start`: it asks for the game's name, platform, mode, Godot's path
   and the asset budget, creates `game/project.godot`, installs the helper
   scripts and, if you agree, downloads gdUnit4.

Check the setup with `bash tools/selftest.sh`.

## The loop

```
/brief → /art-style → /plan → ( [/asset] → /story → [/review] → /done )* → /playtest → /release
```

1. **`/brief`** — a one-page game brief: pillars, core loop, scope and,
   above all, the **out of scope** list.
2. **`/art-style`** — fixes the look once: route (Claude vector or fal.ai),
   design tokens, references. A ready-made art kit can be applied instead.
3. **`/plan`** — splits the brief into small, testable stories
   (`docs/backlog.md`). Each story lists the art and sound it needs on an
   `Assets:` line.
4. **`/asset`** — makes those assets, choosing a route per asset, with a cost
   estimate and your approval. Optional: code can start on placeholders and
   the real file drops in at the same path without code changes.
5. **`/story`** — hands the next story to the `gdscript-dev` agent, which
   works in its own context so the main session stays clean.
6. **`/review`** — required in `project` mode: the read-only `reviewer`
   agent looks at the change with fresh eyes.
7. **`/done`** — runs the tests, runs the game and takes a screenshot, checks
   acceptance criteria, accessibility, text and asset records. The story
   closes only when everything passes.

## Modes

| | `jam` (default) | `project` |
|---|---|---|
| When | First game, game jam, < 4 weeks | Commercial or long project |
| Review | Optional | Required for every story |
| ADR | Not needed | For decisions that touch more than one system |
| Tests | Optional | Required for game logic |
| "Run it and look" | Required | Required |

Switch with the `mode:` line in `project.yaml`.

## Commands

| Command | What it does |
|---|---|
| `/start` | First-time setup |
| `/brief [idea]` | Writes or revises the game brief |
| `/art-style [idea \| kit]` | Fixes the art route, tokens, palette and references |
| `/asset [S-NNN \| description]` | Makes art or sound: vector ($0), code, or fal.ai (estimate + approval first) |
| `/plan [feature]` | Adds stories to the backlog |
| `/story [S-NNN]` | Implements one story |
| `/review [S-NNN]` | Independent code review |
| `/done [S-NNN]` | Verifies and closes a story |
| `/adr [question]` | Technical decision + record (`docs/adr/`) |
| `/prototype [question]` | Throwaway experiment in `game/prototypes/` |
| `/playtest [notes]` | Turns playtest observations into backlog items |
| `/bug [description]` | Bug report + fix story |
| `/scope [time left]` | Proposes what to cut |
| `/release [version]` | Export and release checklist (never uploads); Android / Play Console list on mobile |
| `/localize [setup\|extract\|translate\|check\|store]` | Moves text to keys, fills missing translations, checks placeholders and fonts, writes store text |
| `/monetize` *(mobile profile)* | Chooses ad and purchase providers, plans the real adapters and stories |
| `/metrics [setup\|report\|provider]` *(analytics profile)* | Wires level events into the game, turns playtest logs into a level funnel, proposes tuning stories |

## Agents

| Agent | Job | Model |
|---|---|---|
| `gdscript-dev` | Implements a story: code, scenes, tests | session model |
| `reviewer` | Read-only code review | sonnet |
| `architect` | Cross-system decisions, ADRs (writes no code) | opus |
| `designer` | Mechanics, numbers, balance (`docs/` only) | sonnet |
| `qa` | Writes tests, reproduces bugs | sonnet |
| `shader-vfx` | Shaders, particles, visual effects | sonnet |
| `godot-docs` | Quick, cheap API verification | haiku |
| `vector-artist` | Draws visuals as SVG from the design tokens, looks at the preview, builds ($0). Writes no code | session model |
| `artist` | Sound effects and music via fal.ai; images vector can't do (painterly, photographic, pixel art). Writes no code | sonnet |
| `writer` *(optional)* | Dialogue, UI text, lore, translations | sonnet |
| `audio` *(optional)* | Sound lists, buses, mix (files are made by `artist`) | sonnet |

Agents never talk to the user directly; they report to the main session in a
fixed format. When something is ambiguous they return `BLOCKED: <question>`
instead of guessing.

## Hooks

| Event | Hook | What it does |
|---|---|---|
| Session start | `session-start.sh` | Injects the checkpoint and the story in progress; reports missing setup |
| Before compaction | `pre-compact.sh` | Logs the compaction in the state file |
| Before a read | `read-guard.sh` | Refuses whole-file reads over 40 KB in `docs/` and `production/` and returns the headings instead |
| After a write | `gd-check.sh` | Catches 17 Godot 3 patterns in `.gd` files; parse-checks when Godot is installed |
| Before/after a fal call | `fal-budget.sh` | Refuses unlisted models and calls past the budget; logs every call with its estimated cost in `production/asset-ledger.tsv` |
| After an SVG write | `svg-guard.sh` | Blocks SVG features Godot can't draw (text, filters, styles, animation, external images); warns on colours outside the tokens |
| End of turn | `session-stop.sh` | While a story is in progress, asks Claude once to refresh a checkpoint older than 20 minutes |

## Mobile profile

Turned on by choosing "mobile" in `/start`, or with
`bash tools/apply-profile.sh mobile portrait` (or `landscape`). It adds
nothing to desktop projects; its rules and commands enter the context only
when the profile is on.

| What it adds | What it is for |
|---|---|
| Project settings | 720×1280 portrait (or 1280×720 landscape), `expand` aspect (full screen on every phone), Compatibility renderer, ETC2/ASTC texture compression, touch emulation from the mouse, back button that does not quit |
| `App` autoload | Android back button, pause/resume signals (to save), safe area (notch, gesture bar), haptics |
| `SafeAreaContainer` | Keeps HUD and menus out from under notches and screen edges |
| `Ads` and `Purchases` autoloads | One entry point for ads and in-app purchases; they run on **mock backends** for now, so the game plays in the editor and in tests without an ad network. `/monetize` plugs in the real providers without changing game code |
| `AdsPolicy` | Interstitial rules: none before level 5, every 3 levels, 60 s apart, none at all once "remove ads" is bought |
| gdUnit4 tests | Ad rules, rewarded ads, purchases, restore, persistence (15 tests) |
| `.claude/rules/mobile.md` | Touch targets ≥ 48 px, safe area, lifecycle, performance, text size, ad placement rules |
| `/monetize` | Chooses the AdMob and Google Play Billing plugins through an ADR, guides the install, learns the real API from the plugin's own files and plans the adapter stories |
| `/done` and `/release` | On-device confirmation for touch and feel stories; Android export, keystore, icons, privacy policy, data safety form, and the 12 testers × 14 days closed-test checklist |
| `artist` / `vector-artist` | Recipes for the app icon (192, 512, adaptive 432 foreground/background) and the store graphic (1024×500) |

`.gitignore` keeps signing keys (`*.keystore`, `*.jks`) and `builds/` out of
the repository. Losing the upload key means you cannot update the app: back
it up, never commit it.

## Vector assets (drawn by Claude, $0)

Flat, illustrated or geometric styles are drawn by Claude as SVG; Godot
imports SVG directly.

- **Design tokens** (`game/assets/_style/tokens.json`): every colour in one
  file. Templates (`game/assets/_src/**/*.svg.tpl`) use colours as `{{token}}`.
- **`bash tools/svg-build.sh`** builds the templates into SVGs under
  `game/assets/`, checks them, records them in ASSETS.md as `claude-vector`
  and generates the `DesignTokens` GDScript class from the same colours.
  Change a colour and rebuild: every image and every colour in code follows.
- **`bash tools/svg-check.sh`** and the **`svg-guard` hook** block what
  Godot's SVG renderer (ThorVG) can't draw: `<text>`, filters, `<style>`,
  animation, external images. Text is drawn by a Godot Label or, like the
  logo, converted to paths.
- **`bash tools/svg-render.sh <svg> [png] [width]`** renders a PNG with
  Godot's own SVG renderer. Claude looks at the preview; store icons are
  exported the same way.
- **`bash tools/build-theme.sh`** builds a Godot theme (buttons, panels,
  labels) from the tokens; **`bash tools/install-fonts.sh`** installs
  Baloo 2 and Rubik (SIL OFL).
- `/asset` picks a route per asset: **vector** ($0, default), **code**
  (theme, shaders, particles, Tweens) or **fal** (sound, music, painterly or
  photographic images).

### Çay Ocağı art kit (`cay-ocagi-art`)

An example kit for a Turkish tea-house sort puzzle, converted one-to-one from
the drawing code of its trailer:
`bash tools/apply-profile.sh cay-ocagi-art && bash tools/svg-build.sh`

| Group | Contents |
|---|---|
| Glass | back tint, liquid mask, cylinder shading, front outline and highlights, saucer (one shared canvas, layers align) |
| Symbols | 8 colour-blind symbols (leaf, drop, flower, sprig, heart, apple, star, bean); drawn white, tinted in Godot |
| Props | samovar with teapot, sugar cube, steam wisp |
| UI | undo, +1 glass and eye icons; tile band; tutorial hand |
| Background | tea-house counter, 720×1600 |
| Brand | logo (lettering converted to paths from Baloo 2), app icon 512, adaptive icon 432 foreground/background, store graphic 1024×500 |
| Code | `GlassView`: builds a glass from its layers, clips the liquid to the glass, keeps the liquid level while tilting, shows colour-blind symbols (with gdUnit4 tests) |
| Docs | `docs/art-style.md` (colours, sizes, rules), `docs/motion-recipes.md` (the trailer's pour, brew, steam and sugar-rain timings as Tween recipes, plus solver-verified levels) |

## Sound, music and fal.ai images

| Asset | Model | Price (Nov 2026) | Quality |
|---|---|---|---|
| Character, object, icon, UI piece | `fal-ai/nano-banana-2/edit` + style references | $0.08 / image | Good |
| Key images | `fal-ai/nano-banana-pro/edit` | $0.15 / image | Good |
| Background, parallax layer | `fal-ai/nano-banana-2` | $0.08 (2K: ×1.5) | Good |
| Transparent background | `fal-ai/bria/background/remove` | $0.018 / image | Good |
| Animation frames (2–4) | Image model + base sprite reference | per image | Weak: check by eye |
| Tiles | Image model | per image | Experimental: check seams |
| Sound effect | `fal-ai/elevenlabs/sound-effects/v2` | $0.002 / second | Good |
| Looping music | `fal-ai/minimax-music/v2.6` | $0.15 / track | Good; listen to the loop seam |
| Long music | `fal-ai/elevenlabs/music` | ~$0.6–0.8 / minute | Good |

- **Rules are enforced in code.** Allowed models live in
  `tools/fal-models.tsv`, all marked "Commercial use" on their fal pages. The
  hook refuses unlisted models and calls past `asset_budget_usd`. Paid calls
  are not pre-approved: Claude Code asks before each one.
- **Pixel-art processing runs in Godot** (`tools/godot/image_tool.gd`): trim,
  area-average downscale, hard alpha, palette mapping, palette extraction
  from a style image, sprite-sheet slicing. No Python or ImageMagick needed.
- **Every file is recorded.** `tools/import-asset.sh` downloads the file,
  keeps the original in `game/assets/_raw/` (reprocessing is free) and writes
  model, prompt and cost to `game/assets/ASSETS.md`.
- **Spend:** `bash tools/fal-cost.sh` (estimated; the real bill is at
  [fal.ai/dashboard/usage](https://fal.ai/dashboard/usage)).
- fal keeps outputs for about 7 days and anyone with the link can open them
  meanwhile, so the tools download every output right away.
- Stores (e.g. Steam) ask you to disclose AI-generated content; `/release`
  drafts that disclosure from ASSETS.md.

## Analytics (profile)

`bash tools/apply-profile.sh analytics`, or `/metrics setup`.

- **`Analytics` autoload:** `level_started / level_completed / level_failed`
  and free-form `event()` calls. Debug builds write one JSON-lines file per
  session to `user://analytics/`; there is no remote server. No personal data
  besides a random install ID, and players can turn it off in settings. With
  the mobile profile, ads and purchases are logged automatically.
- **`bash tools/funnel.sh <folder>`:** a level funnel from playtest logs:
  players who started and finished each level, completion rate, average
  time, fails per player, and how many players reached it.
- **`/metrics report`:** reads the table, names difficulty spikes and the
  biggest drop with numbers, and proposes tuning stories that name the value
  to change. `/metrics provider` later puts a remote service (GameAnalytics,
  Firebase…) behind the same interface.

## Cloud CI (GitHub Actions)

Runs on its own once the folder is a GitHub repository; your computer does
not need to be on.

| Workflow | When | What it does |
|---|---|---|
| `ci.yml` | Every push and pull request | Self-test, localization check; with a `game/project.godot`, downloads Godot 4.7.2, imports the project, **parse-checks every script**, runs the gdUnit4 suite and attaches logs on failure |
| `android.yml` | By hand (Actions → Run workflow) and on `v*` tags | Android debug build with the export templates; a signed release build when the `ANDROID_KEYSTORE_*` secrets exist. Builds are downloadable artifacts |

- The Godot version is the `GODOT_VERSION` line in the workflows; keep it
  equal to the version you use.
- `android.yml` is experimental and needs a committed
  `game/export_presets.cfg` (safe to commit: Godot keeps passwords in a
  separate file). Check the log of its first run.
- GitHub's free plan has a monthly minutes quota for private repositories,
  which is why Android builds run on demand.
- The same checks locally: `bash tools/parse-all.sh`, `bash tools/run-tests.sh`.

## Accessibility

- **`.claude/rules/accessibility.md`:** colour never carries information
  alone; text size and contrast; flash limits; no required rapid tapping;
  a visual cue for every important sound; and a settings screen in every
  game (colour-blind mode, text size, reduce motion, haptics, volume).
- **`bash tools/colorblind.sh palette`** lists which gameplay colours
  (`_style/gameplay_colors.hex`) become confusable under protanopia,
  deuteranopia or tritanopia, with their ΔE.
- **`bash tools/colorblind.sh image <screenshot.png>`** produces three
  colour-vision-deficiency simulations (Machado 2009); `/done` looks at them.
- `/art-style` runs the palette check, `/plan` adds the settings story to the
  first plan, and `/done` checks every visual story.

## Localization

- All player-facing text lives in one CSV: `game/locale/strings.csv`
  (`keys,en,tr`). Languages come from the `languages` line in
  `project.yaml`; default English + Turkish, the first is the source.
- **`bash tools/l10n.sh setup`** creates the CSV and registers the
  translations with Godot. **`bash tools/l10n.sh check`** reports missing
  language columns, empty cells, placeholder (`%d`, `{name}`) mismatches
  between languages, keys used in code but missing from the CSV, and
  hard-coded text. CI runs it on every push.
- **`/localize`** moves hard-coded text to keys, fills missing translations
  with `writer` (including Turkish rules: informal "sen", İ/ı), checks fonts
  and overflow, and writes the store listing in each language.

## Layout

```
CLAUDE.md               Rules Claude reads every session (< 80 lines)
project.yaml            Version, mode, platform, test tool, Godot path, art style, asset budget
.mcp.json               fal.ai MCP server (OAuth; contains no key)
docs/brief.md           Game brief
docs/backlog.md         Every story and its status
docs/art-style.md       Art route, tokens, sizes, references
docs/adr/               Architecture decisions
docs/playtests/         Playtest notes
production/state.md     Session checkpoint (Claude's memory)
production/evidence/    Screenshots proving stories are done
production/asset-ledger.tsv  Every fal call and its estimated cost
game/                   The Godot project (scenes, scripts, tests, addons)
game/assets/            sprites, ui, backgrounds, tiles, sfx, music, store, _style, _src, _raw
game/assets/ASSETS.md   Source, prompt and cost of every asset
game/assets/_style/tokens.json  Design tokens (colours)
game/assets/_src/       Vector templates (*.svg.tpl); built SVGs live under game/assets/
game/locale/strings.csv Player-facing text in every language
tools/                  Setup, test, screenshot, asset and self-test scripts
tools/fal-models.tsv    Allowed fal models and prices
tools/profiles/mobile/      Mobile profile (installed with apply-profile.sh)
tools/profiles/analytics/   Analytics profile
tools/profiles/cay-ocagi-art/  Çay Ocağı art kit (SVG templates, tokens, GlassView)
.github/workflows/      Cloud CI: ci.yml (tests), android.yml (builds)
```

## Context management

- **The memory is a file, not the conversation.** The CHECKPOINT block in
  `production/state.md` is overwritten after every story and decision and
  injected at every session start and after compaction, so `/clear` is safe.
- **One story, one agent context.** Implementation happens in a separate
  context; the main session only chooses, verifies and records.
- **Rules load only when needed.** `.claude/rules/` files are scoped with
  `paths:` — for example the test rules load only while working in
  `game/tests/`. The Godot API reference loads while working on `.gd`/`.tscn`
  files.

## Known limits

- The Godot-dependent scripts (`parse_check.gd`, `screenshot.gd`,
  `run-tests.sh`, `setup-godot.sh`) were written for Godot 4.7; check their
  output on first use. The hooks and the self-test are tested automatically.
- `screenshot.sh` needs a machine with a display; on a server `/done` asks
  you for the screenshot instead.
- Claude does not write export presets or signing settings; `/release` guides
  you through them.
- C# works, but the Godot 3 check and the reference focus on GDScript.
- The fal integration has not been tried with a live account. The budget
  hook and the import script are tested; check the MCP tool names and
  outputs on the first `/art-style` or `/asset` run. If the fal MCP tool's
  parameter names change, the budget estimate may not read counts or
  durations (it then assumes one image / 10 seconds).
- `image_tool.gd`, the mobile profile's GDScript and tests, `GlassView`,
  `build_theme.gd`, the analytics scripts and the colour-blind tools have not
  been run in Godot yet (they pass the Godot 3 check; setting names were
  verified against the Godot 4.7 source docs). After applying a profile, run
  `bash tools/run-tests.sh` first; CI exercises them on real Godot 4.7.2.
- The art kit's SVGs were rendered in a browser and checked by eye. ThorVG
  supports the same subset, but look once with `tools/svg-render.sh` after
  the first build.
- Real ad and purchase adapters are not included: plugin APIs change between
  versions, so `/monetize` has them written against the installed plugin's
  own files. iOS is not covered yet.
- Prices change: `artist` checks current prices with fal before each batch
  and updates `tools/fal-models.tsv`.

## License

MIT. `.claude/skills/godot-api/` and `tools/godot/parse_check.gd` are adapted
from Claude Code Game Studios (MIT, © 2026 Donchitos). Assets generated with
fal.ai are subject to each model's own license and to the
[fal.ai terms of service](https://fal.ai/legal/terms-of-service). The art
kit's logo lettering was converted to paths from Baloo 2 (SIL Open Font
License 1.1).
