# Chapter 1 sound and offline font

## Changes
- Codex integrated `chapter1_audio` specialist's bounded, precomputed PCM cues for pick/drop/coin/warn/unlock/gate. Menu sound toggle persists outside game slots; gate suppresses duplicate unlock jingle. ADR 0007 records provisional implementation pending phone listening.
- Bundled unchanged Baloo 2 variable font with OFL/source; weight 800, OS emoji fallback. Signed debug APK now 0.1.2, installed and cold-launched on connected POCO.
- Fixed menu rebuild's deferred child-name collision; audio teardown drains clips in tests. Added async-test timeout guards.
- Backlog now contains phone listening/mute and longer-run performance follow-up. Old 0.1.1 logs show ~97→~43 FPS over ~8 minutes; draw CPU rises, cause not isolated. No thermal diagnosis inferred.

## Checks
- `./check.sh`: GREEN, all five suites (gate bot, unattended counters, slots, phone HUD/font/toggle, audio waveform/rate-limit/mute/settings/polyphony).
- Rendered bundled-font screenshot inspected (`build/polish-font.png`). 300-frame local draw benchmark mean 8.059ms, p95 8.698ms; previous optimized mean 8.315ms.
- Headless Android export signed; `adb install --no-incremental -r`: Success. Cold launch 749ms; current PID 11627 logs show Vulkan/Mali startup with no Godot errors.
- User reported mute/listening issue. Real phone tap wrote sound=false, repeat tap restored true; persisted across APK replacement. Improved poor white-label contrast to dark text and explicit ON/OFF; tested actual pointer routing at both logical phone sizes. Updated check.sh GREEN; re-export/install/cold launch succeeds (597ms), sound preference remains true. Actual audible listening remains unresolved, pending retest. Saves not redesigned; existing slot tests green, prior user close/reopen confirmation retained.
- `git diff --check`: clean. Build logs/screenshots/APK ignored; code and vault changes committed by explicit path.

## Dialogue trace
- User: "continue" after smoother Android gameplay and confirmed close/reopen persistence. Then "Sounds work, mute has a problem", followed by "cant hear anything and no sound off".
- Codex completed Chapter 1 sound/font polish, installed 0.1.2, improved sound control after the reported issue, requested actual phone listening/mute retest, and surfaced longer-run performance evidence. No new gameplay/economy decisions made.
