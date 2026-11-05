class_name SafeAreaContainer
extends MarginContainer
## Put HUD and menu content inside this node (anchored Full Rect): it pads by
## the device safe area — notch, rounded corners, gesture bar — plus
## extra_margin, so buttons are never hidden or hard to reach.

@export var extra_margin: int = 16


func _ready() -> void:
	_apply()
	get_viewport().size_changed.connect(_apply)


func _apply() -> void:
	var insets := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	var app := get_node_or_null("/root/App")
	if app != null and app.has_method("safe_insets"):
		insets = app.call("safe_insets")
	add_theme_constant_override("margin_left", int(insets["left"]) + extra_margin)
	add_theme_constant_override("margin_top", int(insets["top"]) + extra_margin)
	add_theme_constant_override("margin_right", int(insets["right"]) + extra_margin)
	add_theme_constant_override("margin_bottom", int(insets["bottom"]) + extra_margin)
