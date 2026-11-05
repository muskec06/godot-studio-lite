extends GdUnitTestSuite
## Ads facade with the mock backend.

const ADS := preload("res://scripts/monetization/ads.gd")


func _ads(first_level: int = 1, every: int = 2) -> Node:
	var ads: Node = auto_free(ADS.new())
	add_child(ads)
	ads.ads_removed = false
	ads.config.policy.first_interstitial_level = first_level
	ads.config.policy.levels_between_interstitials = every
	ads.config.policy.min_seconds_between_ads = 0.0
	return ads


func test_rewarded_success_is_reported() -> void:
	var ads := _ads()
	var got: Array = []
	ads.rewarded_result.connect(func(p: StringName, earned: bool) -> void: got.append([p, earned]))
	ads.show_rewarded(&"extra_tube")
	assert_array(got).is_equal([[&"extra_tube", true]])


func test_rewarded_failure_grants_nothing() -> void:
	var ads := _ads()
	var got: Array = []
	ads.rewarded_result.connect(func(p: StringName, earned: bool) -> void: got.append([p, earned]))
	ads.backend.fail_next = true
	ads.show_rewarded(&"undo")
	assert_array(got).is_equal([[&"undo", false]])


func test_interstitial_follows_level_spacing() -> void:
	var ads := _ads(1, 2)
	assert_bool(ads.on_level_completed(1)).is_false()
	assert_bool(ads.on_level_completed(2)).is_true()
	assert_bool(ads.on_level_completed(3)).is_false()
	assert_bool(ads.on_level_completed(4)).is_true()


func test_no_interstitial_after_remove_ads() -> void:
	var ads := _ads(1, 1)
	ads.ads_removed = true
	assert_bool(ads.on_level_completed(10)).is_false()


func test_no_ads_without_consent() -> void:
	var ads := _ads(1, 1)
	ads.backend.consent_finished.emit(false)
	assert_bool(ads.can_offer_rewarded(&"extra_tube")).is_false()
	assert_bool(ads.on_level_completed(10)).is_false()
