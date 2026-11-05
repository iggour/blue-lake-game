#!/bin/bash
# Runs every check from AGENTS.md section 8 and writes the results to .artifacts/test_log.txt.
# Double-click in Finder (or run in Terminal). Windowed runs also save screenshots.
cd "$(dirname "$0")/.."
G=/Users/zhangtongyang/Downloads/Godot.app/Contents/MacOS/Godot
[ -x "$G" ] || G="$(mdfind "kMDItemCFBundleIdentifier == 'org.godotengine.godot'" | head -1)/Contents/MacOS/Godot"
LOG=.artifacts/test_log.txt
mkdir -p .artifacts
{
  echo "== $(date) =="
  echo "== parse check =="
  for s in scripts/*.gd; do "$G" --headless --path . --check-only --script "$s"; done 2>&1 | grep -E "SCRIPT ERROR|Parse Error|ERROR" || echo "no script errors"
  echo "== main scene 120 frames =="
  "$G" --headless --path . --quit-after 120 2>&1 | grep -E "SCRIPT ERROR|ERROR" || echo "no runtime errors"
  for t in tests/test_*.gd; do
    echo "== headless $t =="
    "$G" --headless --path . --script "$t" 2>&1 | grep -E "TEST PASS|TEST FAIL|SCRIPT ERROR|ERROR|Invalid" | head -40
  done
  for t in tests/test_s01_enter.gd tests/test_s01_future.gd; do
    echo "== windowed $t =="
    "$G" --path . --script "$t" 2>&1 | grep -E "TEST PASS|TEST FAIL|SCRIPT ERROR|ERROR|Invalid" | head -40
  done
  echo "== done =="
} > "$LOG" 2>&1
echo "Results: $LOG"
