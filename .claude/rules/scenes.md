---
paths:
  - "game/**/*.tscn"
  - "game/**/*.tres"
---

# Scene and resource files

- Godot writes these files; hand edits must keep its format exactly:
  `[gd_scene load_steps=N format=3 uid="uid://..."]`, `[ext_resource ... id="1_abc"]`,
  then `[sub_resource]`, then `[node]` sections. `load_steps` = resources + 1.
- Do not invent `uid://` values. Omit the `uid=` attribute on new resources
  and let the editor assign one on the next import.
- Never edit `*.import` files or anything under `game/.godot/`.
- One scene per reusable thing (player, enemy, pickup, HUD); the level scene
  instances them. Keep a scene under ~30 nodes; split when it grows.
- Label/Button `text` in scenes is a translation key (`MENU_PLAY`), which
  Godot translates automatically; add the key to `game/locale/strings.csv`.
- Data designers tune (enemy stats, item tables, level params) goes in custom
  `Resource` types saved as `.tres`, not in scene node properties scattered
  across levels.
- Changing a scene that other scenes instance: list the dependents
  (Grep for its path) and say so in the report.
