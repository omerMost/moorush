#!/usr/bin/env bash
# Green = the Godot chapter-1 slice imports, boots, and passes the headless bots (ADR 0002/0005).
set -euo pipefail
cd "$(dirname "$0")/godot"
GODOT=${GODOT:-/opt/homebrew/bin/godot}
fail=0
out=$("$GODOT" --headless --path . --import 2>&1) || true
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error"; then echo "$out"; echo "FAIL import"; exit 1; fi
out=$("$GODOT" --headless --path . --quit-after 120 2>&1) || true
if echo "$out" | grep -qE "SCRIPT ERROR|Parse Error|^ERROR"; then echo "$out"; echo "FAIL boot"; exit 1; fi
echo "PASS boot"
for t in test_bot_chapter1 test_counters_unattended test_save_slots; do
  out=$("$GODOT" --headless --path . -s "res://tests/$t.gd" 2>&1) || true
  echo "$out" | grep -E "^(PASS|FAIL)|^  " || true
  echo "$out" | grep -q "^PASS" || fail=1
  echo "$out" | grep -qE "SCRIPT ERROR" && fail=1
done
[ $fail = 0 ] && echo "check.sh: GREEN" || { echo "check.sh: RED"; exit 1; }
