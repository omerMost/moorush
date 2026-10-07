# 2026-10-07 — Claude review of Codex S0–S3 (sim split, clock, night actors, hearts, weapons)

**Who:** a Claude session driving Codex (the user's card C2, "Session that drives Codex"). It writes the briefs and reviews each commit; Codex writes all the code (ADR 0015).

## What happened
- Claude wrote the S0 brief. By the time it was posted, Codex had already landed S0–S3: `4dfeed8` (split), `0d61444` (clock), `e09ae1d` (night actors + Gary), `3307b2d` (hearts + checkpoints) and `d60d3cf` (weapons). Claude reviewed all five.
- A peer review session (local_d6450a0b) reported the following, and both points are recorded:
  - N2, "no repeated farm in later chapters", is not approved, so don't brief it. S6 shouldn't build on the duplicated ch2 farm.
  - A Codex commit in this range overwrote an uncommitted Claude backlog edit. Every Codex brief now carries the rule "minimal in-place vault edits, never rewrite backlog/STATE wholesale, `git diff context/` before committing".

## Verdict: PASS, with follow-ups (in the backlog Now, briefed with S4)
1. **Flaky rendered test.** `test_windowed_weapons` failed 1 of 5 runs: Gary wasn't shot in 20 s, because the driver doesn't reload.
2. **Rendered tests on a fresh checkout.** They can't save their PNGs because `build/` doesn't exist. The test still printed PASS.
3. **Frame spikes at dusk and sunrise** (M1 Mac, a scratch probe on seed 23 for nights 2–9):
   - mean tick **0.28 ms**;
   - dusk/beat-0 **10–23 ms**, sunrise **25 ms**.

   Likely causes: `horde_zombie` runs up to 16 A* searches per spawn, sunrise runs departure routes, and dusk writes a checkpoint. On the POCO this may be a 75–125 ms hitch.
4. **First nights have no tension.** The fight bot took 0 hits over 30 first nights (10 seeds × 3 chapters). The later nights still need measuring before a difficulty card.
5. **`check.sh` takes 16.7 min of wall time** (the ch3 bot alone 391 s), up from about 4.5 min. Tiering is now urgent.

Matches the spec:
- beats 2/4/6, +1 per beat per night, cap 10;
- turning only at night within 1,100 px, ×3 patience;
- HP 3/6/12, Karen ×1.5, big ×3, Granny +2 hits;
- weapon stats as in §3.5;
- cure reward ×2, ×3 on a boss night;
- 5 hearts, 1 s i-frames, no wallet loss;
- normal loss → dusk, boss-night loss → chapter start;
- Gary at 40% speed, harmless, 60 s timeout;
- the boss-night rule `cn % 3 == 0`.

The hard-won fixes are kept:
- A* only, with no straight-line fallback (ADR 0021), plus unstick;
- helper demand filtering;
- per-slot checkpoints inside the slot file;
- price-rescale migration;
- S0's moved bodies verified against the original by token comparison.

ADRs 0019–0023 are Codex's provisional calls. Claude accepts them. The career bots run with damage disabled (`MooEconomySim`). That's acceptable until S5, when the armed career bot becomes part of the done check.

## Checks
- **S0 determinism, independently reproduced:** the new test copied into a pre-split `0f1cb8f` export → `1337840505`, money 338, pads 19, T 1200.0. Identical on the `4dfeed8` export.
- **`./check.sh` on a clean `git archive d60d3cf` export: GREEN, 19 suites.**
  - fight 10/10 survival per chapter, 0 hits;
  - determinism `646437788`;
  - ch1 gate 547.8 s;
  - ch2 2,365.2 s;
  - ch3 5,932.6 s;
  - wall 08:12→08:29, with the rendered runs in parallel.
- **Rendered:** `test_windowed_night`, `_hearts` and `_clock` PASS; `_weapons` PASS 4 of 5. Screenshots inspected:
  - `night-actors.png`: the joke types are readable. The Dash button sits at the top-left, but only because the test turns HUD processing off.
  - `weapons-night.png`: the ammo HUD, AIM and Dash are visible.
  - `hearts-faint.png`: "You fainted! Grandpa: Karen got you", with "Retry from dusk".
- Docs only from Claude: this note and the backlog. No game code was touched.

## Dialogue trace
- User: "ok can you create a session over the codex to continue". On card C2: "Session that drives Codex".
- Claude: wrote the S0 brief and offered card X1 (paste, or run `codex exec`). No answer yet.
- Peer session: N2 is unapproved; add the vault-edit rule to every brief. Both acknowledged.
- Next: the S4 brief (S3 follow-ups + check.sh tiers + Gary's tutorial §7 completion).
