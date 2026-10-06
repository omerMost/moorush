# Android smoothness candidate 0.1.1

**Agent:** Codex root; performance-review subagent provided read-only audit.

## What changed
- Recorded POCO playtest feedback verbatim. Compared port input/movement/rendering with frozen HTML.
- Corrected HUD input order (priority -10), removing an extra frame before movement receives fresh joystick input.
- Cached the original opaque procedural item drawings into four 192×192 textures. Translucency/headless/warmup keep original drawing; no art/economy/speed/renderer redesign.
- Cached bounded curve geometry/text measurements/colors and batched grass lines. ADR 0006 records this provisional implementation choice.
- Added debug-only Android five-second frame windows and an explicit deterministic desktop draw profiler. App-background gaps excluded from samples. Bumped APK/menu to 0.1.1, preserving package and saves.
- Updated architecture, STATE, playtest note and backlog. User's smoothness confirmation and phone frame samples remain pending.

## Checks
- Local rendered benchmark, 300 frames after deterministic 240s demo: world draw CPU mean 21.083→8.315ms (60.6% reduction), p95 21.980→8.929ms. Not Android FPS or browser comparison.
- Rendered cache-path screenshot inspected at 240s; visuals retained.
- Headless checks green: gate at 430.9s, both counters sell unattended, full persisted saves, phone touch/menu and input process ordering.
- Signed Android 0.1.1 APK installed; native cold launch succeeds (574ms). Final menu/debug-sampling update is included in the same 0.1.1 candidate.
- No five-second gameplay frame window captured yet: app awaits user Play. No claim that Android smoothness is resolved.

## Dialogue trace
- User: "the game feels less smooth as it was on the html"
- User clarification: "its cind of lagy like its on 30 fps working nice"
- Asked user to play 0.1.1 for ~20 seconds and compare; pending.
