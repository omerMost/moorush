# Backlog

Active, actionable work. One bullet = one chunk you could pick up and finish in a session. **Cross items off and move them to `done.md` with the date in the same turn you finish them** — the backlog must reflect current reality.

## Now

_(Mid-flight or top-priority. Usually 1–3 items.)_

- [ ] **Android device playtest:** 0.3.5 installed/launched on the connected POCO on 2026-10-07; daytime Chapters 2–3 and existing phone-save restoration verified locally. Prior build smoothness, sound effects and close/reopen progress confirmed by user. Audible output in 0.1.3 confirmed by user ("yes now i can hear it"). Upgrade glitch resolved on 0.2.1, confirmed by user ("yes"). Remaining: nearest-item pickup/Toss feel retest, Cut-wheel cheese/wooden holder/scenery/customer crop-and-tray route visual retest and Chapters 2–3 phone gameplay/layout feedback, user mute/listening check (setting persistence verified), full layout review, actual lock/wake save/resume acceptance (Home/cold reopen/app-switch handling and local regression pass), and an uninterrupted 10-minute performance run with exclusive phone use (coloring app interrupts current captures; 0.3.5 partial captures mean ~57 engine FPS; older 0.1.1 logs drift from ~97 to ~43 FPS across ~8 minutes; cause not isolated); startup logs are clean of Godot script errors/crashes.

- [ ] **The fun core:** the 2-second loop versus the one big world. Decide with the user (`research/fun-additions.md`, item #2 is unbuilt). This stays separate from the port (ADR 0005, G1).
- [ ] Replace the placeholder icon mark in `scripts/generate-icons.js` when the brand exists, re-run it

## Next

- [ ] Port Farmer night taco stand and Night server with the night/combat system; the daytime Chapter 2 step intentionally defers these.

_(Approved, ready to pick up, not started yet.)_

- [ ] Port the rest in verified steps after the slice: chapters 4–9, the harbor, vehicles, robbers, night and zombies (`findPath`/`NAV`), weapons, turrets, collectors, the fun layer (fever, events, bosses, hats, debate, prestige). Also the solid world boundary plus the unstick safety net
- [ ] **Split `godot/scripts/sim.gd` by system before porting night and zombies** (from Claude's review on 2026-10-07, *provisional*). It's 1,614 lines in one file and mirrors the HTML monolith. With 9 chapters, night, zombies and the fun layer it heads toward 5,000+. Proposed split: economy/pads, customers/counters, nav/collision, saves. Keep `check.sh` green across the split.
- [ ] **Tier `check.sh`** (from the review). The full run takes about 4.5 minutes today, and the chapter-3 bot alone is 85–97 s of real time. Each new chapter bot adds more. Proposal: a fast tier under 60 s on every commit, and the full bots before landing on `main`.
- [ ] **Make STATE.md terse again** (from the review). It's a 66-line wall of text, and "At a glance" still calls the HTML "the game". Godot is the game now; the HTML is the spec. Split the Android device evidence out into the playtest notes.
- [ ] **A coordination rule for Claude and Codex.** Both act as the root in the same checkout: Codex landed `bed5f84` in the middle of Claude's review. Decide on one root at a time, or have each AI work in its own worktree.
- [ ] Give the specialist agents (`.claude/agents/*.md`) a Godot section. They're written for `prototype/index.html` today
- [ ] Define native save import/migration coverage and whether to preserve in-flight goods/helper cargo; current slots are isolated but full old HTML import remains pending.
- [ ] Godot tests for the two cases v9 never tested: the debate timer running out, and MOO FEVER exactly doubling prices (once those systems are ported)
- [ ] Decide on the old public artifact link (republish it from the repo or retire it)

## Later / stretch

- [ ] Branch cleanup (the user's call, since deleting branches is theirs): 17 local `codex/*` branches, all already merged into `main`, plus 2 stale Claude worktrees (`.claude/worktrees/infallible-lovelace-*` and `laughing-varahamihira-*`) and their `claude/*` branches.
- [ ] Refine Toss-bin artwork with a visible open mouth/rim; current solid top bar makes the eased shrink/fade read as entering a lid (native rendered QA).

_(Parking lot. Ideas, nice-to-haves, things you'd do if everything else were done.)_

- [ ] Research ideas not yet built (`research/`): one-thumb mode, a lunger zombie, safe zones, the dawn payout screen, secret characters, a cow-breed album, the Grandpa Bovine narrator and the rival Chad Cornwell, share cards, weekly mutators, Cow Cannon fast travel, the Tower of Babel stack
