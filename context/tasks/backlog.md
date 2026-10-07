# Backlog

Active, actionable work. One bullet = one chunk you could pick up and finish in a session. **Cross items off and move them to `done.md` with the date in the same turn you finish them** — the backlog must reflect current reality.

## Now

_(Mid-flight or top-priority. Usually 1–3 items.)_

- [ ] **Night and zombies in chapters 1–3, with stakes (the user's card N1 "Night + zombies"; redesigned by cards F1–F11, ADR 0018).** The spec is `design/fun-systems.md` §3. Codex builds it and Claude reviews (ADR 0015). S0 system split is complete (ADR 0019); keep `check.sh` green through the following ports. Build in this order, one verified commit each:
  1. **Clock + night:** **S1 clock foundation done** (ADR 0020): 300s chapter clock, phases, 90s night, every-third-night hook, saves/migration and native radial lighting/HUD. **Remaining:** connect the following night mechanics to its phase/sunrise hooks. Customers turn only at night (`customerLost`/`makeZombie`/`pickType`). Night zombies arrive in 3 beats (2/4/6, +1 per beat per night), with at most 10 alive. Zombies chase with `findPath`/`NAV`, a hard-won rule. Ch1 night 1 is Gary only (`tutorial.md` §7).
  2. **Hearts + checkpoints:** 5 hearts, −1 per bite, refill at sunrise. `dusk` and `chapter_start` checkpoints per slot. A normal-night loss → dusk; a boss-night loss → chapter start. Restores keep settings, wardrobe and `tut.*`.
  3. **Weapons:** Milk squirter (ch1, 100), Egg launcher (ch2), Pie launcher (ch3), plus 2 upgrade pads each. Ammo is the carried stack. Zombie HP per chapter (3/6/12). The joke types, including Zombie Granny.
  4. **Bosses as chapter exams:** every 3rd night; Cornelius, The Big Cheese and The Sourdough Starter with 3 powers each; `boss_beaten[ch]` plus the gate are needed to leave the chapter. Looks from `characters.md` §7.
  5. **Robbers, by day only** (v9 L950–1022): no hearts, tackle refunds 2×.
  6. The Farmer night taco stand.
  - **Out of ch1–3:** MOO FEVER, BREAKING MOOS events, weather, daily goals (F8); turrets, floodlights, dog, collectors, pockets, hats (*provisional*).
  - **Done check:** the tests in `fun-systems.md` §5 (hearts, checkpoints, night escalation, zombie HP + pathing + unstick, bosses ch1–3, gate requires boss, robbers day-only, a fight bot over 10 seeds, the career bot ch1–3).
- [ ] **Android device playtest:** 0.3.5 installed/launched on the connected POCO on 2026-10-07; daytime Chapters 2–3 and existing phone-save restoration verified locally. Prior build smoothness, sound effects and close/reopen progress confirmed by user. Audible output in 0.1.3 confirmed by user ("yes now i can hear it"). Upgrade glitch resolved on 0.2.1, confirmed by user ("yes"). Remaining: nearest-item pickup/Toss feel retest, Cut-wheel cheese/wooden holder/scenery/customer crop-and-tray route visual retest and Chapters 2–3 phone gameplay/layout feedback, user mute/listening check (setting persistence verified), full layout review, actual lock/wake save/resume acceptance (Home/cold reopen/app-switch handling and local regression pass), and an uninterrupted 10-minute performance run with exclusive phone use (coloring app interrupts current captures; 0.3.5 partial captures mean ~57 engine FPS; older 0.1.1 logs drift from ~97 to ~43 FPS across ~8 minutes; cause not isolated); startup logs are clean of Godot script errors/crashes.

- [ ] **The fun core:** the 2-second loop versus the one big world. Decide with the user (`research/fun-additions.md`, item #2 is unbuilt). This stays separate from the port (ADR 0005, G1). Measured: the Godot ch1 arrow bot walks 94% of the time (`tutorial.md` §2). Boss nights add ammo-reload trips (`fun-systems.md` §3.6), so this matters more now.
- [ ] **Card after the night port: ch1 boss pacing** (`fun-systems.md` §3.9). The ch1 gate is affordable at about 7.4 min, but the first boss night is at about 13.1 min. Measure with the career bot, then ask the user: wait, a longer ch1, or an earlier ch1 boss.
- [ ] **Playtest question after the night port:** does a boss loss sending you back to the chapter start (up to about 35 min in ch2–3) feel fair? (ADR 0018 consequence.)
- [ ] Replace the placeholder icon mark in `scripts/generate-icons.js` when the brand exists, re-run it

## Next
- [ ] **Tutorial: Grandpa's soft opening, chapter 1 B0–B6 (ADR 0016, `design/tutorial.md` §2–§6, §8).** Codex builds, Claude reviews.
  - `tutorial.gd`, the sim's `ev_*` events, the HUD bubble with the portrait placeholder, the moo-babble, and the `tut` save key with old-save migration.
  - Remove the intro toast.
  - Done check: `test_tutorial_bot` (all beats by T ≤ 45 s, first sale ≤ 20 s, no pause), `test_tutorial_order`, `test_tutorial_saves` (resume, old save unchanged, 3-slot isolation, delete), and the chapter-1 bot within ±5% of 444.6 s.
- [ ] **Tutorial: Grandpa's first-time lines and constant commentary for chapters 1–3 (`design/tutorial.md` §5).** Replace the chapter intro toasts.
  - Done check: `test_grandpa_lines`: ≤ 12 words and ≤ 64 chars, cooldowns 20/120/300 s, 10–30 lines per 600 s, no idle nags.
- [ ] **With the night port: Gary the practice zombie (`design/tutorial.md` §7, cards T8/T9).**
  - Gary pathfinds with `findPath`/`NAV`, can't bite, and trips after 60 s.
  - Armory-arrow hook when gunless. Night first-time lines.
  - Look: `design/characters.md` §6 and `docs/design/characters/gary.png` (*provisional*): a scarecrow in a too-small zombie mask who bursts into straw when hit.
  - Done check: `test_tutorial_night`. Also verify a gunless first night is survivable, and raise a card if not.
- [ ] **Grandpa Bovine portrait art** (card D3 A, "A Cow farmer"; `design/characters.md` §2, `docs/design/characters/grandpa.png`): the cow-farmer bust in the 56 px HUD bubble and the 240×150 dialog/newspaper frame, with the mustache wiggle while talking. It replaces the 👴🐮 placeholder. His voice and catchphrases are in §2.


_(Approved, ready to pick up, not started yet.)_

- [ ] Port the rest in verified steps after the slice: chapters 4–9, the harbor, vehicles, robbers, night and zombies (`findPath`/`NAV`), weapons, turrets, collectors, the fun layer (fever, events, bosses, hats, debate, prestige). Also the solid world boundary plus the unstick safety net
- [ ] **Tier `check.sh`** (from the review). The full run takes about 4.5 minutes today, and the chapter-3 bot alone is 85–97 s of real time. Each new chapter bot adds more. Proposal: a fast tier under 60 s on every commit, and the full bots before landing on `main`.
- [ ] **Make STATE.md terse again** (from the review). It's a 66-line wall of text, and "At a glance" still calls the HTML "the game". Godot is the game now; the HTML is the spec. Split the Android device evidence out into the playtest notes.
- [ ] **Character pass 1: faces, player, helpers** (user cards D1/D2/D6, 2026-10-07; spec `design/characters.md` §0, §1, §4; images `docs/design/characters/player.png`, `helpers.png`, `support.png`).
  - In `paint.gd`: a parameterised person drawer (`bodyW`/`bodyH`/`legH`/`headR`/`neck`/`lean`) whose defaults match today's body, plus face style C (brows + blush, brow moods, blink).
  - The player outfit ladder for chapters 1–3 (the rest when ported), with draw scale `0.88 + 0.038·i`. The hitbox stays unchanged.
  - Teen-intern helpers with the MOO cap, name tags, and naps after ≥ 4 s idle.
  - Customers and supporting cast get face style C.
  - Cache the variants (ADR 0006/0017). Done check: `check.sh` green, a render test comparing against the PNGs, and Android FPS no worse than 0.3.5.
- [ ] **Character pass 2: zombies, with the night port** (cards Z1/D5/D8; `characters.md` §5, `zombies.png`). The grumpy zombie face and torn hem; joke zombies with their own body shapes and props; mood brows on customers who are turning. Add the new **Zombie Granny** type: speed ×0.7, +2 hits of the chapter weapon (`fun-systems.md` §3.4), weight ~8. Her scarf hat waits, because hats are out of ch1–3 (ADR 0018, *provisional*). Those stats are *provisional* and need an economy check. Fold this into the Now item "Night and zombies".
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
