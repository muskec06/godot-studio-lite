---
paths:
  - "game/**/*.gd"
  - "game/**/*.tscn"
---

# Mobile rules (platform: mobile)

- **Touch first.** Use `InputEventScreenTouch` / `InputEventScreenDrag`, or
  Control `gui_input` / buttons; mouse events only arrive through
  `emulate_touch_from_mouse` in the editor. No hover states, no right-click,
  no keyboard-only actions.
- **Touch targets ≥ 48 px tall and wide at 720-wide base resolution**
  (Android's 48 dp rule; roughly a fingertip), 8 px apart. Main actions in the
  lower half of a portrait screen, where thumbs reach.
- **Safe area.** HUD and menus sit inside a `SafeAreaContainer`
  (scripts/mobile/safe_area_container.gd). Never put buttons in the outer
  ~5% of the screen without it. Stretch aspect is `expand`: anchor UI to
  edges, never assume 720×1280 exactly.
- **Lifecycle** through the `App` autoload: save on `App.paused` (the OS may
  kill a backgrounded app), handle `App.back_requested` on every screen
  (close popup → pause menu → confirm quit on the main menu).
- **Haptics** with `App.vibrate(ms)` (10–30 ms for taps), respecting the
  setting. Sound and haptics are both toggleable in settings.
- **Performance budget:** 60 fps on a mid-range phone; Compatibility renderer.
  Avoid per-frame allocations, full-screen shaders and many overlapping
  transparent layers (overdraw). Stop processing on menus (`set_process(false)`)
  to save battery.
- **Text** is drawn by Godot at ≥ 28 px on the 720-wide base, never baked into
  images; every player-facing string goes through `tr()`.
- **Monetization** only through the `Ads` and `Purchases` autoloads, never a
  plugin directly. Grant rewards only on `rewarded_result(..., true)`; grant
  consumables only on `purchase_finished(..., true)`. Never show an ad during
  play, on the first session, or right after a loss without an opt-in.
