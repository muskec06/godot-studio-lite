---
name: godot-api
description: Godot 4.4–4.7 API changes Claude's training data does not cover — renamed and removed APIs, new defaults (Jolt, D3D12), GDScript 4.5+ features, test and parse-check command lines. Use before writing or reviewing GDScript, scenes or shaders, and whenever unsure an engine API exists in Godot 4.7.
user-invocable: false
paths:
  - "game/**/*.gd"
  - "game/**/*.tscn"
  - "game/**/*.tres"
  - "game/**/*.gdshader"
---

# Godot API reference (4.4 → 4.7)

Pinned version: **Godot 4.7** (latest patch 4.7.2, Aug 2026). Check
`godot_version` in `project.yaml`; if it is older than 4.7, ignore rows marked
4.7 and say so.

Your training data covers Godot up to about 4.3. 4.4 is thin, 4.5–4.7 are
missing. When an API is not in these files and you are not sure it exists in
4.7, say so and ask the `godot-docs` agent to check the official docs rather
than guessing.

## Read only what the task needs

| Question | File, section |
|---|---|
| Will this old API still work? | `deprecated-apis.md` (find the name with Grep) |
| What changed between versions? | `breaking-changes.md`, the version heading |
| Idiomatic 4.5+ GDScript (typing, `@abstract`, variadic args, lambdas) | `current-best-practices.md` § GDScript |
| Running tests or a parse check from the command line | `current-best-practices.md` § Command Line |
| A specific subsystem | `modules/<name>.md`: animation, audio, input, navigation, networking, physics, rendering, ui |

Grep the heading, then Read with offset/limit. Do not load every file.

## Facts worth keeping in mind every time

- Physics: Jolt is the default 3D engine since 4.6. Jolt `WorldBoundaryShape3D`
  plane sign flipped in 4.7.
- Rendering: D3D12 is the default on Windows since 4.6; glow was reworked.
- GDScript 4.7: an override of a typed-return method inherits the type and
  needs an explicit `return`.
- Input 4.7: mouse/keyboard device IDs are `InputEvent.DEVICE_ID_MOUSE` /
  `DEVICE_ID_KEYBOARD`, not `0`.
- Audio 4.7: `AudioStreamPlayer2D/3D.area_mask` defaults to 0 (disabled).
- ripgrep has no `gdscript` type; filter with `glob: "*.gd"`.
- `--check-only` reports false errors for code that names an autoload; use
  `res://addons/gsl_tools/parse_check.gd` instead (the `gd-check` hook does).

Sources and verification dates are at the top and bottom of each file. This
reference is adapted from Claude Code Game Studios (MIT).
