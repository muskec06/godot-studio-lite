---
name: localize
description: Localization — set up the strings CSV and Godot translations, move hard-coded text to keys, fill missing translations (default Turkish + English), check placeholders and fonts, and translate the store listing.
argument-hint: "[setup | extract | translate | check | store]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Edit, Bash(bash tools/l10n.sh*)
---

# /localize — every player-facing word in every language

Languages come from `languages` in `project.yaml` (first = source language,
default `en tr`). Strings live in `game/locale/strings.csv`
(`keys,en,tr`); Godot imports one `.translation` per language. Empty
argument: run `check`, then suggest the next sub-command.

## setup
`bash tools/l10n.sh setup` — creates the CSV and registers the translations
(fallback = source language). Ask whether to add languages first. Plan the
language selector into the settings story (`TranslationServer.set_locale()`,
saved with the other settings; first launch follows the device language).

## extract
1. `bash tools/l10n.sh check` lists hard-coded scene and script text.
2. For each, propose a key: `AREA_THING[_STATE]` — `MENU_PLAY`,
   `LEVEL_COMPLETE_TITLE`, `SHOP_COINS_SMALL`. Show the list; ask.
3. Add the rows to the CSV (source language filled) and change the code to
   `tr("KEY")` or the scene's `text` to the key. Plural or numbered text:
   `tr("LEVEL_N") % n` with `%d` in every language, or `tr_n()` with a
   `?plural` column for languages that need it. Changes to game files go
   through `gdscript-dev` when they are more than a few lines.

## translate
Fill empty cells with the `writer` agent: pass the rows, the glossary from
`docs/narrative/bible.md` if it exists, the tone from `docs/brief.md`, and
these rules — same placeholders as the source; fit the UI (≤ 120% of the
source length for buttons); Turkish: informal "sen" in games unless the brief
says otherwise, dotted/dotless i correct (İ/i, I/ı), Turkish quotes and
punctuation; no machine-translation tone. Show a table of new rows; ask
before writing. Uncertain terms go to the user as questions.

## check
`bash tools/l10n.sh check` and explain each ERROR with its fix. Then:
- **Fonts:** every font the game uses must contain each language's letters
  (Turkish: ç ğ ı İ ö ş ü). Look at a screenshot with the second language
  forced (`internationalization/locale/test="tr"` temporarily, or a debug
  menu) — missing glyphs show as boxes.
- **Overflow:** labels with `autowrap_mode` or `text_overrun_behavior`
  set, or sized for the longest language.

## store
Draft the store title (≤ 30 chars), short description (≤ 80) and full
description (≤ 4000) in every language, written for players searching the
store: what you do in the first 10 seconds, the hook, 3–5 features. Save to
`docs/store/<lang>.md` after the user approves.
