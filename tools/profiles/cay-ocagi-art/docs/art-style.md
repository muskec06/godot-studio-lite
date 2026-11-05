# Art style — Çay Ocağı Sort

Style: flat vector illustration, drawn by Claude as SVG · View: front, slightly
above the counter · Mood: warm, cosy, a neighbourhood tea house at golden hour.
Source: the 60-second trailer (artifact "Çay Ocağı Sort Tanıtımı"), whose
canvas drawings were converted 1:1 into the templates in `game/assets/_src/`.

Route: **vector** (Claude, $0) for everything visual. fal.ai only for sound
effects and music.

## Tokens
All colours live in `game/assets/_style/tokens.json` and reach code as
`DesignTokens.color(&"name")` (`game/scripts/generated/design_tokens.gd`).
Change a token, run `bash tools/svg-build.sh`: SVGs and code follow.

## Shapes and rules
- Soft, rounded shapes; no hard black outlines. Glass outline is a warm white
  (`glass_line`, 80%) with two white highlight strokes on the left.
- Light comes from the upper left (window). Shadows are warm brown
  (`shadow`, `shade_dark`) at low opacity, never grey or black.
- Metal is brass: the six-stop `brass_0…5` gradient, left dark → light
  centre → right dark.
- Accent red (`accent_red`) only on porcelain details: saucer rim, demlik band.
- Steam is three warm-white wavy strokes that rise and fade, never a blob.
- Text is drawn by Godot in **Baloo 2** (headings, labels, 800 weight) and
  **Rubik** (buttons, 500–600); both SIL Open Font License 1.1
  (`bash tools/install-fonts.sh`). The logo's lettering was converted from
  Baloo 2 ExtraBold to paths.

## Sizes (base resolution 720 × 1280, portrait)
- Glass SVG: 200 × 460 design size; on screen 55–130 px wide depending on how
  many glasses (layout rules in `docs/motion-recipes.md`).
- Liquid: bottom at 5% of glass height, each of the 4 layers 20.5%.
- Symbols: 62% of a layer's height, max 34% of glass width.
- Buttons: 112 px circles (`btn_face`, `btn_edge`), icon 100 × 100 SVG inside.
- Background: `backgrounds/cafe_counter.svg` 720 × 1600, top-aligned.

## Gameplay colours (colour-blind safe with symbols)
| Drink | Token | Symbol | Symbol colour |
|---|---|---|---|
| Demli çay | drink_demli `#a63e12` | leaf | light |
| Açık çay | drink_acik `#e6ae3a` | drop | dark |
| Ihlamur | drink_ihlamur `#bcc53f` | flower | dark |
| Adaçayı | drink_adacayi `#5c8e4e` | sprig | light |
| Kuşburnu | drink_kusburnu `#d93a58` | heart | light |
| Elma çayı | drink_elma `#ef7a2b` | apple | light |
| Sahlep | drink_sahlep `#f3e7ce` | star | dark |
| Türk kahvesi | drink_kahve `#3b2216` | bean | light |

Check with `bash tools/colorblind.sh palette` (uses `_style/gameplay_colors.hex`).
Pairs it flags are covered by the symbol mode — keep it one tap away.

## Assets in this kit
glass (back, mask, shade, front, saucer) · symbols ×8 · props (semaver with
demlik, sugar cube, steam wisp) · ui (undo, +1 glass and eye icons, çini tile,
tutorial hand) · backgrounds (café counter) · brand (logo, app icon 512,
adaptive icon fg/bg 432, store graphic 1024 × 500).
