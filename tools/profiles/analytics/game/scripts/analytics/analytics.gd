extends Node
## Gameplay analytics (autoload "Analytics"). Game code reports what happens;
## where it goes is decided here:
##   - a local JSON-lines log in user://analytics/ (debug builds by default):
##     one file per session, read by tools/funnel.sh after playtests
##   - a remote backend, if one is installed with use_backend() (/metrics provider)
##
##   Analytics.level_started(3)
##   Analytics.level_completed(3, {"moves": 14})
##   Analytics.level_failed(3, {"reason": "no_moves"})
##   Analytics.event(&"shop_opened")
##
## Privacy: events carry a random install ID, never names, emails, device IDs
## or locations. set_enabled(false) stops everything (settings opt-out; also
## call it until consent where a remote backend needs consent).

signal tracked(event: Dictionary)

## Overridable for tests.
var dir: String = "user://analytics"
var id_file: String = "user://analytics/id.cfg"

## Write the local session log. Debug builds by default; playtest builds too.
var log_to_file: bool = OS.is_debug_build()
var backend: AnalyticsBackend
var install_id: String = ""
var session_id: String = ""

var _enabled: bool = true
var _file: FileAccess
var _level_start_msec: Dictionary = {}


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	_load_identity()
	session_id = _random_id()
	backend = AnalyticsBackend.new()
	if log_to_file and _enabled:
		var stamp := Time.get_datetime_string_from_system().replace(":", "").replace("-", "").replace("T", "-")
		_file = FileAccess.open("%s/%s-%s.jsonl" % [dir, stamp, session_id.left(6)], FileAccess.WRITE)
	event(&"session_start", {
		"version": str(ProjectSettings.get_setting("application/config/version", "")),
		"platform": OS.get_name(),
		"locale": TranslationServer.get_locale(),
	})


func use_backend(new_backend: AnalyticsBackend) -> void:
	if backend != null:
		backend.flush()
	backend = new_backend


func is_enabled() -> bool:
	return _enabled


## Player opt-out (settings) or consent gate. Remembered across sessions.
func set_enabled(on: bool) -> void:
	_enabled = on
	_save_identity()


func event(name: StringName, params: Dictionary = {}) -> void:
	if not _enabled:
		return
	var e := {"t": snappedf(Time.get_unix_time_from_system(), 0.001), "uid": install_id, "sid": session_id, "e": String(name)}
	e.merge(params, false)
	tracked.emit(e)
	backend.track(e)
	if _file != null:
		_file.store_line(JSON.stringify(e))


func level_started(level: int, extra: Dictionary = {}) -> void:
	_level_start_msec[level] = Time.get_ticks_msec()
	var p := {"level": level}
	p.merge(extra, false)
	event(&"level_start", p)


func level_completed(level: int, extra: Dictionary = {}) -> void:
	var p := {"level": level, "seconds": _seconds_in(level)}
	p.merge(extra, false)
	event(&"level_complete", p)


func level_failed(level: int, extra: Dictionary = {}) -> void:
	var p := {"level": level, "seconds": _seconds_in(level)}
	p.merge(extra, false)
	event(&"level_fail", p)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		event(&"session_pause")
		if _file != null:
			_file.flush()
		if backend != null:
			backend.flush()


func _seconds_in(level: int) -> float:
	if not _level_start_msec.has(level):
		return -1.0
	return snappedf((Time.get_ticks_msec() - int(_level_start_msec[level])) / 1000.0, 0.1)


func _random_id() -> String:
	return Crypto.new().generate_random_bytes(8).hex_encode()


func _load_identity() -> void:
	var cf := ConfigFile.new()
	if cf.load(id_file) == OK:
		install_id = str(cf.get_value("analytics", "install_id", ""))
		_enabled = bool(cf.get_value("analytics", "enabled", true))
	if install_id.is_empty():
		install_id = _random_id()
		_save_identity()


func _save_identity() -> void:
	var cf := ConfigFile.new()
	cf.set_value("analytics", "install_id", install_id)
	cf.set_value("analytics", "enabled", _enabled)
	cf.save(id_file)
