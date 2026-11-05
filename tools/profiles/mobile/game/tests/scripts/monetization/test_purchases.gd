extends GdUnitTestSuite
## Purchases facade with the mock store.

const PURCHASES := preload("res://scripts/monetization/purchases.gd")
const SAVE := "user://test_purchases.cfg"


func before_test() -> void:
	_delete_save()


func after_test() -> void:
	_delete_save()


func _delete_save() -> void:
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _purchases() -> Node:
	var p: Node = auto_free(PURCHASES.new())
	p.save_path = SAVE
	add_child(p)
	return p


func test_buying_remove_ads_grants_it() -> void:
	var p := _purchases()
	p.buy("remove_ads")
	assert_bool(p.has_product("remove_ads")).is_true()


func test_entitlement_survives_restart() -> void:
	var p := _purchases()
	p.buy("remove_ads")
	var again := _purchases()
	assert_bool(again.has_product("remove_ads")).is_true()


func test_failed_purchase_grants_nothing() -> void:
	var p := _purchases()
	var results: Array = []
	p.purchase_finished.connect(func(id: String, ok: bool, _r: String) -> void: results.append([id, ok]))
	p.backend.fail_next = true
	p.buy("remove_ads")
	assert_bool(p.has_product("remove_ads")).is_false()
	assert_array(results).is_equal([["remove_ads", false]])


func test_consumables_are_not_stored() -> void:
	var p := _purchases()
	p.buy("coins_small")
	assert_bool(p.has_product("coins_small")).is_false()


func test_restore_brings_back_owned_products() -> void:
	var p := _purchases()
	p.backend.restored.emit(PackedStringArray(["remove_ads", "unknown_sku"]))
	assert_bool(p.has_product("remove_ads")).is_true()
	assert_bool(p.has_product("unknown_sku")).is_false()
