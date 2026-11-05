extends GdUnitTestSuite
## Analytics facade: event shape, level timing, opt-out, persistent install ID.

const ANALYTICS := preload("res://scripts/analytics/analytics.gd")
const TEST_DIR := "user://test_analytics"


func after_test() -> void:
	var path := ProjectSettings.globalize_path(TEST_DIR + "/id.cfg")
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func _analytics() -> Node:
	var a: Node = auto_free(ANALYTICS.new())
	a.log_to_file = false
	a.dir = TEST_DIR
	a.id_file = TEST_DIR + "/id.cfg"
	add_child(a)
	return a


func test_events_carry_ids_and_name() -> void:
	var a := _analytics()
	var got: Array = []
	a.tracked.connect(func(e: Dictionary) -> void: got.append(e))
	a.event(&"shop_opened", {"tab": "coins"})
	assert_int(got.size()).is_equal(1)
	assert_str(got[0]["e"]).is_equal("shop_opened")
	assert_str(got[0]["tab"]).is_equal("coins")
	assert_str(got[0]["uid"]).is_not_empty()
	assert_str(got[0]["sid"]).is_not_empty()


func test_level_complete_reports_level_and_time() -> void:
	var a := _analytics()
	var got: Array = []
	a.tracked.connect(func(e: Dictionary) -> void: got.append(e))
	a.level_started(3)
	a.level_completed(3, {"moves": 14})
	var done: Dictionary = got[1]
	assert_str(done["e"]).is_equal("level_complete")
	assert_int(done["level"]).is_equal(3)
	assert_int(done["moves"]).is_equal(14)
	assert_float(done["seconds"]).is_greater_equal(0.0)


func test_opt_out_stops_events_and_is_remembered() -> void:
	var a := _analytics()
	a.set_enabled(false)
	var got: Array = []
	a.tracked.connect(func(e: Dictionary) -> void: got.append(e))
	a.event(&"anything")
	assert_array(got).is_empty()
	var again := _analytics()
	assert_bool(again.is_enabled()).is_false()


func test_install_id_survives_restart() -> void:
	var a := _analytics()
	var again := _analytics()
	assert_str(again.install_id).is_equal(a.install_id)


func test_backend_receives_events() -> void:
	var a := _analytics()
	var b := AnalyticsBackend.new()
	a.use_backend(b)
	a.level_failed(2)
	assert_str(b.events[-1]["e"]).is_equal("level_fail")
