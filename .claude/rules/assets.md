---
paths:
  - "game/assets/**"
---

# Asset rules

- Files arrive through `tools/import-asset.sh`, which keeps the original in
  `_raw/` and writes the `ASSETS.md` row. Copying a file in by hand: run the
  script on it anyway (`--model local --note "<origin, licence>"`).
- Never edit `_raw/` files; reprocess from them instead of regenerating.
- **Vector assets:** the source is `_src/<path>.svg.tpl`; the `.svg` next to the
  game files is built output. Edit the template or a token in
  `_style/tokens.json`, then `bash tools/svg-build.sh` — never hand-edit a
  built `.svg` (the next build overwrites it). Colours come from tokens;
  code reads the same values via `DesignTokens.color(&"name")`.
- Godot draws SVG with ThorVG: no `<text>`, filters, `<style>` or animation
  (the svg-guard hook enforces this). Author at ~2× on-screen size.
- Names: `snake_case`, what it is first, state last: `slime_green_hurt.png`,
  `ui_button_primary.png`, `sfx_coin_pickup.mp3`. Frames: `_00`, `_01` …
- Pixel art keeps its native size; scale up in Godot (integer stretch, Nearest
  filter), never by resizing the file.
- No text inside images: labels, numbers and dialogue are drawn by Godot so
  they can be translated and resized.
- Replacing an asset keeps its path, so scenes and code need no change.
