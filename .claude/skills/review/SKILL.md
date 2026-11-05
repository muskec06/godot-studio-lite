---
name: review
description: Independent code review of the story in progress (or named files) by the read-only reviewer agent, in its own context.
argument-hint: "[S-NNN or file paths]"
disable-model-invocation: true
context: fork
agent: reviewer
background: false
---

Review the change described below and reply in your VERDICT format.

Target: $ARGUMENTS

If the target is empty or a story ID: open `docs/backlog.md`, take the named
story (or the one with status `doing`), read its section for the acceptance
criteria and file list, and review those files. Use `git diff` and
`git status` when this is a git repository to see exactly what changed.

If the target is file paths: review those files against the project rules
(`.claude/rules/`) and Godot 4.7 correctness.

Read `mode` in `project.yaml`: in `project` mode a story whose section names
a test must have that test, and missing tests are a Must fix.
