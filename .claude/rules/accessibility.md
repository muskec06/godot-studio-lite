---
paths:
  - "game/**/*.gd"
  - "game/**/*.tscn"
  - "docs/brief.md"
  - "docs/art-style.md"
---

# Accessibility rules

- **Colour is never the only signal.** Anything the player must tell apart
  (teams, item types, sort colours, health states) also differs by shape,
  pattern, icon, position or label. Gameplay colours live in
  `game/assets/_style/gameplay_colors.hex`; check them with
  `bash tools/colorblind.sh palette` (no pair below ΔE 15 under any
  deficiency, or a second signal for that pair).
- **Text:** body text ≥ 28 px at the base resolution on mobile (≥ 20 px on
  desktop), contrast ≥ 4.5:1 against its background (3:1 for large text).
  Text is never baked into images.
- **Motion and flashes:** nothing flashes more than 3 times per second;
  screen shake and large camera motion can be reduced in settings.
- **Input:** no action requires fast repeated tapping, precise timing or
  holding as the only way, unless that is the core challenge — then offer
  an assist. Desktop: all actions are rebindable through the Input Map.
- **Sound:** every gameplay-relevant sound has a visual cue; separate
  music / effects volume.
- **Settings screen** (one story in the first `/plan`): colour-blind mode
  (patterns/icons on), text size, reduce motion, haptics toggle, volume
  sliders. Settings persist and apply immediately.
