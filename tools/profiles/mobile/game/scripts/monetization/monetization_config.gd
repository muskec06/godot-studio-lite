class_name MonetizationConfig
extends Resource
## Ad and product settings. Create res://resources/monetization.tres from this
## script in the editor (FileSystem > New Resource) to edit them in the
## Inspector; without it, these defaults apply.
##
## Ad unit IDs here are the RELEASE ones. Debug builds must use the ad
## network's test IDs (the real adapter handles that): showing or clicking
## your own live ads can get the account banned.

const PATH := "res://resources/monetization.tres"

@export var policy: AdsPolicy

@export_group("Ad units (release)")
@export var android_app_id: String = ""
@export var android_rewarded_unit: String = ""
@export var android_interstitial_unit: String = ""

@export_group("Products")
## Bought once, kept forever, restored on reinstall.
@export var non_consumable_products: PackedStringArray = ["remove_ads"]
## Bought many times; the game grants their content on purchase_finished.
@export var consumable_products: PackedStringArray = ["coins_small", "coins_large"]
@export var remove_ads_product: String = "remove_ads"


static func load_or_default() -> MonetizationConfig:
	var cfg: MonetizationConfig = null
	if ResourceLoader.exists(PATH):
		cfg = load(PATH) as MonetizationConfig
	if cfg == null:
		cfg = MonetizationConfig.new()
	if cfg.policy == null:
		cfg.policy = AdsPolicy.new()
	return cfg
