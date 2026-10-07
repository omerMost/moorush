# Backlog

Active, actionable work. One bullet = one chunk you could pick up and finish in a session. **Cross items off and move them to `done.md` with the date in the same turn you finish them** — the backlog must reflect current reality.

## Now

_(Mid-flight or top-priority. Usually 1–3 items.)_

- [ ] **Night and zombies in chapters 1–3, with stakes (the user's card N1 "Night + zombies"; redesigned by cards F1–F11, ADR 0018).** The spec is `design/fun-systems.md` §3. Codex builds it and Claude reviews (ADR 0015). S0 system split is complete (ADR 0019); keep `check.sh` green through the following ports. Build in this order, one verified commit each:
  1. **Clock + night:** **S1 clock foundation done** (ADR 0020): 300s chapter clock, phases, 90s night, every-third-night hook, saves/migration and native radial lighting/HUD. **S1 actor follow-up done** (ADR 0021): night-only nearby customer turning, 3x patience, 2/4/6 escalating waves/cap 10, safe A* chase/unstick, sunrise conversion and per-slot actors/scheduler/RNG. Ch1 night 1 is Gary only. Bites now apply S2 health/stock damage. Gary's real weapon purchase/shot acceptance and Grandpa lines follow in step 3/tutorial.
  2. **Hearts + checkpoints: S2 done** (ADR 0022): five hearts, one-second immunity, sunrise refill, named faint/retry card and per-slot dusk/chapter backups with retained preferences/tutorial/wardrobe/stats. Inventory reservations settle once on rollback. Real damage is enabled; economy-only career fixtures remain separate alongside the S3 real-damage normal-night fight bot.
  3. **Weapons: S3 done** (ADR 0023): Milk/Egg/Pie, two upgrades each, independent armory pads, settled carried-product ammo, aim/tap/hold, splash, dash, joke actors and feedback. Headless real shots/reload, dual touch/pointer and normal-night fights plus natural purchase-deadline checks. Boss fights/full armed-career bot remain S4.
  4. **Bosses as chapter exams:** every 3rd night; Cornelius, The Big Cheese and The Sourdough Starter with 3 powers each; `boss_beaten[ch]` plus the gate are needed to leave the chapter. Looks from `characters.md` §7.
  5. **Robbers, by day only** (v9 L950–1022): no hearts, tackle refunds 2×.
  6. The Farmer night taco stand (in d1 cell (1,2) per `design/chapter2.md` §4; build after the ch2 redesign).
  - **Out of ch1–3:** MOO FEVER, BREAKING MOOS events, weather, daily goals (F8); turrets, floodlights, dog, collectors, pockets, hats (*provisional*).
  - **Night performance acceptance:** profile Android beat-spawn/replan/save timing before deploying the completed night port. The S3 headless full-career run is 421.0s wall with parallel validations, versus S2 ~230s and prior ~85–97s; this is CPU-test evidence, not device FPS.
  - **Done check:** the tests in `fun-systems.md` §5 (hearts, checkpoints, night escalation, zombie HP + pathing + unstick, bosses ch1–3, gate requires boss, robbers day-only, a fight bot over 10 seeds, the career bot ch1–3).
- [ ] **Android device playtest:** 0.3.5 installed/launched on the connected POCO on 2026-10-07; daytime Chapters 2–3 and existing phone-save restoration verified locally. Prior build smoothness, sound effects and close/reopen progress confirmed by user. Audible output in 0.1.3 confirmed by user ("yes now i can hear it"). Upgrade glitch resolved on 0.2.1, confirmed by user ("yes"). Remaining: nearest-item pickup/Toss feel retest, Cut-wheel cheese/wooden holder/scenery/customer crop-and-tray route visual retest and Chapters 2–3 phone gameplay/layout feedback, user mute/listening check (setting persistence verified), full layout review, actual lock/wake save/resume acceptance (Home/cold reopen/app-switch handling and local regression pass), and phone soak pending: needs an exclusive connected phone, the user will say when (P2: "Later"). Build 0.3.7+ with the mesh-cache fix and the 60 FPS cap (ADR 0026, P3). Done check: ≥ 58 FPS mean over an uninterrupted 10 min, last 2 min within 10% of minutes 1–2, window p95 ≤ 20 ms (0.3.6 uncapped partial: 108.6 FPS/p95 10.2 ms, thermal 117→97); startup logs are clean of Godot script errors/crashes.
- [ ] **Night A* spikes (measured 2026-10-07 by `test_perf_drift.gd`, MOO_PERF_VERBOSE=1):** a single long successful `find_path` over the 230×72 nav grid costs 10–47 ms in GDScript (mostly public customer routes and zombie chases at night); dusk boundary step 11–16 ms (checkpoint capture). Candidate: the engine's C++ `AStarGrid2D` or a per-frame path budget. Tie-breaks may change routes, so it needs the determinism and route suites; this is Codex's nav area.

- [ ] **The fun core:** the 2-second loop versus the one big world. Decide with the user (`research/fun-additions.md`, item #2 is unbuilt). This stays separate from the port (ADR 0005, G1). S3 adds weapon costs/reload; the tutorial’s former 444.6s gate baseline must be measured with matching weapon-purchase behavior before its ±5% comparison. Measured: the Godot ch1 arrow bot walks 94% of the time (`tutorial.md` §2). Boss nights add ammo-reload trips (`fun-systems.md` §3.6), so this matters more now.
- [ ] **Card after the night port: ch1 boss pacing** (`fun-systems.md` §3.9). The pre-weapons gate was affordable at about 7.4 min; S3 economy bots buy it at about 7.9–9.1 min depending on seed, while the first boss night is at about 13.1 min. Measure with the career bot, then ask the user: wait, a longer ch1, or an earlier ch1 boss.
- [ ] **Playtest question after the night port:** does a boss loss sending you back to the chapter start (up to about 35 min in ch2–3) feel fair? (ADR 0018 consequence.)
- [ ] Replace the placeholder icon mark in `scripts/generate-icons.js` when the brand exists, re-run it
- [ ] **S3 follow-ups from Claude's S0–S3 review (2026-10-07), briefed to Codex with S4:**
  - `test_windowed_weapons` is flaky: 1 of 5 runs FAIL ("Gary shot in 20.0s: false"); the driver never reloads its ammo.
  - Rendered tests fail to save their PNGs on a fresh checkout (no `build/` directory); they should create it.
  - Dusk and sunrise each take one 10–25 ms tick on an M1 Mac (beat-0 spawns run up to 16 A* searches each, plus sunrise departure routes and the checkpoint write). Likely a 75–125 ms hitch on the POCO. Spread the work across frames.
  - The fight bot took **0 hits in 30 first nights**. Measure later nights (5, 8) and report the hearts lost, as input for a difficulty card. No tuning before the card.

## Next
- [ ] **Chapter 2 redesign: the farm grows, plus cheese (cards G1–G6, ADR 0024, spec `design/chapter2.md`).** Codex builds it, Claude reviews. **Order:** after S4 (bosses) and before S6 (the taco stand moves to d1 (1,2)). S4 doesn't wait.
  - **Ch2 drops its corn field, dairy barn, big coop and egg stand.** Its 12 pads grow ch1's field, barn and coop where they stand (a new `grow` effect, cross-district targets like `"m":"0:B"`). The new things are the Cheese press, Cheese shop and the Milk pipeline from the ch1 barn (N2 = A).
  - **Shops appear only when useful:** the bank and vehicle shop are hidden in ch1–3; the armory appears at the first dusk.
  - **The discovery moment:** glide 0.6 s, zoom 1.2, a Grandpa line for 2.0 s, glide back 0.5 s, tap to skip. Only for unlocks, new chapters and the armory, never for ordinary pads (ADR 0009 stays).
  - **Old ch2 saves migrate** (§5: map the pads, refund the rest).
  - **Done check:** `design/chapter2.md` §8.
- [ ] **No repeated production in later chapters** (the user, 2026-10-07: "i want you to add to tasks to change things so there will not be another corn field and cow barn or farm because its making the field to complex to track"). Ch2 is settled by ADR 0024. The rule (one of each type in the whole game, at most two products per chapter, G2) applies when chapters 4–9 are ported: Paper delivery, Print shop and TV studio repeat across chapters 6–9 (prototype L223–285). Needs a card per chapter at port time.
- [ ] **Card before porting the Harbor:** which chapter number becomes the water chapter (G4: its own chapter, fish → sushi, boat, own boss; pearls cut; `design/chapter2.md` §7).
- [ ] **Tutorial: Grandpa's soft opening, chapter 1 B0–B6 (ADR 0016, `design/tutorial.md` §2–§6, §8).** Codex builds, Claude reviews.
  - `tutorial.gd`, the sim's `ev_*` events, the HUD bubble with the portrait placeholder, the moo-babble, and the `tut` save key with old-save migration.
  - Remove the intro toast.
  - Done check: `test_tutorial_bot` (all beats by T ≤ 45 s, first sale ≤ 20 s, no pause), `test_tutorial_order`, `test_tutorial_saves` (resume, old save unchanged, 3-slot isolation, delete), and the chapter-1 bot within ±5% of 444.6 s.
- [ ] **Tutorial: Grandpa's first-time lines and constant commentary for chapters 1–3 (`design/tutorial.md` §5).** Replace the chapter intro toasts.
  - Done check: `test_grandpa_lines`: ≤ 12 words and ≤ 64 chars, cooldowns 20/120/300 s, 10–30 lines per 600 s, no idle nags.
- [ ] **With the night port: Gary the practice zombie (`design/tutorial.md` §7, cards T8/T9).**
  - Gary pathfinds with `findPath`/`NAV`, can't bite, and trips after 60 s.
  - Actor/flag/timeout and conditional affordable-armory guide seam done (ADR 0021). Real Milk squirter purchase/shooting and ≤20s Gary fight acceptance done in S3. Remaining: Grandpa night lines.
  - Look: `design/characters.md` §6 and `docs/design/characters/gary.png` (*provisional*): a scarecrow in a too-small zombie mask who bursts into straw when hit.
  - Done check: `test_tutorial_night`. Also verify a gunless first night is survivable, and raise a card if not.
- [ ] **Grandpa Bovine portrait art** (card D3 A, "A Cow farmer"; `design/characters.md` §2, `docs/design/characters/grandpa.png`): the cow-farmer bust in the 56 px HUD bubble and the 240×150 dialog/newspaper frame, with the mustache wiggle while talking. It replaces the 👴🐮 placeholder. His voice and catchphrases are in §2.


_(Approved, ready to pick up, not started yet.)_

- [ ] Port the rest in verified steps after the slice: chapters 4–9, the harbor, vehicles, robbers, night and zombies (`findPath`/`NAV`), weapons, turrets, collectors, the fun layer (fever, events, bosses, hats, debate, prestige). Also the solid world boundary plus the unstick safety net
- [ ] **Tier `check.sh`** (from the review). The full run took about 4.5 minutes at bed5f84; at d60d3cf (S3) it takes **16.7 min** wall on a clean export, and the chapter-3 bot alone is **391 s** (Claude's S0–S3 review). Each new chapter bot adds more. Briefed to Codex with S4. Proposal: a fast tier under 60 s on every commit, and the full bots before landing on `main`.
- [ ] **Make STATE.md terse again** (from the review). It's a 66-line wall of text, and "At a glance" still calls the HTML "the game". Godot is the game now; the HTML is the spec. Split the Android device evidence out into the playtest notes.
- [ ] **Character pass 1: faces, player, helpers** (user cards D1/D2/D6, 2026-10-07; spec `design/characters.md` §0, §1, §4; images `docs/design/characters/player.png`, `helpers.png`, `support.png`).
  - In `paint.gd`: a parameterised person drawer (`bodyW`/`bodyH`/`legH`/`headR`/`neck`/`lean`) whose defaults match today's body, plus face style C (brows + blush, brow moods, blink).
  - The player outfit ladder for chapters 1–3 (the rest when ported), with draw scale `0.88 + 0.038·i`. The hitbox stays unchanged.
  - Teen-intern helpers with the MOO cap, name tags, and naps after ≥ 4 s idle.
  - Customers and supporting cast get face style C.
  - Cache the variants (ADR 0006/0017). Done check: `check.sh` green, a render test comparing against the PNGs, and Android FPS no worse than 0.3.5.
- [ ] **Character pass 2: zombies, with the night port** (cards Z1/D5/D8; `characters.md` §5, `zombies.png`). Grumpy faces, torn hems, joke props and Granny stats are implemented in ADR 0021. Remaining: parameterized body silhouettes, mood brows on turning customers, full Gary straw/mask/clothes animation and rendered comparison against the design PNGs. Implemented **Zombie Granny** stats: speed ×0.7, +2 hits of the chapter weapon (`fun-systems.md` §3.4), weight ~8. Her scarf hat waits, because hats are out of ch1–3 (ADR 0018, *provisional*). Those stats are *provisional* and need an economy check. Fold this into the Now item "Night and zombies".
- [ ] **Chad Cornwell** (card D4 B; `characters.md` §3, `chad.png`): corn-cob hair, the purple suit and a smug mouth, always drawn at the player's next-chapter scale. He shows up in chapter-intro newspaper cards, as the rival robber kind and as the debate opponent. Build him when the story/newspaper cards and the politics chapters are ported.
- [ ] **Mascot-suit bosses** (card D7 C; `characters.md` §7, `bosses.png`): a foam suit shaped like each chapter's product, with sneakers and a sweaty face hole. On defeat the head pops off to reveal Chad ("...this was Dad's idea."). Build with the boss port. The suit shapes for chapters 3–9 are *provisional*.
- [ ] Give the specialist agents (`.claude/agents/*.md`) a Godot section. They're written for `prototype/index.html` today
- [ ] Define native save import/migration coverage and whether to preserve in-flight goods/helper cargo; current slots are isolated but full old HTML import remains pending.
- [ ] Godot tests for the two cases v9 never tested: the debate timer running out, and MOO FEVER exactly doubling prices (only when those systems come back; they're out of ch1–3 per ADR 0018)
- [ ] **Card: which cut systems return in chapters 4–9?** MOO FEVER, BREAKING MOOS events, weather, goals, turrets, floodlights, dog, collectors, hats (ADR 0018, `fun-systems.md` §3.8). Decide before porting ch4.
- [ ] Decide on the old public artifact link (republish it from the repo or retire it)

## Later / stretch

- [ ] Branch cleanup (the user's call, since deleting branches is theirs): 17 local `codex/*` branches, all already merged into `main`, plus 2 stale Claude worktrees (`.claude/worktrees/infallible-lovelace-*` and `laughing-varahamihira-*`) and their `claude/*` branches.
- [ ] Refine Toss-bin artwork with a visible open mouth/rim; current solid top bar makes the eased shrink/fade read as entering a lid (native rendered QA).

_(Parking lot. Ideas, nice-to-haves, things you'd do if everything else were done.)_

- [ ] Research ideas not yet built (`research/`): one-thumb mode, a lunger zombie, safe zones, the dawn payout screen, secret characters, a cow-breed album, the Grandpa Bovine narrator and the rival Chad Cornwell, share cards, weekly mutators, Cow Cannon fast travel, the Tower of Babel stack
