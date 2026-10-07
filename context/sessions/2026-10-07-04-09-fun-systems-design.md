# 2026-10-07 — Fun systems design session (cards F1–F11) → zombies with stakes

**Who:** Claude (Root Orchestrator, design and discussion session, worktree `jolly-euler-305ae9`). Docs only. No game code (ADR 0015).

## What happened
- **Read** v9's fun code (L950–1540, plus GUNS/CUTS L332, the queue L641–672) and explained each system with its numbers.
- **Findings:**
  - one resource does three jobs (the carried stack);
  - cures pay 2× a sale, which pays you to be slow;
  - far-away customers leave silently;
  - night is one flat 90 s;
  - there are six ways to lose coins;
  - about 12 systems hit you in the first 13 minutes of ch1, and nothing can make you lose.
- **Round 1 cards** (night shape, cure pay, chasers, losses): the user picked "[No preference]" on all four and asked to discuss first.
- **A walk-through** of every system in three groups (core, helpers, noise). Then Claude's Z1–Z5 ideas for more interesting zombies, plus a cut list. **The user rejected Z1–Z5** and gave their own direction: you can lose, a chapter restart, weapons to buy, tough zombies, and bosses with powers.
- **Cards F1–F11** turned that into a spec.
- **Input from the review session (local_d6450a0b):** the Godot ch1 arrow bot walks 94% of the time (`tutorial.md` §2). Gary and the armory arrow from the tutorial fit the design.
- **Wrote:**
  - `design/fun-systems.md` (decisions, a numeric spec, Codex's test list, a condensed v9 reference);
  - ADR 0018;
  - the backlog: the Now item "Night and zombies" rewritten as 6 build steps; new items for the ch1 pacing card, the boss-restart playtest question and the "which cut systems return in ch4–9" card; the Zombie Granny line adjusted.
- STATE.md was not touched. It's Codex's in-progress file (ADR 0015); the snapshot change is in ADR 0018 and the backlog.

## Decisions
- User's cards: F1 hearts; F2 chapter start; F3 boss as the exam; F4 a weapon per chapter; F5 a fixed night; F6 every night harder (a normal loss → dusk); F7 the carried stack; F8 keep only robbers; F9 every 3rd night; F10 boss + gate; F11 robbers by day.
- *Provisional* (Claude):
  - 5 hearts; customers turn only at night;
  - bites cost no wallet;
  - zombie HP 3/6/12 (3 hits from the chapter weapon); boss HP 40/120/320 and all boss powers;
  - the Pie launcher for ch3; the beat sizes 2/4/6 and the 10-alive cap;
  - turrets, lights, dog, collectors and hats out of ch1–3;
  - the cure reward stays v9's; the Influencer flash is toned down.

## Checks
- Docs only. No code changed, so `check.sh` wasn't needed.
- Verified the v9 numbers by reading the code: `turnRate`, `decorateCust`, `ZTYPES`, `GUNS`, `CUTS`, `updBoss`, `EVENTS`, `newGoals`, `pocketCap`/`payInto`, `retireGain`.
- Checked consistency with `tutorial.md` §7 (Gary, T9 arrow, squirter at 100) and `characters.md` §5/§7 (Zombie Granny, mascot-suit bosses).
- Rebased on origin/main (`d752d2d`) before writing. ADR number 0018 is free.

## Dialogue trace (user's words, verbatim)
- Request: "i want you to create a new session for the fun part i want to discuss the logic of the fun parts what do they cause"
- Round 1: "[No preference]" ×4
- "i want to first discuss on all the fun part , i think some of them are just too much that the game loses it pointing . lets talk about what happens in each of the parts and the spaciel fun part"
- "i feel like the zombie part could get more intresting but the game is soo full of staff that its just there"
- "i did not like your ideas there are also boss . i think you need to be able to loose and start the chapter from your saving after ,  maybe you need to buy a weapon that will help you defet the zombies and the boss that have extended life and are hard to kill and the boss should actully have powers"
- F1 "Your hearts run out (Recommended)"; F2 "Start of the chapter"; F3 "Chapter's final exam (Recommended)"; F4 "New weapon each chapter (Recommended)"
- F5 "Fixed: every Nth night"; F6 "Yes, getting harder (Recommended)"; F7 "Your carried stack (v9, Recommended)"; F8 "Robbers"
- F9 "Every 3rd night (Recommended)"; F10 "Beat boss AND buy the gate (Recommended)"; F11 "Daytime only (Recommended)"

## Next
- Codex: the Now item "Night and zombies, with stakes", in 6 steps. Claude reviews.
- After the port: the ch1 pacing card, and the boss-restart fairness question in the playtest.
