extends Node
## Mobile app lifecycle (autoload "App"): Android back button, pause/resume,
## safe area and haptics. Game code listens to these signals instead of
## handling notifications itself.
##
## project.godot sets application/config/quit_on_go_back=false, so the back
## button no longer quits: handle back_requested (close the popup, open the
## pause menu, or call get_tree().quit() on the main menu).

signal back_requested
## App went to the background (or lost focus on desktop). Save now: a mobile
## OS may kill a backgrounded app without warning.
signal paused
signal resumed

var haptics_enabled: bool = true


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back_requested.emit()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			paused.emit()
		NOTIFICATION_APPLICATION_RESUMED:
			resumed.emit()


## Short haptic tick for taps and successes. No-op on desktop.
## Android needs the VIBRATE permission in the export preset.
func vibrate(duration_ms: int = 20) -> void:
	if haptics_enabled and OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms)


## Safe-area insets (notch, rounded corners, gesture bar) in viewport units,
## as {left, top, right, bottom}. All zero on desktop.
func safe_insets() -> Dictionary:
	var none := {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	if not OS.has_feature("mobile"):
		return none
	var win := DisplayServer.window_get_size()
	var safe := DisplayServer.get_display_safe_area()
	if win.x <= 0 or win.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return none
	var vp := get_viewport().get_visible_rect().size
	var s := vp / Vector2(win)
	return {
		"left": maxf(0.0, safe.position.x * s.x),
		"top": maxf(0.0, safe.position.y * s.y),
		"right": maxf(0.0, (win.x - safe.end.x) * s.x),
		"bottom": maxf(0.0, (win.y - safe.end.y) * s.y),
	}
