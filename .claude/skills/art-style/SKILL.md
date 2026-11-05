---
name: art-style
description: Define the game's 2D art style once — route (Claude-drawn vector at $0, or fal.ai images), size, view, palette, design tokens and approved references that every later asset follows. Can start from an art kit in tools/profiles.
argument-hint: "[style idea | kit name | 'revise']"
disable-model-invocation: true
---

# /art-style — lock the look before making assets

Input: `$ARGUMENTS`. Every later asset copies this style, so it is worth
getting right once. If `docs/art-style.md` exists and the argument is not
`revise`, show its summary and stop. `docs/brief.md` should exist (else
suggest `/brief`).

## 0. Kit?
List art kits (`tools/profiles/*-art/`). If one fits the brief or the
argument names it, offer it: `bash tools/apply-profile.sh <kit>` then
`bash tools/svg-build.sh` — tokens, templates, art-style.md and code helpers
arrive ready; go to step 6 to adapt them. (A kit can also be made from an
existing drawing or animation of the user's: read it and convert its shapes
into templates, as `cay-ocagi-art` was made from the trailer.)

## 1. Ask (one `AskUserQuestion`, ≤ 4 questions, recommended first)
- **Route:** Claude-drawn vector, $0, editable, sharp on every screen
  (recommended for flat / illustrated / cartoon / geometric looks) · fal.ai
  images (painterly, photographic, very detailed, or pixel art; ~$0.3–0.8 to
  set up, then per image).
- Style: flat vector / soft illustration / pixel art (`art_style` default).
- View: side-on / top-down / three-quarter / front (board or puzzle).
- Mood: 3 options from the brief's pillars and setting.
Then once, optional: reference games or images it should feel like.

## 2. Tokens (both routes)
Write `game/assets/_style/tokens.json`: a flat `"name": "#rrggbb"` map — a
background pair, surface/panel, text and ink, an accent, button face/edge/
icon (`btn_face`, `btn_edge`, `btn_icon`, `ui_text`, `ui_ink`, `ui_gold`,
`ui_pill`, `ui_muted` feed the Godot theme), and one token per gameplay
colour. Show the swatches as a small table before writing.

## 3a. Vector route ($0)
Run `vector-artist`: "Job: /art-style concepts. Draw 3 concepts of <the
brief's main object or character> as templates `_src/concepts/concept_N.svg.tpl`
using tokens.json, each a different take on the mood; build and render them."
Read the 3 previews, describe each in one line, ask which sets the style or
what to change (free to iterate). Keep the chosen template as
`_src/<folder>/<name>.svg.tpl` (it is the first real asset); delete the rest.

## 3b. fal route
Draft a 2–3 line style prompt (medium, outline, shading, light, colour mood,
what to avoid). Ask: "Generate 4 concepts of <subject> with
`fal-ai/nano-banana-2` (~$0.32)?" Check fal tools (else `/mcp` → fal → sign
in). Run `artist`: "Job: /art-style concepts …; import to
`_style/concept_1.png` … `_style/concept_4.png` with no processing." Show,
pick, keep as `_style/ref_1.png`, move the others to `_raw/_style/`. Pixel
art: derive the palette with
`<godot_bin> --headless --path game -s res://addons/gsl_tools/image_tool.gd -- extract <abs ref_1.png> <abs _style/palette.hex> 16`.

## 4. Gameplay colours
If the game codes information by colour: write `_style/gameplay_colors.hex`
and run `bash tools/colorblind.sh palette`. For every flagged pair change a
colour or decide the second signal (shape, pattern, icon) — record it.

## 5. Theme and fonts (vector route, recommended for both)
Offer `bash tools/install-fonts.sh` (asks network; OFL fonts) — or name the
fonts the user prefers — then `bash tools/build-theme.sh` so Buttons, Panels
and Labels use the tokens.

## 6. Write `docs/art-style.md` after showing it
```
# Art style
Route: vector | fal · Style: <…> · View: <…> · Mood: <…>
Shapes and rules: <outline, shading, light, metal/glass/etc. treatments>
Style prompt (fal only): <2–3 lines> · Negative: <…>
Sizes: base resolution · main object px · UI scale · background WxH
Tokens: game/assets/_style/tokens.json · Palette: <file> | none
Gameplay colours: _style/gameplay_colors.hex · second signal: <…> | n/a
References: <templates or ref images, what each is>
```
Set `art_style` in project.yaml if it changed. Report cost (vector: $0;
fal: `bash tools/fal-cost.sh`) and the next step (`/asset`) in ≤ 5 lines.
