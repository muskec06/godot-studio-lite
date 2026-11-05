extends SceneTree
## Parse-checks Godot scripts the way the game loads them.
## Installed by /start (via tools/setup-godot.sh) to res://addons/gsl_tools/.
##
##   godot --headless --path game -s res://addons/gsl_tools/parse_check.gd -- res://a.gd res://b.gd
##
## Prints `ok: <path>` or `PARSE FAIL: <path>` per script, with Godot's own
## error lines above each failure. Exit 0 when every script loads, 1 when any
## does not, 2 when no script was given.
##
## Why not `--check-only`: it compiles the file with no autoloads registered,
## so valid code that names an autoload fails with "Identifier not found".
## Loading in `_initialize()` runs after startup has registered them.
##
## Adapted from Claude Code Game Studios (MIT).


func _initialize() -> void:
	var paths := OS.get_cmdline_user_args()
	if paths.is_empty():
		printerr("parse_check: no scripts given. Pass res:// paths after `--`.")
		quit(2)
		return
	var failed := 0
	for path in paths:
		var script := load(path) as Script
		# A script with a parse error still loads but cannot instantiate.
		# Abstract classes (@abstract, 4.5+) cannot instantiate either, so they
		# are allowed through when the engine can tell us they are abstract.
		var is_abstract := script != null and script.has_method("is_abstract") and script.call("is_abstract")
		if script == null or (not script.can_instantiate() and not is_abstract):
			printerr("PARSE FAIL: ", path)
			failed += 1
		else:
			print("ok: ", path)
	quit(1 if failed > 0 else 0)
