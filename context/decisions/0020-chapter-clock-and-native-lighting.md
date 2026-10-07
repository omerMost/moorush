# ADR 0020 — Chapter clock persistence and bounded native lighting

**Status:** Provisional builder choices, verified locally; pending Claude review (ADR 0015)
**Date:** 2026-10-07
**Supersedes:** None. Implements the clock foundation of ADR 0018 and extends ADR 0019.

## Context

Following S0, the user asked "continue?". The next approved work is Clock + night. Land its clock/day-night foundation first (S1), with explicit transition seams for subsequent waves, Gary, hearts/checkpoints and bosses. Customer behavior, production, gates and RNG remain unchanged in this foundation; the full Clock + night backlog item remains open.

The frozen v9 clock is 300 seconds: morning to 25%, midday to 50%, evening to 70%, night to 100%. New games start at 8%, so the first 90-second night begins 186 seconds after starting. ADR 0018 requires a per-chapter night count and every third night as a boss hook.

## Decision

- `sim/clock.gd` is the eighth composed system. State remains on MooSim as `S.day`, `S.time` (0–1) and `S.cn`. Clock runs before production in update; it consumes no RNG.
- Boundary stepping emits each phase/dawn once, in order, even with a large clock-only delta. It retains the v9 darkness curve (0–60%, including the short dawn fade). Hooks dispatch through MooSim so later systems/subclasses can handle dusk and sunrise.
- A newly owned chapter starts at day 1 / 8% / cn 0. Visiting an already-owned district through menu travel retains the current campaign chapter's clock. Applying completed gates during loading does not reset it; restore clock metadata after pad replay.
- Add top-level `day`, `time`, `cn` to native JSON snapshots without changing existing inventory/payment keys or version-dependent pad migration. Old native saves default to day 1 / 8% / cn 0. A legacy save with day/time but no cn infers completed nights plus the current night. Loading at night does not replay dusk. Slot writes use full-precision JSON floats so fractional clock values round-trip exactly. An engine probe at time 0.7 − 3e−8 showed default formatting discards a float bit; the regression checks exact restoration before dusk and one subsequent transition. Validate finite phase and nonnegative counters.
- The HUD shows day/phase or night number under the rank pill. Night 3/6/etc uses a red tint; boss actors/banners are still for the later boss port.
- Native lighting uses one overlay quad and a canvas shader, with at most 24 radial lights: player, active counters, helpers. Coordinates/radii/strengths follow v9. Lighting changes neither collision nor gameplay RNG. Existing item/curve/text caches remain intact (ADR 0006).

## Alternatives

- **Keep a single global chapter-independent clock:** simpler, but a newly entered chapter would inherit arbitrary night difficulty and would not give chapter-start checkpoints their own day 1.
- **Persist derived phase and last-transition state:** unnecessary duplicate state; it could replay dusk after loading or disagree with time. Derive phase from persisted time instead.
- **Bake the lighting mask every frame or draw many CPU gradient shapes:** adds texture churn/draw work to the Android surface. One bounded shader pass implements the radial holes without a new dependency. Android sustained performance acceptance remains separate.

## Verification

`test_clock.gd` covers boundaries, 90-second nights, night 3 at 786s, every-third-night hooks, no RNG draws, fine/coarse stepping, real update integration, chapter/menu/reset semantics, reload without dusk replay, migration and slot isolation. The determinism test now pins full clock-bearing snapshots at **4198937285**, and additionally projects out only the new clock keys to retain the original S0 economy hash **1337840505** (338 coins / 19 pads / T 1200.0).

`test_windowed_clock.gd` captures day/evening/night/red third night/dawn, numerically checks the radial player light, red tint and unmodified HUD pixels, and bounds light count. Full headless suites and the rendered Chapter 1 career remain required before landing. Night zombie escalation/Gary, turning, hearts, weapons, boss actors and the taco stand are subsequent work; S1 does not claim them complete.
