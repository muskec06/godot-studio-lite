class_name StoreBackend
extends RefCounted
## App store interface. This base class is also the mock used in the editor,
## on desktop and in tests: every purchase succeeds instantly unless fail_next.
##
## A real adapter (Google Play Billing, say) extends this, overrides every
## method and emits the same signals when the store answers. It must also
## acknowledge/consume purchases as the store requires (Google Play refunds
## purchases not acknowledged within 3 days). Install it with
## Purchases.use_backend(); see /monetize.

signal purchase_result(product_id: String, ok: bool, reason: String)
## Products the store says this account owns (non-consumables).
signal restored(product_ids: PackedStringArray)

## Tests: make the next purchase fail.
var fail_next: bool = false

var _owned: PackedStringArray = []


func initialize(_config: MonetizationConfig) -> void:
	pass


func purchase(product_id: String) -> void:
	if fail_next:
		fail_next = false
		purchase_result.emit(product_id, false, "mock failure")
		return
	if not _owned.has(product_id):
		_owned.append(product_id)
	purchase_result.emit(product_id, true, "")


func restore() -> void:
	restored.emit(_owned)


## Localised price string from the store ("₺49,99"). The mock has no prices.
func price_text(_product_id: String) -> String:
	return ""
