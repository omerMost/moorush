#!/usr/bin/env bash
# Import, boot, and run bounded Chapter 1 bots. A process failure is a check failure.
set -euo pipefail
cd "$(dirname "$0")/godot"
GODOT=${GODOT:-/opt/homebrew/bin/godot}
run_check() {
  local label="$1"
  shift
  local out
  if ! out=$("$GODOT" --headless --path . "$@" 2>&1); then
    printf '%s\nFAIL %s (process exited unsuccessfully)\n' "$out" "$label"
    return 1
  fi
  if printf '%s\n' "$out" | grep -qE 'SCRIPT ERROR|Parse Error|^ERROR|^FAIL'; then
    printf '%s\nFAIL %s\n' "$out" "$label"
    return 1
  fi
  if [[ "$label" == test_* ]]; then
    printf '%s\n' "$out" | grep -E '^(PASS|FAIL)|^  ' || true
    printf '%s\n' "$out" | grep -q '^PASS' || return 1
  else
    printf 'PASS %s\n' "$label"
  fi
}
run_check import --import
run_check boot --quit-after 120
for t in test_bot_chapter1 test_bot_chapter2 test_bot_chapter3 test_counters_unattended test_save_slots test_touch_hud test_audio test_upgrade_navigation test_customer_routes test_item_transfers; do
  run_check "$t" -s "res://tests/$t.gd"
done
printf 'check.sh: GREEN\n'
