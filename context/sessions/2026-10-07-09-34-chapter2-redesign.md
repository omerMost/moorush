# 2026-10-07 — Chapter 2 redesign, map tidy-up, discovery moment (cards G1–G6)

**Who:** Claude (the fun-systems design session, worktree `jolly-euler-305ae9`), on a hand-off from the review session local_d6450a0b. Docs only, no game code (ADR 0015).

## What happened
- **The review session relayed:** "i want to change part 2 of the game tell the fun systems session". Claude asked what "part 2" meant (chapter 2, part 2 of the night design, or something else).
- **The user described it:** remove the repeated ch2, make ch1's fields bigger, organize the map, add a discovery animation with Grandpa, too many field types, and the water needs organizing.
- **Checked** Godot's `data.gd` (ch2's 4 duplicated modules, 12 pads, ch1's 3 shop cells, the weapon costs) and v9's `HARBOR` and `DPOS`. Read `tutorial.md` §5 for the existing Grandpa lines.
- **Cards G1–G6** (§Dialogue). This also settles the backlog's card **N2 = A**: the ch1 barn feeds the cheese press.
- **Wrote:**
  - `design/chapter2.md`: rules, the ch1/ch2 block layouts, 12 ch2 pads, a save migration, the discovery-moment spec and its lines, the water, and the tests;
  - ADR 0024;
  - the backlog: a new build item "Chapter 2 redesign" placed after S4 and before S6; the "No repeated farm" item narrowed to chapters 4–9; a Harbor chapter card; S6's taco stand location.
- STATE.md isn't touched (Codex's file, ADR 0015).

## Decisions
- User: G1 the ch1 farm grows plus cheese; G2 up to two products per chapter; G3 glide, zoom and Grandpa; G4 the Harbor as its own later chapter; G5 keep the 3×3 grid; G6 shops appear only when useful.
- *Provisional* (Claude):
  - the ch2 block layout and the 12 pads with their base costs;
  - the `grow` effect (plots ×1.5, regrow ×0.8);
  - the migration mapping and refunds;
  - the reveal timings (0.6 / 2.0 / 0.5 s, zoom 1.2), and no camera move at night with zombies alive;
  - the Grandpa unlock lines, which replace `f_unlock`;
  - pearls and jewelry cut from the Harbor.
- **S4 (bosses) doesn't need to wait:** The Big Cheese stays in ch2, and Cornelius eats ch1's corn. The ch2 redesign lands after S4 and before S6.

## Checks
- Docs only, so `check.sh` wasn't needed.
- Verified the facts against `godot/scripts/data.gd` (`stage0`–`stage2`, `WEAPONS` costs) and the prototype's `HARBOR`/`DPOS` (L347–376).
- Consistent with:
  - ADR 0009 (no focus on ordinary pads);
  - ADR 0023 (the Egg launcher's deadlines, re-measured);
  - `tutorial.md` §5 (`f_ch2`/`f_ch3` kept, `f_unlock` replaced) and §7 (the armory and Gary);
  - `fun-systems.md` (The Big Cheese, the taco stand).
- Rebased on origin/main (`eeb9796`). ADR 0024 is free.

## Dialogue trace (user's words, verbatim)
- Via the review session: "i want to change part 2 of the game tell the fun systems session"
- "i want to remove most of chapter 2 , its mostly repeted chapter 1 insted of reopening corn cow and chiken field make in chepter 2 the filed fro, chepter 1 bigger . and i want to organize the map, and also i want to add animation when new field is discover move the camera to zoom there and tell the tutorial grandpa be there and say whets new . there are too many fields type at the moment and it remove the game intrest from the fun part , also the water part are cool but also needs to orgenize"
- G1 "Ch1 farm grows + cheese (Recommended)"; G2 "Up to two per chapter"; G3 "Glide + zoom + Grandpa (Recommended)"; G4 "Its own chapter, later (Recommended)"
- G5 "Keep the 3×3 grid"; G6 "Appear only when useful (Recommended)"
