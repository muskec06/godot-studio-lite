---
paths:
  - "game/**/*.gd"
---

# GDScript rules

- Static typing everywhere it is cheap: `var hp: int = 10`, `func hit(n: int) -> void`,
  `:=` when the type is obvious. Typed arrays: `Array[Enemy]`.
- Order inside a script: `class_name`, `extends`, signals, enums, constants,
  `@export`s, public vars, private `_vars`, `@onready`s, built-in callbacks
  (`_ready`, `_process`…), public methods, private `_methods`.
- Names: `snake_case` files, functions, variables; `PascalCase` classes and
  nodes; `UPPER_CASE` constants; signals in past tense (`died`, `health_changed`).
- Tunable numbers are `@export` (or fields of a `Resource`), never magic
  numbers in logic. Group them with `@export_group`.
- Talk up with signals, down with method calls. Never `get_parent().get_parent()`.
  Nodes the script owns: `%UniqueName`. Cross-scene access: an autoload or a
  signal, not a node path.
- Movement and physics in `_physics_process`, scaled by `delta` when not using
  `move_and_slide()`'s velocity. Input actions from the Input Map, not key codes.
- No allocations or `get_node()` lookups per frame in hot paths; cache in
  `@onready`.
- Player-facing text is a key from `game/locale/strings.csv`: `tr("MENU_PLAY")`,
  `tr("LEVEL_N") % n`. Never a literal sentence in code (debug prints are fine).
- `game/prototypes/**` is exempt from the structure rules above (still Godot 4
  syntax). Prototype code is never imported by the real game.
