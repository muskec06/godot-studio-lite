---
name: release
description: Release checklist — export presets, version number, a final test run, build export, release notes; stops before uploading anything.
argument-hint: "[version, e.g. 0.3.0] [platform]"
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Glob, Grep, Bash(bash tools/run-tests.sh*), Bash(git status*), Bash(git log*), Bash(git tag --list*)
---

# /release — get a build out

Input: `$ARGUMENTS` — version and platform (Windows / Linux / macOS / Web /
Android). Ask for what is missing.

Report each step PASS / FAIL / SKIPPED. Stop at the first FAIL and say how
to fix it.

**Mobile:** when `platform: mobile` in `project.yaml` and the target is
Android, also work through `android.md` in this skill's folder (read it
section by section) between steps 4 and 6; its Play Console items are the
user's, list them as USER.

1. **Backlog.** No story is `doing`. List `todo` stories that are bugs; ask
   whether any must ship first.
2. **Tests.** `bash tools/run-tests.sh` must exit 0 (or 3 with the user's
   acknowledgement that tests cannot run here).
3. **Version.** Set `config/version="<version>"` under `[application]` in
   `game/project.godot` (ask first; this is the one edit to that file).
4. **Export presets.** `game/export_presets.cfg` must contain a preset for
   the platform. If missing: tell the user to add it in the editor (Project →
   Export → Add…) and to install export templates matching their Godot
   version (Editor → Manage Export Templates). Claude does not write this
   file: it holds signing settings.
5. **Export.** Give the exact command for the user to run (export creates
   files outside the repo and may need signing keys):
   `<godot_bin> --headless --path game --export-release "<preset>" ../builds/<platform>/<file>`
   Web builds also need the host to send COOP/COEP headers if threads are on;
   mention it.
6. **Smoke test.** Ask the user to launch the exported build (not the editor)
   and confirm: it starts, the first playable works, quitting works.
7. **Notes.** Draft player-facing release notes from stories marked `done`
   since the last release (git log / Done dates): what's new, what's fixed,
   known issues. Plain language, no story IDs. Write
   `docs/releases/<version>.md` after the user approves the draft.
8. **AI-generated content.** If `game/assets/ASSETS.md` lists fal.ai
   models: no placeholders remain in shipped scenes; every shipped file under
   `game/assets/` (outside `_raw/` and `_style/`) has a row; the models used
   still show "Commercial use" on their fal.ai pages. Remind the user that
   stores ask about it (Steam's content survey has an AI-generated content
   disclosure; itch.io has a tag) and draft a one-paragraph disclosure from
   ASSETS.md: what was generated (art, sound, music) and that it was reviewed
   and edited by the developer.
9. Suggest `git tag v<version>`; do not tag, push or upload.
