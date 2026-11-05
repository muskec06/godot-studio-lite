class_name AdsBackend
extends RefCounted
## Ad network interface. This base class is also the mock used in the editor,
## on desktop and in tests: ads "show" instantly and rewarded ads pay out.
##
## A real adapter (for an AdMob plugin, say) extends this class, overrides
## every method, and emits the same signals when the network answers — usually
## a frame or seconds later. Install it with Ads.use_backend(); see /monetize.

## The player finished (earned = true) or skipped/failed (false) a rewarded ad.
signal rewarded_finished(placement: StringName, earned: bool)
signal interstitial_finished(placement: StringName)
## Privacy consent flow done (GDPR/KVKK); false = do not show ads.
signal consent_finished(can_show_ads: bool)

## Tests: make the next rewarded ad fail or be unavailable.
var fail_next: bool = false


func initialize(_config: MonetizationConfig) -> void:
	pass


func request_consent() -> void:
	consent_finished.emit(true)


func is_rewarded_ready(_placement: StringName) -> bool:
	return not fail_next


func show_rewarded(placement: StringName) -> void:
	var earned := not fail_next
	fail_next = false
	rewarded_finished.emit(placement, earned)


func show_interstitial(placement: StringName) -> void:
	interstitial_finished.emit(placement)
