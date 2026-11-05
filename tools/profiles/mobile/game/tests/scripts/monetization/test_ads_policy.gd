extends GdUnitTestSuite
## AdsPolicy: when interstitials may show.


func _policy() -> AdsPolicy:
	var p := AdsPolicy.new()
	p.first_interstitial_level = 5
	p.levels_between_interstitials = 3
	p.min_seconds_between_ads = 60.0
	return p


func test_no_interstitial_before_first_level() -> void:
	assert_bool(_policy().should_show_interstitial(4, 10, 999.0, false)).is_false()


func test_interstitial_when_level_count_and_time_allow() -> void:
	assert_bool(_policy().should_show_interstitial(5, 3, 60.0, false)).is_true()


func test_no_interstitial_too_few_levels_since_last() -> void:
	assert_bool(_policy().should_show_interstitial(9, 2, 999.0, false)).is_false()


func test_no_interstitial_too_soon_after_any_ad() -> void:
	assert_bool(_policy().should_show_interstitial(9, 3, 59.9, false)).is_false()


func test_no_interstitial_when_ads_removed() -> void:
	assert_bool(_policy().should_show_interstitial(20, 10, 999.0, true)).is_false()
