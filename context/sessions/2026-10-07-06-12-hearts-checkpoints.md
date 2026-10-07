# S2 — Native hearts and checkpoint retries

## Outcome

Added a weak-owned hearts system behind MooSim: five hearts, one-second immunity, actual zombie bite damage, arrived-stock knockoff (Karen six/ordinary three), sunrise refill and a named faint/retry HUD card. Gary is harmless. Faint freezes simulation and survives cold reopening.

Two flat immutable backups live inside each slot JSON. New game/chapter ownership captures the chapter baseline; dusk captures after initializing its wave. Normal loss restores dusk; boss-night loss restores chapter entry and day 1/.08/cn 0. Retry retains tutorial/wardrobe/lifetime stats and separate sound/settings. Checkpoints preserve and settle reserved stock/helper cargo once, while ordinary saves keep their arrived-goods contract and now retain arrived helper cargo. Canonical district/route/belt matching handles reverse purchase order. New helper timers and frozen checkpoint numbers use six decimal places to avoid JSON parser one-ULP drift; live clock/night precision stays intact. Both exact RNG strings are preserved. Completed Gary stays completed; unfinished practice survives chapter restart without duplication.

ADR 0022 records provisional builder choices. Architecture, STATE and backlog are refreshed. Weapons/fight bots remain S3; shipped damage is enabled. Economy regression fixtures explicitly reject damage rather than claiming a surviving unarmed career. No APK/device landing.

## Checks

- `./check.sh`: GREEN, import/boot and 15 headless suites. Latest hearts/determinism changes were also rerun separately after the corresponding refinements.
- `test_hearts`: 37 checks, including actual windup, full immunity second, stock reservations, cold pending loss, wallet/slot isolation, sparse/pending goods, reverse-order helper cargo, boss baseline threat RNG, all-district rollback, finished-upgrade migration and Gary completion retention.
- Final 1,200s seed-23 hash: **3667160503**, money **215**, bought pads **19**, T **1200.0**. New health/backup/helper metadata extends the fingerprint. Removing the S2 fields still matches S1 **1588353440** exactly; the test checks both hashes.
- Economy fixtures: Farm Kid **447.3s**, Farmer **2118.1s**, three-chapter end **4839.1s**, including 300s unattended. Career wall **230.0s**; milk/egg unattended sales **1002/1428**. These match S1 simulation totals; wall time is not phone-performance evidence.
- Rendered `test_windowed_hearts`: eight assertions, visible filled/empty hearts, money clearance, named loss card fitting portrait, cleared movement, suspension guard and real retry callback preserving sound/menu. Inspected `build/hearts-faint.png`.
- Rendered chapter 1 passed at **461.0s** (real-time/windowed stepping); clock and all eight night actor render checks passed.
- `git diff --check`: clean. Initial `git pull --rebase origin main` was blocked by the parallel session's dirty playtest note; fetch verified HEAD and origin/main were equal. That note was left untouched and excluded from staging.
- Sim file lines:

| File | Lines |
| --- | ---: |
| sim.gd | 407 |
| sim/agents.gd | 199 |
| sim/clock.gd | 93 |
| sim/customers.gd | 107 |
| sim/feedback.gd | 61 |
| sim/hearts.gd | 150 |
| sim/items.gd | 227 |
| sim/nav.gd | 361 |
| sim/saves.gd | 215 |
| sim/world.gd | 282 |
| sim/zombies.gd | 297 |

All remain below 450 lines. Nav/A*, solid boundaries, incremental grid updates and item drawing caches are unchanged.

## Dialogue trace

- User: "what next ?"
- Builder proposed S2: five hearts, bite immunity/sunrise healing and per-slot dusk/chapter checkpoints retaining tutorial/settings.
- User: "ok continue"
- Standing user instruction: "You are the builder (ADR 0015). Claude reviews your commit afterwards on a clean `git archive` export."
- User's vault rules require Checks, Dialogue trace, fresh shell timestamp, verified own-path commit and push to main. ADR 0022 choices remain provisional pending Claude review.
