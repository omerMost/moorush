# Run: chapters 1–3 complete (goal mode, ADR 0025)

**North star:** Godot chapters 1–3 play as designed, from the first tap to the supermarket gate:
- night and zombies with stakes;
- a boss exam per chapter;
- the redesigned chapter 2;
- Grandpa's tutorial;
- the new cast.

All of it is proven by bots in `check.sh`, with the tester's PASS on every step.

**Builder:** the "Build Moo Rush chapters 1–3 in goal mode" session. **Tester:** the "Fix Moo Rush Android performance drift" session. **Branch:** `run/chapters-1-3`.

## Steps (in order; each one is a commit, a tester PASS, then landed on main)

| # | Step | Spec | Done check (minimum) |
|---|---|---|---|
| S4a | Review follow-ups: make `test_windowed_weapons` deterministic (5/5), rendered tests create `build/`, measure difficulty (hits taken per night), **tier `check.sh`** (`check.sh fast` < 90 s, `check.sh full` before landing) | backlog Now, review `2026-10-07-08-29` | 5 of 5 weapons runs pass, fast tier < 90 s, full tier GREEN |
| S4b | Ch1 boss Cornelius (3 telegraphed powers), boss every 3rd night, ch1 needs `boss_beaten` + the gate | fun-systems §3, characters §7 | `test_boss_ch1`, `test_gate_requires_boss` (ch1), fight bot over 10 seeds |
| S5 | Chapter 2 redesign: the ch1 farm grows, Milk pipeline, Cheese, migration with map/refund, the discovery moment (glide + zoom + Grandpa), shops only when useful | chapter2.md §2–§8 | every test in chapter2.md §8, career bot GREEN |
| S6 | Ch2 boss The Big Cheese and ch3 boss The Sourdough Starter; boss-required exits in ch2–3 | fun-systems §3 | boss tests ch2/ch3, armed career bot to the supermarket gate |
| S7 | Robbers by day only (v9 L950–1022), tackle refund 2× | fun-systems §3 | `test_robbers_day_only` |
| S8 | Night taco stand (ch2) | fun-systems §3 | a counter sells at night only |
| S9 | Tutorial: B0–B6 soft beats, Grandpa commentary, Gary's polish, the armory arrow | tutorial.md §2–§8 | `test_tutorial_bot` (≤ 45 s, first sale ≤ 20 s), `test_tutorial_order`, `test_tutorial_saves`, `test_grandpa_lines`, `test_tutorial_night` |
| S10 | Character pass 1 (faces, a player who grows up, helpers) and pass 2 (zombies, Chad, mascot bosses) | characters.md | rendered screenshots vs `docs/design/characters/*.png`; HUD/touch tests GREEN |
| S11 | Performance re-check of the full ch1–3 game with night (the tester's area); a phone soak only when the user frees the phone | ADR on cached meshes, the 60 FPS cap | `test_perf_drift` GREEN with night active |

## Rules
- Hard-won fixes to protect:
  - `findPath`/`NAV` pathfinding;
  - the solid boundary plus unstick;
  - helpers picking up only what's needed;
  - isolated save slots;
  - old saves keeping finished upgrades.
- Edit vault files minimally and in place. Session note per step (Checks + Dialogue trace).
- Blocked on the user → write a decision card into the morning page and backlog, then skip to the next independent step.
- Stop when S11 passes, or when every remaining step is blocked. Then write `context/morning-page-<date>.md`.
