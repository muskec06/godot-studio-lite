---
paths:
  - "docs/**/*.md"
---

# Design document rules

- Short beats complete. The brief is one page; a mechanic spec fits one
  screen; an ADR stays under 60 lines. Longer means it should be split.
- Numbers, states and examples, not adjectives. Every tunable has a name and
  a starting value.
- Each document has one owner skill: `/brief` → brief.md, `/plan` →
  backlog.md, `/adr` → adr/, `/playtest` → playtests/. Edit through them or
  keep their format.
- `docs/backlog.md`: keep the table and the story sections in sync; status
  lives only in the table. Never delete a story; set it to `cut`.
- Write new sections into an existing file with Edit at the right heading,
  not by rewriting the whole file.
