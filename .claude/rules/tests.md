---
paths:
  - "game/tests/**"
---

# Test rules (gdUnit4)

- Path mirrors the code: `game/scripts/combat/damage.gd` →
  `game/tests/scripts/combat/test_damage.gd`.
- `extends GdUnitTestSuite`; test functions `func test_<what_it_does>() -> void`.
- One behaviour per test, named for the behaviour, with arrange / act / assert
  visible. `assert_int(x).is_equal(3)` style assertions.
- Every node created in a test is wrapped in `auto_free()`; orphan nodes make
  the run exit 101.
- Deterministic: seed RNGs (`seed(42)` or a `RandomNumberGenerator` with a
  fixed `seed`), no real-time waits longer than needed, no network.
- A test that fails for the right reason before the fix is worth more than
  three that never failed.
- Run with `bash tools/run-tests.sh`. Report its real verdict.
