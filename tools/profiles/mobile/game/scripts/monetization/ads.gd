extends Node
## Ads facade (autoload "Ads"). Game code talks only to this node; which ad
## network sits behind it is decided once, in use_backend().
##
##   if Ads.can_offer_rewarded(&"extra_tube"): show the "watch ad" button
##   Ads.show_rewarded(&"extra_tube")   -> rewarded_result(&"extra_tube", earned)
##   Ads.on_level_completed(level)      -> shows an interstitial when AdsPolicy allows
##
## Grant rewards only in a rewarded_result handler with earned == true.

signal rewarded_result(placement: StringName, earned: bool)

var config: MonetizationConfig
var backend: AdsBackend
## True once "remove_ads" is owned: interstitials stop, rewarded ads (opt-in) stay.
var ads_removed: bool = false

var _can_show_ads: bool = true
var _levels_since_interstitial: int = 0
var _last_ad_msec: int = -1


func _ready() -> void:
	config = MonetizationConfig.load_or_default()
	use_backend(AdsBackend.new())
	var purchases := get_node_or_null("/root/Purchases")
	if purchases != null:
		ads_removed = purchases.call("has_product", config.remove_ads_product)
		purchases.connect("entitlements_changed", _on_entitlements_changed)


func use_backend(new_backend: AdsBackend) -> void:
	if backend != null:
		if backend.rewarded_finished.is_connected(_on_rewarded_finished):
			backend.rewarded_finished.disconnect(_on_rewarded_finished)
		if backend.consent_finished.is_connected(_on_consent_finished):
			backend.consent_finished.disconnect(_on_consent_finished)
	backend = new_backend
	backend.rewarded_finished.connect(_on_rewarded_finished)
	backend.consent_finished.connect(_on_consent_finished)
	backend.initialize(config)


## Run the privacy consent flow (required before ads in the EU/UK; KVKK in
## Turkey). Call once at startup, before the first ad.
func request_consent() -> void:
	backend.request_consent()


func can_offer_rewarded(placement: StringName) -> bool:
	return _can_show_ads and backend.is_rewarded_ready(placement)


func show_rewarded(placement: StringName) -> void:
	if not _can_show_ads:
		rewarded_result.emit(placement, false)
		return
	_last_ad_msec = Time.get_ticks_msec()
	backend.show_rewarded(placement)


## Call once per completed level. Returns true when an interstitial was shown.
func on_level_completed(level: int) -> bool:
	_levels_since_interstitial += 1
	if not _can_show_ads:
		return false
	var since := INF if _last_ad_msec < 0 else (Time.get_ticks_msec() - _last_ad_msec) / 1000.0
	if not config.policy.should_show_interstitial(level, _levels_since_interstitial, since, ads_removed):
		return false
	_levels_since_interstitial = 0
	_last_ad_msec = Time.get_ticks_msec()
	_track(&"ad_interstitial", {"placement": "level_complete", "level": level})
	backend.show_interstitial(&"level_complete")
	return true


func _on_rewarded_finished(placement: StringName, earned: bool) -> void:
	_track(&"ad_rewarded", {"placement": String(placement), "earned": earned})
	rewarded_result.emit(placement, earned)


## Reports to the Analytics autoload when the analytics profile is installed.
func _track(name: StringName, params: Dictionary) -> void:
	var analytics := get_node_or_null("/root/Analytics")
	if analytics != null:
		analytics.call("event", name, params)


func _on_consent_finished(can_show_ads: bool) -> void:
	_can_show_ads = can_show_ads


func _on_entitlements_changed() -> void:
	var purchases := get_node_or_null("/root/Purchases")
	if purchases != null:
		ads_removed = purchases.call("has_product", config.remove_ads_product)
