# 2026-10-07 — Android performance drift: root cause found and fixed (Claude perf session)

User asked: "create a new session fix the Performance". This is an explicit exception to ADR 0015: Claude may change game code, in its own worktree.

## Diagnosis (numbers)
- **Unbounded growth: ruled out.** A 32-simulated-minute run of a full chapter-3 farm in the real scene: flyers, floaters, toasts, sparks, ground coins, leaving, queues, tray slots, pending ids, Paint caches, objects, nodes and static memory all plateau. Draw rises only while piles fill and the farm grows (scene load), then flattens.
- **Per-call cost is the problem.** Primitive benchmark inside `_draw` (M1, Godot 4.7.2):
  - `draw_rect` / `draw_line`: 0.1 µs;
  - textured item: 0.5 µs;
  - `draw_colored_polygon`, `draw_circle`, `canvas_item_add_triangle_array`: 13–15 µs (Godot 4 builds a GPU buffer for each one);
  - cached `draw_mesh`: 0.1 µs.
  - One person ≈ 210 µs. Sectioned profile of the full farm: fields 4.3 ms, machines 2.2, helpers 2.6, other entities ~3.
- Triangulation ruled out: a cached fan through `canvas_item_add_triangle_array` gave no gain.

## Fix (ADR 0025)
- `Paint.fill_shape`: repeated convex shapes (rounded rects, ellipses, circles in `draw_circle`'s 64-segment layout, person hair and cap) become one cached `ArrayMesh` each, drawn with `draw_mesh` plus a translation.
  - Single-use shapes (pulsing pads) keep the polygon path.
  - Meshes unused for 300 frames are released; hard bounds of 1,024 meshes and 4,096 seen keys.
- `world_view.gd` skips helpers and leaving customers whose feet are more than 140 units outside the padded view. Helpers' `lean` is always 0, so culling changes nothing.
- HUD hearts (new on main) use `Paint.circ`.
- No sim edits. Version 0.3.6 (code 13).
- Tests:
  - `godot/tests/test_perf_drift.gd` (in check.sh): 32 simulated minutes, all 43 pads, nights + `MooFightBot`, a fixed 10-view camera tour, collection plateaus and caps, flat draw/update CPU (±15%), a polygon budget (≤40 per frame; ~8 measured); it reports the phase-boundary step times.
  - `godot/tests/test_windowed_shape_cache.gd`: rendered A/B, old path vs cached, 8 views.

## Checks
- Headless `test_perf_drift`:
  - before the night port: draw 2.12 → 2.14 ms (+1.1%), update +0.3%; 3 parallel reruns −1.3% to +4.3%;
  - after the rebase with nights: draw 1.94 → 2.09 ms (+8.0%), update +9.5%, 6 nights, PASS.
  - Baseline code also passes headless (3.14 → 3.43 ms): the dummy renderer hides the buffer cost, so the polygon budget is the guard.
- Rendered on the M1, same test: draw **13.75 → 2.99 ms** (both flat over 32 minutes).
- Rendered A/B on the new main: mean draw 11.63 → 3.13 ms; 7 of 8 views pixel-identical, 1 view with 1 edge pixel (GPU-side translation rounding; tolerance ≤10). Shape-level A/B: 0 of 1.17 M pixels differ (circles, rounded rects, ellipses, hair, cap, translucent colours, scaled transform).
- **Night spikes (measured, not fixed):**
  - dusk boundary step mean 11.4 / max 16.1 ms (checkpoint capture); other boundaries 0.6–1.0 ms;
  - slowest ordinary step up to 135 ms;
  - instrumented: single long successful `find_path` calls over the 230×72 grid cost 10–47 ms in GDScript (mostly public customer routes and zombie chases). Instrumentation reverted. Backlogged as Codex nav work (*provisional* call not to rewrite A* here).
- **POCO soaks** (`scripts/android_soak.py`, slot 1 idle, sound off):
  - 0.3.5 baseline, **valid** 600 s, 121 windows: mean **58.8 FPS**, window p95 **17.8 ms**, draw **10.7 ms**; minutes 1–2 62.4 → last 2 min 56.3 FPS (**−9.8%**); battery 27.5 → 33.5 °C. Fails "mean ≥ 60".
  - 0.3.6, after cooling to 28.6 °C: **108.6 FPS**, p95 **10.2 ms**, draw **5.15 ms** over 80 windows. Then 3 suspensions and USB loss at ~400 s, so **invalid** as acceptance. Per minute 117 → 97 FPS: uncapped at ~120 Hz it still slows thermally (draw 4.5 → 6.4 ms on a static scene).
  - Install preserved slot 1 and the audio settings byte for byte; backups are in ignored `build/phone-backup-perf/`.
- Done check: (a) PASS; (b) **pending**, needs an uninterrupted 0.3.7+ soak; (c) see check.sh below.
- check.sh GREEN on the rebased branch (19 suites, 17 min 35 s; perf_drift draw +5.9%, raw update +14.8%). The update check was then switched to a 1%-trimmed mean of per-step times (*provisional*): per-minute trimmed update is flat by day (0.70–0.80 ms) with night peaks (0.9–1.2 ms); the raw mean swings ±10% with night/window alignment and rare A* steps. Three reruns +9.6%, +8.6%, −6.5%: PASS. Zombies ≤10, shots ≤1, checkpoints ≤10 KB plateau. Final check.sh after the last rebase: see the landing commit.

## Decisions
- **P1:** user chose "A: before + after (Recommended)".
- **P2, P3:** user answered "Unlocked" both times.
- *Provisional* (mine):
  - fan-mesh caching only for convex shapes;
  - 140-unit people cull margin;
  - not rewriting A* during Codex's split;
  - ADR renumbered to 0025 because main took 0016–0024.
  - update-drift check uses a 1%-trimmed mean (raw mean also printed).
- **P3 (frame cap), user via the review session:** "Cap at 60 FPS (Recommended)". Implemented as Android-only `Engine.max_fps = 60` in `moo.gd` (*provisional* mechanism, over a vsync/display-mode change). The phone done check becomes ≥ 58 FPS mean, last 2 min within 10% of minutes 1–2, p95 ≤ 20 ms.
- **Later P2 answer, via the review session:** "Later". Done check (b) stays open in the backlog until the user frees the phone.

## Dialogue trace
- User: "create a new session fix the Performance".
- Claude, card P1 (phone soak plan) → user: "A: before + after (Recommended)".
- Claude, card P2 (unlock phone) → user: "Unlocked".
- Claude, card P3 (unlock again after cool-down) → user: "Unlocked".
- Review session relayed later answers. P2: "Later" (land the code fix first; the soak waits for the phone). P3: "Cap at 60 FPS (Recommended)".
- Review session (local_d6450a0b) asked for a rebase onto the sim split, check.sh, perf with nights, a dusk/sunrise spike measurement and the soak status. All were sent back to it.

## Notes for next session
- The phone has 0.3.6 built *before* the rebase (no night code, no 60 FPS cap). The next phone build must be 0.3.7 (code 14).
- To stop my own runs I used `pkill -f "godot --headless --path . -s"`, which could also have killed a concurrent Codex test run in the main checkout. None was running afterwards. Next time, kill by PID.
- The windowed A/B warm-up now uses the fight bot and a step count: a night checkpoint restore can rewind `sim.T`, so `while sim.T < X` loops hang.
