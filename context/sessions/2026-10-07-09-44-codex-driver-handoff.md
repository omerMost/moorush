# 2026-10-07 — Codex-driver session stands down (handoff of the unsent S4a/S4b brief)

**Who:** the Claude session that drove Codex (card C2). The user switched to a Claude builder in goal mode (ADR 0025, which supersedes 0015). This session sends no more Codex briefs.

## The open brief, for the goal-mode builder
It was written and shown to the user but never confirmed as pasted into Codex. Codex landed nothing after `d60d3cf`.

**S4a: the S3 review follow-ups** (evidence in `2026-10-07-08-29-claude-review-codex-s0-s3.md`):
1. `test_windowed_weapons` is flaky: 1 of 5 runs fails because the driver never reloads. Target: 10 of 10.
2. Every `test_windowed_*` creates `build/` and FAILS when `save_png` fails. Today it prints an ERROR and still PASSes.
3. Dusk and sunrise spikes on an M1: the beat-0 tick takes 10–23 ms and sunrise 25 ms, against a mean of 0.28 ms.
   - Spread these across frames: `horde_zombie`'s up to 16 `find_path` calls per spawn, the sunrise departure routes, and the dusk checkpoint write.
   - Assert that no night tick exceeds 6 ms on desktop for nights 2–9, seed 23.
   - Keep A* only.
4. Measure only, no tuning: `test_fight` on nights 5 and 8, with the base weapon and with both upgrades (survival, hearts lost, peak alive). First nights cost 0 hits over 30 runs today.
5. Tier `check.sh`. It takes 16.7 min of wall time today, the ch3 bot alone 391 s.
   - A fast tier under 90 s: the feature suites, the ch1 bot and determinism.
   - `--full` before landing on main.

**S4b: ch1 Cornelius plus the ch1 gate-requires-boss rule** (`fun-systems.md` §3.6/§5, `characters.md` §7):
- **Spawn and chase:** he spawns 6 s after a `cn % 3 == 0` dusk, within 520 px, with HP 40. He chases with NAV/A* and unstick. Contact costs −1 heart, and he counts toward the cap of 10.
- **Powers** (each with a warning ≥ 0.8 s, each dodgeable with the dash):
  - the kernel ring: every 4 s, 10 kernels at 260 px/s;
  - the burrow: every 12 s, a mound r 50 follows for 2 s, locks for 1 s, then he erupts;
  - the corn snack: within 60 px of a ripe crop, +2 HP per second.
- **Sunrise:** if he's alive, he flees with no penalty.
- **Win:**
  - the reward `max(500, bp×250)`;
  - a `boss_beaten[0]` flag kept per slot;
  - the defeat beat: the head pops off and Chad says "...this was Dad's idea."
- **The ch1 gate** opens ch2 only when it's bought AND `boss_beaten[0]`. A HUD shows "Boss in N nights". Old saves already past ch1 migrate as beaten.
- **Tests:**
  - `test_boss_ch1` and `test_gate_requires_boss`;
  - a fight bot over 10 seeds: fully upgraded ≤ 75 s; base weapon ≤ 90 s with ≥ 1 heart in 7 of 10; no gun can't win;
  - an armed ch1 career bot that reports the wait between buying the gate and beating the boss. That's the input for the ch1 pacing card. Don't change the pacing alone.
- **Don't hard-code ch2's corn field, barn, coop or egg stand** (ADR 0024). Gary's lines and straw burst wait for the tutorial step.

## Checks
- Docs only. No code. The `d60d3cf` review evidence is in the 08-29 note: `check.sh` GREEN with 19 suites, the S0 hash reproduced.

## Dialogue trace
- User: "ok can you create a session over the codex to continue" (card C2: "Session that drives Codex").
- Peer messages:
  - the review session: N2 isn't approved; add the vault-edit rule to every brief; renumber to S4 = bosses;
  - the fun-systems session: ADR 0024, the order S4 → ch2 redesign → S6;
  - the review session: "please stand down", because of ADR 0025.
- Card X1 (paste the brief, or run `codex exec`) was never answered. It's moot under ADR 0025.
