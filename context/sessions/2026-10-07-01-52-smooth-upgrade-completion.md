# Smooth upgrade completion

## Changes
- User reports a visual glitch when payment finishes. Root found universal upgrade camera shake, temporary unlock focus, and synchronous full navigation rebuild (~69–110ms locally; chapter opening ~190ms).
- Removed ordinary upgrade shake/focus while retaining sound/toast/confetti/fog and saves. Refreshes only changed obstacle cells plus 60-unit margin; unchanged geometry preserves helper paths. Full grid still built on world reset. ADR 0009 records provisional visual/performance choice.
- Added full-mask equivalence/payment/camera tests for all 22 upgrades, new slot reset and old farm migration. Read-only chapter2_qa review independently passes, no concerns for current geometry.
- Signed Android 0.2.1 installed and cold-launched without resetting app data. Actual pre-update slot backed up: Farmer, wallet 901, cap 12. Phone visual comparison pending; precise reported visual symptom remains unconfirmed.

## Checks
- `./check.sh`: GREEN, seven suites. Natural Chapter 1 gate 409.0s; bakery gate 1,763.4s, then 300s idle sales. Slot, input/audio and nav equivalence checks pass.
- Isolated local completion after patch ~0.1–20ms for ordinary upgrades; no shake or focus. Timing excludes real save I/O; not an Android frame-time guarantee.
- Signed export, `adb install --no-incremental -r`: Success, launch 557ms. Pending user comparison on an actual phone upgrade.
- `git diff --check`: clean. No prices/production changes; helper route continuity can change deterministic bot pacing.

## Dialogue trace
- User: "when i finish to pay for new upgradge i get a glitch not nice to the eye".
- Root asked shake/camera/flash clarification (unanswered), investigated independently, explained the measured hitch and camera effects, and installed the targeted patch for comparison. No subjective resolution claimed yet.
