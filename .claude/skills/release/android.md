# Android release checklist (platform: mobile)

Read by /release when `platform: mobile`. Each line PASS / FAIL / USER.
Claude checks what is in the repo; the user does everything in Play Console
and anything involving the keystore.

## Build
- [ ] Android export templates installed for the exact Godot version.
- [ ] Preset in `game/export_presets.cfg` (user creates it in the editor):
      `package/unique_name` set (e.g. com.studio.game, never changes after
      launch); `version/code` higher than the last upload; `version/name` =
      the release version; `gradle_build/export_format` = AAB for Play;
      `architectures/arm64-v8a` on; `gradle_build/target_sdk` meets Google
      Play's current target API requirement (user checks Play Console).
- [ ] Permissions: only what is used — `permissions/internet` and
      `permissions/access_network_state` for ads/billing, `permissions/vibrate` if
      `App.vibrate` is used. Nothing else.
- [ ] Icons: `launcher_icons/main_192x192`, `adaptive_foreground_432x432`
      (subject inside the centre ~66%), `adaptive_background_432x432`,
      optionally `adaptive_monochrome_432x432`. Generate with /asset, PNG.
- [ ] `screen/edge_to_edge` on only if the UI uses SafeAreaContainer everywhere.
- [ ] Release keystore: created by the user (`keytool`), stored outside the
      repo with a backup; `.gitignore` covers *.keystore/*.jks. Play App
      Signing enabled. **Losing the upload key blocks updates.**
- [ ] Debug builds use test ad IDs; the release build uses real IDs (check
      `MonetizationConfig` and the adapter's `OS.is_debug_build()` branch).

## Device check (user, on a real phone, release build)
- [ ] Installs, launches, first level playable within 30 s.
- [ ] Back button: every screen behaves; main menu asks before quitting.
- [ ] Background → resume keeps progress; force-quit → relaunch keeps progress.
- [ ] Notch / gesture bar: nothing hidden or unreachable.
- [ ] Ads: consent shows once; rewarded pays out; interstitial spacing right.
- [ ] Purchase with a licence tester: remove-ads works, survives reinstall
      via Restore; coin pack grants once.

## Play Console (user)
- [ ] New personal accounts: closed test with ≥ 12 testers for 14 continuous
      days before production access (plan this early).
- [ ] Store listing: title, short and full description (TR + EN), icon
      512×512, feature graphic 1024×500, ≥ 2 phone screenshots.
- [ ] Privacy policy URL (required with ads/billing): what data the ad SDK
      collects, contact address.
- [ ] Data safety form matching the ad and billing SDKs' declared data use.
- [ ] Content rating questionnaire; ads declaration = yes; target audience
      (choosing children triggers Families policy — avoid unless intended).
- [ ] In-app products created with IDs matching `MonetizationConfig`, active.
- [ ] Staged rollout (e.g. 20%) for the first production release.
