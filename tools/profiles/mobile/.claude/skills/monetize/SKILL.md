---
name: monetize
description: Mobile monetization — choose ad and store providers, install their Godot plugins, write real adapters behind the Ads and Purchases autoloads, and plan the rewarded-ad, interstitial, remove-ads and consent stories.
argument-hint: "[ads | iap | both]"
disable-model-invocation: true
---

# /monetize — real ads and purchases behind the existing facades

The `Ads` and `Purchases` autoloads already work with mock backends (editor,
desktop, tests). This command replaces the mocks with real providers without
touching game code.

1. **Check.** `platform: mobile` in `project.yaml` and the files under
   `game/scripts/monetization/` exist (else `bash tools/apply-profile.sh
   mobile`). Recommend `mode: project` from here on: monetization bugs cost
   money and reviews. Ask before switching.

2. **Decide providers** with `/adr` (architect), giving it these as current
   candidates to verify, not as settled facts:
   - Ads: an AdMob plugin for Godot 4 (e.g. Poing Studios' "AdMob" in the
     Asset Store, MIT, Android + iOS, Godot 4.2+). Check its last release date,
     Godot 4.7 support, rewarded + interstitial support and UMP consent support.
   - Android purchases: Godot's first-party GodotGooglePlayBilling plugin
     (Godot 4.2+; docs: tutorials/platform/android/android_in_app_purchases).
   - iOS later, as its own decision.
   Both need a Gradle build (Project → Install Android Build Template).

3. **Install** — the user does it, Claude guides: in the editor, Asset Store
   (or the plugin's GitHub release), install, enable under Project Settings →
   Plugins, enable `gradle_build/use_gradle_build` in the Android preset.
   Never download plugin code with a script.

4. **Learn the real API** before writing a line: read the installed plugin's
   README / example under `game/addons/<plugin>/` (Grep for signal and method
   names) and its docs page. Ask `godot-docs` for engine-side questions. Note
   the verified API in the ADR's Consequences.

5. **Plan** with `/plan monetization`, these stories (adapt names):
   - AdMob adapter: `extends AdsBackend`, test unit IDs in debug builds
     (`OS.is_debug_build()`), release IDs from `MonetizationConfig`; emits the
     base class signals; installed with `Ads.use_backend()` on mobile only
     (`OS.has_feature("android")`).
   - Consent: UMP flow at first launch before any ad request; "Privacy
     options" button in settings when the region requires it.
   - Billing adapter: `extends StoreBackend`, query products → localized
     prices, purchase, **acknowledge** non-consumables / **consume**
     consumables, restore on startup; installed with `Purchases.use_backend()`.
   - Game hooks: rewarded buttons (only when `Ads.can_offer_rewarded`),
     `Ads.on_level_completed(level)` after the win screen, "Remove ads" and
     "Restore purchases" in settings, coin packs granting on
     `purchase_finished(id, true, _)`.
   - Store setup checklist (user): AdMob app + ad units, Play Console products
     with the same IDs as `MonetizationConfig`, licence testers.
   Each story keeps the facade tests green; adapters get a smoke test on a
   real device (test ads must show, a licence-tester purchase must complete).

6. **Policy defaults** live in `AdsPolicy` (no interstitial before level 5,
   every 3 levels, 60 s apart). Tune them after playtests, not before.

7. Report: ADR path, plugins installed or pending, stories added, next
   command, ≤ 10 lines.
