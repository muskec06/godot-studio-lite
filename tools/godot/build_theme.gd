extends SceneTree
## Builds res://resources/theme.tres from the design tokens, so every Button,
## Panel and Label matches the art without image files. Run through
## tools/build-theme.sh (which also makes it the project's default theme).
##
##   godot --headless --path game -s res://addons/gsl_tools/build_theme.gd
##
## Tokens used (game/assets/_style/tokens.json), each with a fallback:
## btn_face, btn_edge, btn_icon, ui_text, ui_ink, ui_gold, ui_pill, ui_muted.
## Fonts: res://assets/fonts/Rubik.ttf (body, buttons) and Baloo2.ttf
## (headings, type variation "HeaderLarge") when present
## (bash tools/install-fonts.sh); otherwise Godot's default font.

const TOKENS := "res://assets/_style/tokens.json"
const OUT := "res://resources/theme.tres"

var tokens: Dictionary = {}


func _initialize() -> void:
	var path := ProjectSettings.globalize_path(TOKENS)
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			tokens = parsed
	var theme := Theme.new()

	var body := _font("res://assets/fonts/Rubik.ttf", 500)
	var heading := _font("res://assets/fonts/Baloo2.ttf", 800)
	if body != null:
		theme.default_font = body
	theme.default_font_size = 30

	# Buttons: warm porcelain face, caramel edge, brown text.
	var face := _c("btn_face", "#fff2de")
	var edge := _c("btn_edge", "#e0b77e")
	var ink := _c("btn_icon", "#6b2f17")
	theme.set_stylebox("normal", "Button", _box(face, edge, 4, 28))
	theme.set_stylebox("hover", "Button", _box(face.lightened(0.06), edge, 4, 28))
	theme.set_stylebox("pressed", "Button", _box(edge, edge.darkened(0.15), 4, 28))
	theme.set_stylebox("disabled", "Button", _box(Color(face, 0.5), Color(edge, 0.5), 4, 28))
	var focus := _box(Color(0, 0, 0, 0), _c("ui_gold", "#e9a73a"), 4, 30)
	focus.draw_center = false
	theme.set_stylebox("focus", "Button", focus)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		theme.set_color(state, "Button", ink)
	theme.set_color("font_disabled_color", "Button", Color(ink, 0.5))
	theme.set_constant("h_separation", "Button", 10)

	# Panels and popups: dark tea pill colour.
	var panel := _box(Color(_c("ui_pill", "#5a2414"), 0.94), Color(0, 0, 0, 0), 0, 28)
	panel.set_content_margin_all(24)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_stylebox("panel", "PopupPanel", panel)

	# Labels: cream text with a dark outline (readable on any background).
	theme.set_color("font_color", "Label", _c("ui_text", "#fff1dc"))
	theme.set_color("font_outline_color", "Label", _c("ui_ink", "#2e0f07"))
	theme.set_constant("outline_size", "Label", 6)
	theme.set_type_variation("HeaderLarge", "Label")
	theme.set_font_size("font_size", "HeaderLarge", 64)
	theme.set_constant("outline_size", "HeaderLarge", 14)
	if heading != null:
		theme.set_font("font", "HeaderLarge", heading)
	theme.set_type_variation("Muted", "Label")
	theme.set_color("font_color", "Muted", _c("ui_muted", "#cbaa8e"))
	theme.set_constant("outline_size", "Muted", 0)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://resources"))
	var err := ResourceSaver.save(theme, OUT)
	if err != OK:
		printerr("build_theme: could not save ", OUT, " (error ", err, ")")
		quit(1)
		return
	print("wrote ", OUT, " (fonts: ", "Rubik" if body != null else "default", ", ", "Baloo 2" if heading != null else "default", ")")
	quit(0)


func _c(token: String, fallback: String) -> Color:
	var v: Variant = tokens.get(token, fallback)
	return Color.html(str(v)) if Color.html_is_valid(str(v)) else Color.html(fallback)


func _box(bg: Color, border: Color, border_w: int, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(border_w)
	b.set_corner_radius_all(radius)
	b.content_margin_left = 28
	b.content_margin_right = 28
	b.content_margin_top = 16
	b.content_margin_bottom = 16
	b.anti_aliasing = true
	return b


func _font(path: String, weight: int) -> Font:
	if not ResourceLoader.exists(path):
		return null
	var base := load(path) as FontFile
	if base == null:
		return null
	var v := FontVariation.new()
	v.base_font = base
	var ts := TextServerManager.get_primary_interface()
	v.variation_opentype = {ts.name_to_tag("wght"): weight}
	return v
