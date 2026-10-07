# 2026-10-07 — Claude Root Orchestrator reviewed the Godot port (Codex's work)

The user moved development to Codex after the chapter-1 slice and asked Claude to "take a strong look at what now have".

## What exists (main = bed5f84)
- Godot 4.7.2 + GDScript in `godot/`:
  - about 3.2k lines of game code, with `sim.gd` at 1,614 of them;
  - about 1.5k lines of tests.
- Chapters 1–3 (Farm Kid, Farmer, Baker), daytime only, with 34 pads and 3 persistent districts.
- Android 0.3.5 runs on the user's POCO X7: sound, saves, a suspend/resume lifecycle, cached drawing.
- ADRs 0006–0014 and 17 Codex session notes. Every one of those notes has a Checks section and a Dialogue trace.

## Findings, most important first
1. **Performance is the biggest open risk.**
   - 0.1.1 drifted from about 97 FPS down to 43 over 8 minutes.
   - The latest partial run averaged 57 FPS, with a p95 of 18 ms.
   - Not diagnosed yet. Night, zombies and more chapters will add load.
2. **Polish versus fun.** The last ~10 commits are playtest polish: cheese art, trays, pickup and Toss. Meanwhile the user's "THE GAME SHOULD BE FUNNIER" and the 2-second-loop fun core are untouched. The funny systems (night, zombies, fever, events) aren't ported.
3. **`sim.gd` is a monolith.** It heads toward 5k+ lines as more gets ported. *Provisional* proposal: split it by system first.
4. **`check.sh` is slow.** About 4.5 minutes, and it grows with every chapter bot.
5. **STATE.md is hard to read.** It's a dense wall of text and still calls the HTML "the game".
6. **Claude and Codex both work as the root in the same checkout.** Codex landed `bed5f84` while this review was running.
7. **Branch clutter.** 17 merged `codex/*` branches and 2 stale Claude worktrees.

Also checked, and *not* a bug: STATE's "4,632.2 s" supermarket gate and check.sh's "game 4932.2s" are consistent. The second number includes 300 s of unattended selling.

## Checks
- `./check.sh` on clean `git archive` exports, so Codex's live checkout wasn't touched. **GREEN** both times:
  - be0b8db: 12 suites;
  - bed5f84: 13 suites.
  - Farm Kid gate 444.6 s, Farmer gate 1,963.5 s, end of the 3-chapter bot 4,932.2 s.
- Rendered runs `test_windowed_chapter1` (gate at 421.6 s) and `test_windowed_chapter3` PASS. I looked at the screenshots: the farm with its conveyor, the bread and pie ovens, and the slot menu. They match the prototype's look.
- Docs only from Claude: backlog items added and this note. No game code changed.

## Dialogue trace
- User: "i have continue on codex to develop this. take a strong look at what now have"
- Claude: reviewed git history, the vault, the code and the tests, then ran the checks and the rendered bots. Findings above. Two decision cards went to the user: N1 (the next step) and C1 (who leads).
- User, N1: "Night + zombies (Recommended)". It's the new top Now item in the backlog, with the `sim.gd` split first.
- User, C1: "Codex builds, Claude reviews (Recommended)". Recorded as ADR 0015.
