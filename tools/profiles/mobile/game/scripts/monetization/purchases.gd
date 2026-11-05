extends Node
## In-app purchases facade (autoload "Purchases"). Owns entitlements — the
## non-consumable products the player has bought — and saves them. Which
## store sits behind it is decided once, in use_backend().
##
##   Purchases.buy("remove_ads")       -> purchase_finished(id, ok, reason)
##   Purchases.has_product("remove_ads")
##   Purchases.restore()               -> call from a "Restore purchases" button
##
## Consumables (coin packs): grant the content in a purchase_finished handler
## with ok == true; they are not stored here.

signal purchase_finished(product_id: String, ok: bool, reason: String)
signal entitlements_changed

var save_path: String = "user://purchases.cfg"
var config: MonetizationConfig
var backend: StoreBackend

var _owned: Dictionary = {}


func _ready() -> void:
	config = MonetizationConfig.load_or_default()
	load_entitlements()
	use_backend(StoreBackend.new())


func use_backend(new_backend: StoreBackend) -> void:
	if backend != null:
		if backend.purchase_result.is_connected(_on_purchase_result):
			backend.purchase_result.disconnect(_on_purchase_result)
		if backend.restored.is_connected(_on_restored):
			backend.restored.disconnect(_on_restored)
	backend = new_backend
	backend.purchase_result.connect(_on_purchase_result)
	backend.restored.connect(_on_restored)
	backend.initialize(config)


func buy(product_id: String) -> void:
	backend.purchase(product_id)


func restore() -> void:
	backend.restore()


func has_product(product_id: String) -> bool:
	return _owned.has(product_id)


func price_text(product_id: String) -> String:
	return backend.price_text(product_id)


func load_entitlements() -> void:
	_owned.clear()
	var cf := ConfigFile.new()
	if cf.load(save_path) != OK:
		return
	for id in cf.get_value("owned", "products", PackedStringArray()):
		_owned[str(id)] = true


func save_entitlements() -> void:
	var cf := ConfigFile.new()
	cf.set_value("owned", "products", PackedStringArray(_owned.keys()))
	var err := cf.save(save_path)
	if err != OK:
		push_error("Purchases: could not save %s (error %d)" % [save_path, err])


func _grant(product_id: String) -> void:
	if _owned.has(product_id):
		return
	_owned[product_id] = true
	save_entitlements()
	entitlements_changed.emit()


func _on_purchase_result(product_id: String, ok: bool, reason: String) -> void:
	if ok and config.non_consumable_products.has(product_id):
		_grant(product_id)
	var analytics := get_node_or_null("/root/Analytics")
	if analytics != null:
		analytics.call("event", &"purchase" if ok else &"purchase_failed", {"product": product_id, "reason": reason})
	purchase_finished.emit(product_id, ok, reason)


func _on_restored(product_ids: PackedStringArray) -> void:
	var changed := false
	for id in product_ids:
		if config.non_consumable_products.has(id) and not _owned.has(id):
			_owned[id] = true
			changed = true
	if changed:
		save_entitlements()
		entitlements_changed.emit()
