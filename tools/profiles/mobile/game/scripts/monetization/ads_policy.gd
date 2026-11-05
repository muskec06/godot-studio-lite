class_name AdsPolicy
extends Resource
## When an interstitial (full-screen, not opted into) ad may show. Pure rules
## with no engine state, so they are cheap to test and tune. Rewarded ads are
## opt-in and not limited here.
##
## Defaults are deliberately gentle: early levels decide whether a player
## stays, and an ad there costs more players than it earns.

## No interstitial before the player reaches this level number.
@export var first_interstitial_level: int = 5
## Completed levels between two interstitials.
@export var levels_between_interstitials: int = 3
## Minimum seconds since the last full-screen ad of any kind (rewarded too).
@export var min_seconds_between_ads: float = 60.0


func should_show_interstitial(level: int, levels_since_last: int, seconds_since_last_ad: float, ads_removed: bool) -> bool:
	if ads_removed:
		return false
	if level < first_interstitial_level:
		return false
	if levels_since_last < levels_between_interstitials:
		return false
	return seconds_since_last_ad >= min_seconds_between_ads
