# 2026-10-07 03:52 — Tutorial design (Claude, design session, docs only)

**Agent:** Claude Root Orchestrator, worktree `jovial-pascal-9f6fce`. No game code touched (ADR 0015).

## What happened
- Read STATE, ADRs 0005/0015, `research/fun-additions.md`, the playtest notes and the backlog, plus the teaching code:
  - prototype: `guideTarget`/`guideRaw` L764–800, `stageCard` L2208, the gun toast L633, `newGoals`;
  - Godot: `moo.gd` L68 intro toast, `sim.gd` `guide_raw`/`warn`, `MooBot`.
- Measured a baseline on a clean `git archive` export of `91318e5`, with a scratch script outside the repo, `MooBot` following the arrow on a fresh slot:
  - first corn 0.1 s, feed 2.5 s, milk 6.7 s, stock 9.6 s, sale 15.1 s, coins 20.4 s;
  - Corn conveyor 35.1 s, Bigger arms 61.6 s, Milk runner 259.3 s, gate 444.6 s;
  - moving 94% of the time, longest stand-still 1.5 s.
- Asked cards T1–T10. Wrote `context/design/tutorial.md`:
  - beats B0–B6 with triggers, lines, completion flags and budgets;
  - first-time and commentary line tables;
  - the `tut` save key and old-save migration;
  - Gary's first night;
  - implementation notes and a 6-test headless plan.
- ADR 0016. Four backlog items in Next. STATE gap line and a done entry.
- Coordination: messaged the "Design Moo Rush characters" session (`local_d2defe83…`). The message was queued. I told it Grandpa's look and voice are theirs and the lines/triggers are mine. `characters.md` doesn't exist on origin yet.

## Decisions (*provisional* = mine, not asked)
- The user's: T1–T10, below.
- *Provisional:*
  - old saves count as tutorial-done, get one hello line, and are marked as having seen first-time lines for things they already own;
  - every number in the doc §2/§7: the 45 s opening, the 20 s first sale, ±5% career, cooldowns of 20/120/300 s, 10–30 lines per 600 s, Gary at 40% speed with a 60 s trip timeout;
  - all line texts, and the top-left bubble placement.
- Architecture docs not updated: they describe built code, and nothing was built. Codex updates `system-design.md`/`data-flow.md` when `tutorial.gd` lands.

## Checks
- Baseline bot run: export of `91318e5`, Godot 4.7.2 headless, `measure_first_minutes.gd` in the scratchpad only. Gate at 444.6 s, matching `test_bot_chapter1`'s known ~445 s.
- Line budget: a per-line script over `tutorial.md` §3–§7 checked 57 quoted lines. 0 are over 12 words or 64 chars.
- `check.sh` not run: docs-only change, no game code or tests touched.
- `git fetch` before landing: origin/main had no new commits, no ADR 0016 collision, and no `design/` files.

## Dialogue trace (user's words, verbatim)
- Request: "i want to create a session for the tutorial"
- T1 narrator: "A: Grandpa Bovine (Rec.)"
- T2 strictness: "just part of part 1 soft bets"
- T3 skip/saves: "its a soft one easy to follow so no skip"
- T4 stuck: "B: Arrow only"
- T5 scope: "A: Through first pad (Rec.)"
- T6 after the beats: "C: Constant commentary"
- T7 pause: "A: Never pause (Rec.)"
- T8 first night: "A: Practice zombie (Rec.)"
- T9 Gary without a gun: "C: Arrow to armory"
- T10 quiet toggle: "B: No toggle"

## Next
- Codex: the backlog Next tutorial items (beats first, then commentary, Gary with the night port).
- The character session: Grandpa art and voice into `design/characters.md`. Reconcile the line voice if it differs.
