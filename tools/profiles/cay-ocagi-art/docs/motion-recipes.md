# Motion recipes — from the trailer to Godot

Timings and curves measured from the trailer's code, translated to Godot 4
`Tween` calls. Easing names: trailer `ease` = `TRANS_QUAD, EASE_IN_OUT`;
`easeOut` = `TRANS_CUBIC, EASE_OUT`; `back` = `TRANS_BACK, EASE_OUT`.

## Pour (the core move)
Total duration by context: tutorial 1.3 s · normal play 0.9 s · fast montage
0.6 s · speed-run 0.46 s. Phases as fractions of the total:

| Phase | From → to | What happens |
|---|---|---|
| 0.00–0.16 | lift | source glass rises 20% of its height (quad in-out) |
| 0.16–0.40 | travel | moves to the pour pose beside the target and tilts to 1.02 rad (≈ 58°) toward it (quad in-out); pick the side that keeps the glass on screen |
| 0.40–0.80 | pour | holds, tiny wobble `sin(t·30)·0.015 rad`; stream on; `top_fill` of source falls 1→0 while the target's new layer rises 0→1 (fill progress `clamp((p−0.42)/0.36)`) |
| 0.80–1.00 | return | back to its place, rotation to 0 (quad in-out) |

Stream: a `Line2D` from the source rim lip to the target's liquid surface
(`GlassView.surface_global_position()`), a slight curve outward, width 11% of
the glass width, colour of the poured drink; it thins in over the first 0.05
and out over the last 0.05 of the pour phase. A small ellipse splash
(14% × 3.5% of glass width, colour lightened 10%) sits on the surface.

```gdscript
func pour(src: GlassView, dst: GlassView, pose: Vector2, angle: float, total := 0.9) -> void:
	var home := src.position
	var t := create_tween()
	t.tween_property(src, "position", home + Vector2(0, -src.glass_width * 2.3 * 0.2), total * 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(src, "position", pose, total * 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(src, "rotation", angle, total * 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_method(_set_pour.bind(src, dst), 0.0, 1.0, total * 0.40)
	t.tween_property(src, "position", home, total * 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(src, "rotation", 0.0, total * 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _set_pour(p: float, src: GlassView, dst: GlassView) -> void:
	src.top_fill = 1.0 - p
	dst.top_fill = p
```
(Before the fill step, append the poured drink to `dst` with `top_fill = 0`;
after it, remove it from `src`. Several same-colour layers move together.)

## Feedback
- **Tap:** ripple ring, radius 18 → 82 px, width 10 → 2, alpha 0.9 → 0, 0.4 s.
  `App.vibrate(15)` on mobile.
- **Glass completes ("demlendi"):** bounce up 9% of its height and back,
  `sin(π·t/0.5)` over 0.5 s; warm radial glow behind it; steam fades in over
  0.4 s; "Demlendi!" pops 40 px above the rim, rises 50 px over 0.6 s
  (cubic out), stays 0.7 s, fades 0.3 s — text in `ui_pop_text` with a
  `ui_pill` outline, Baloo 2 800, size ≈ 30% of glass width + 8.
- **Steam:** 3 wisps per completed glass, each cycling every 2 s (offsets
  1/3), alpha `sin(π·u)·0.55`, rising 80% of glass width while drifting
  sideways `sin(j·0.7 + t·2.2)·7%`; width 5.5% of glass width, thinning 40%.
  `props/steam_wisp.svg` as a `GPUParticles2D` texture is the cheap version.
- **Level complete:** "Bölüm tamam!" ("Level complete!") pill (`ui_gold` / `ui_banner_text`),
  scale 0 → 1 with back-out over 0.35 s; sugar rain: 20 cubes, 1.7 s, fall
  with `q²` acceleration, gentle spin and sway, fade out in the last 20%.
- **Stuck (no moves):** shake ±16 px at 70 Hz decaying over 0.45 s, dim the
  counter 32% for ~2 s, highlight "+1 Bardak" with a pulsing glow
  (`0.6 + 0.4·sin(t·14)`).
- **Undo:** the last pour plays backwards at 0.7 s.
- **+1 glass:** new glass slides in from 620 px right over 0.8 s (cubic out)
  while the others re-lay out over the same time.
- **Level intro:** level pill scales in with back-out 0.3 s, fades after 0.85 s.
- **Level change:** counter slides out left 0.28 s (quad), the next slides in
  from the right 0.32 s (cubic out).
- **Colour-blind toggle:** symbols fade in over 0.35 s.

## Layout (trailer, converted to the 720-wide base)
Rows: 1 row up to 3 glasses; 2 rows (ceil/floor halves) up to 8; for 9+,
5 on top and the rest below. Spacing = 720 px / glasses in the widest row;
glass width = min(131, spacing × 0.64); height = width × 2.3. Row baselines
(glass bottoms) at y ≈ 900 for a single row, ≈ 665 and 1060 for two rows,
measured on the trailer's 720 × 1328 screen — scale y to the real viewport.

## Verified levels from the trailer (bottom → top, drink indices)
Useful as solver test fixtures.
- **Level 1** (3 drinks, 2 empty): `[[4,0,2,2],[4,2,2,4],[0,0,4,0],[],[]]`;
  solved in 7 moves `[from, to, count]`: `[0,3,2] [2,0,1] [1,2,1] [1,3,2] [2,1,2] [0,2,2] [0,1,1]`.
- **Level 30 position** (8 drinks, 1 empty, 3 already complete):
  `[[1,1,2,2],[0,0,1,1],[4,4,2,2],[0,3,4,3],[0,3,3,4],[],[5,5,5,5],[6,6,6,6],[7,7,7,7]]`
  — unsolvable as is; with one extra empty glass solved in 10 moves:
  `[0,5,2] [1,0,2] [2,5,2] [3,9,1] [3,2,1] [3,9,1] [1,3,2] [4,2,1] [4,9,2] [3,4,3]`.
