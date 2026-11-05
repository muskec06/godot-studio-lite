extends SceneTree
## Runs a scene for a few frames and saves what the player would see.
## Installed by tools/setup-godot.sh to res://addons/gsl_tools/.
##
##   godot --path game -s res://addons/gsl_tools/screenshot.gd -- <scene> <out.png> [frames] [actions]
##
## <scene>   res:// path of the scene to run (e.g. res://scenes/main.tscn)
## <out.png> absolute path for the PNG
## [frames]  frames to wait before capturing (default 60, about 1 s)
## [actions] optional comma list of input actions held from the start, e.g.
##           "ui_right" or "ui_right,ui_accept", to show movement
##
## Needs a real display (not --headless: the dummy renderer draws nothing).
## Exit 0 = saved, 1 = scene did not load or image empty, 2 = bad arguments.

var _frames_left := 60
var _out := ""
var _actions: PackedStringArray = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("screenshot: usage -- <res://scene.tscn> <out.png> [frames] [actions]")
		quit(2)
		return
	var packed := load(args[0]) as PackedScene
	if packed == null:
		printerr("screenshot: could not load scene ", args[0])
		quit(1)
		return
	_out = args[1]
	if args.size() >= 3 and args[2].is_valid_int():
		_frames_left = maxi(1, args[2].to_int())
	if args.size() >= 4 and not args[3].is_empty():
		_actions = args[3].split(",", false)
	root.add_child(packed.instantiate())
	for action in _actions:
		if InputMap.has_action(action):
			Input.action_press(action)
		else:
			printerr("screenshot: unknown input action ", action)


func _process(_delta: float) -> bool:
	_frames_left -= 1
	if _frames_left > 0:
		return false
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		printerr("screenshot: empty image (running headless?)")
		quit(1)
		return true
	var err := image.save_png(_out)
	if err != OK:
		printerr("screenshot: could not save ", _out, " (error ", err, ")")
		quit(1)
		return true
	print("saved: ", _out, " ", image.get_width(), "x", image.get_height())
	quit(0)
	return true
