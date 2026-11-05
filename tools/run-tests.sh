#!/bin/bash
# Run the gdUnit4 suite in game/tests headlessly and print a one-line verdict
# plus the failing lines. Usage: bash tools/run-tests.sh [res://tests/sub/dir]
# Exit: 0 pass · 1 failures or errors · 3 cannot run (missing Godot/gdUnit4/import)
set -u
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../.claude/hooks/lib.sh"
cd "$ROOT" || exit 3

fw="$(cfg test_framework gdunit4)"
[ "$fw" = "none" ] && { echo "tests: test_framework is none, skipped"; exit 0; }
gb="$(godot_bin)"
[ -n "$gb" ] || { echo "tests: cannot run, Godot executable not found (godot_bin in project.yaml)"; exit 3; }
[ -d game/addons/gdUnit4 ] || { echo "tests: cannot run, gdUnit4 missing (bash tools/install-gdunit4.sh)"; exit 3; }
[ -d game/.godot ] || { echo "tests: cannot run, project not imported (bash tools/setup-godot.sh)"; exit 3; }

target="${1:-res://tests}"
log="${TMPDIR:-/tmp}/gsl-tests.log"
( cd game && "$gb" --headless -s -d --remote-debug tcp://127.0.0.1:0 \
    res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a "$target" --ignoreHeadlessMode ) >"$log" 2>&1
code=$?

case $code in
  0)   if grep -q 'No test cases found' "$log"; then echo "tests: none found under $target"; else echo "tests: PASS"; fi; exit 0 ;;
  100) echo "tests: FAIL" ;;
  101) echo "tests: PASS with warnings (orphan nodes: free what you create in tests)"; grep -iE 'orphan' "$log" | head -n 10; exit 0 ;;
  105) echo "tests: a test script does not parse" ;;
  1)   echo "tests: runner did not start (import the project: bash tools/setup-godot.sh)"; tail -n 15 "$log"; exit 3 ;;
  *)   echo "tests: runner exited $code" ;;
esac
grep -E 'FAILED|Error|ERROR|expected|but was|PARSE' "$log" | grep -v 'remote' | head -n 30
echo "(full log: $log)"
exit 1
