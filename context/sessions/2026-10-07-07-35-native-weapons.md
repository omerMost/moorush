# S3 — Native weapons and carried-product combat

## Outcome

Codex built three armories and nine optional base/upgrade pads (43 total). Milk/Egg/Pie fire arrived carried products through swept projectiles, ±14° assistance, hold/tap and specified splash. Added dash, hit/muzzle flash, interruption/knockback/slow, hit-stop, shake and pitched combo audio. Touch movement/aim IDs are independent; mouse/keyboard and Dash button work. Input releases over controls, partial-stick dash, emulated mouse duplication and Vaulter hit ordering have regressions. QA/economy agents reviewed read-only; neither edited files or committed.

Gun/cooldowns, keyed upgrades and checkpoint ammunition rollback persist; transient shots/input/active dash clear. Historical 10/22/34 economic-pad arrays migrate across armory additions. Player ammo pickup works with full production destinations; helper demand filtering remains. Guide budgeting and provisional final prices meet natural purchase deadlines: Milk 100/200/300, Egg 1200/1800/2400, Pie 4000/4000/5000. Gates remain optional/directly purchasable until S4 adds bosses.

ADR 0023, all three architecture docs, STATE and backlog/done are updated. S4 bosses/full armed-career acceptance, Grandpa dialogue and phone night profiling remain queued. No APK deployment. The parallel session's dirty playtest note was preserved and excluded from staging.

## Checks

- Final `./check.sh`: GREEN, import/boot and all 17 headless suites. `git diff --check`: clean. HEAD and origin/main matched before landing.
- Weapons: **53 checks**, actual purchases/upgrades, delivered three/six-hit cures, splash/multiple cures, ammo reservations, assist/range/cooldown, dash/immunity/collision, checkpoint rollback and old arrays.
- Real-damage fight bot: **10/10 normal-night survival per chapter**, empty initial hands, actual crop harvesting/reload and movement/fire/dash inputs. Bosses are not tested by this fixture.
- Seed-23 natural economy career buys every pad; base weapons at chapter **110.0 / 195.8 / 392.1s** (deadline 486s); last upgrades **394.5 / 1214.2 / 1333.2s** (deadline 1686s). Completes at **5932.6s**, including 300s unattended sales in all six counters; final wall **399.5s**. Economy fixtures explicitly override damage; they do not claim an armed career.
- Seed-1 gate **547.8s**; Chapter-2 fixture **2365.2s**, including unattended verification. Seed-23 1200s snapshot hash **646437788**, money **293**, bought pads **22**. S3 changes price/guide/geometry, so historical fingerprints remain in prior notes.
- Rendered natural Milk purchase/Gary projectile acceptance **0.4s**, five hearts retained. Inspected `build/weapons-night.png`; actual HUD/input/suspension checks pass at both phone sizes.
- First full gate caught a stochastic lifecycle fixture expectation: resumed cow wandering could advance the now-persisted main RNG. The fixture forces that wander, verifies RNG advancement and expects the resumed saved RNG. Full gate rerun passes cold restoration with inventory/wallet/payment checks intact.
- MooSim **434 lines**, eleven weak-owned systems, largest component nav **361**; all simulation files remain below 450 lines.

## Dialogue trace

- User: "continue Next: S3"
- Standing instructions: Codex builds; Claude reviews on a clean export (ADR 0015). Verified own-path commit/push and current vault required (ADRs 0002–0003).
- Builder prices, guide reservation policy and other implementation choices remain **provisional**, recorded in ADR 0023.
