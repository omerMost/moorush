# ADR 0021 — Native night actors and persistence

**Status:** Provisional builder choices, pending Claude review (ADR 0015)
**Date:** 2026-10-07
**Supersedes:** None. Implements the next part of ADR 0018 after ADRs 0019–0020.

## Context

The user said "continue" after the chapter clock/lighting foundation. The approved port order puts night actors before hearts/checkpoints and weapons. The frozen prototype's straight-chase fallback violates the hard-won native solid boundary. Actor movement also needs a bounded mobile planning budget and slot-isolated persistence.

## Decision

- Compose `scripts/sim/zombies.gd` behind MooSim. Actors, scheduler state and a separate threat RNG stay on the facade. Seed the threat stream from the simulation seed without consuming its economy stream. Persist its 64-bit state as a decimal string; JSON numeric floats cannot represent every 64-bit integer.
- Clock boundary segments advance the three-beat scheduler; dusk initializes it, sunrise wakes real zombies on public paths as leaving customers, chapter entry clears threats. First real nights request 2/4/6 at 0/30/60s; later nights add one per beat. The cap is ten, including turned customers and unfinished Gary. Blocked/capped spawns are skipped, not queued into a later burst.
- Night patience advances 3x; only nearby lost customers on real nights turn. Ch1 night 1 has Gary only. Daytime rating loss and the 1.5x late-service tip stay. Threat draws do not perturb customer appearance/spawn RNG, but faster patience intentionally changes the career economy; replace the current determinism hash after measuring, retaining S0/S1 evidence in their session notes.
- Every chase uses the existing NAV/A* route, replanning at 0.5–0.7s. Four plans per tick rotate across actors to avoid starvation. Failed/exhausted routes wait; movement uses solid collision checks and the nav unstick safety net. Upgrade invalidation clears zombie routes along with existing traffic caches; the nav algorithm and incremental masks stay intact.
- Optional `tut` and `night` fields extend native saves. Preserve Gary's flag, actors/HP/timers/paths, the beat elapsed/cursor/serial and threat RNG per slot. Loading emits no retrospective phase/beat events. Older advanced saves skip Gary; older mid-night saves join the next beat without retroactive waves. JSON actor float round-trips are checked within 1e-8; the scheduler integers/RNG string are exact. Existing wallet/upgrades/inventory migration remains.
- Gary appears at the first evening, waits gunless, follows slowly if `S.gun` is supplied, never bites, and ends on a hit or after 60 armed seconds. His affordable weapon guide seam activates when the weapon port adds the actual Milk squirter pad. The current scene has no weapon purchase/fire input, so this is verified through actor/guide fixtures. No Grandpa tutorial is claimed.
- Normal actors expose 0.55s bite windup/0.9s recovery events, HP and `hit_zombie`/cure-reward hooks. **Bites cause no damage or stock/wallet loss in this landing.** The next hearts/checkpoints step owns damage and restores; player shooting follows with weapons. Base HP is 3/6/12, Karen rounds ×1.5, big ×3, Granny adds two chapter-weapon hits and slows ×0.7. Lactose's dairy multiplier is in the hit hook.
- Procedural `zombie_paint.gd` supplies grumpy faces, torn hems, joke props and Gary's mask/plaid/straw colours. Full parameterized body silhouettes/customer mood animation, exact Gary straw/mask/clothes animation, Vaulter leap and Influencer flash rendering remain with the art/combat pass. Existing item caches are retained; no dependency is added.

## Alternatives rejected

- **One shared RNG:** path-budget timing would change future customer random draws. A saved independent stream gives reproducible threat fixtures and keeps that coupling explicit.
- **Prototype straight fallback or unlimited A*:** the former crosses solid scenery/fog; the latter has unbounded per-frame planning. Waiting plus rotating budget keeps routes safe and actors progressing.
- **Drop actors/reset waves on load:** replaying dusk can regenerate waves or remove threats for free. Save the complete small actor set instead.
- **Implement hearts/weapons/bosses in this commit:** would combine several accepted verification steps and obscure failures. Keep their hooks visible and their user-facing limitations recorded until the subsequent ports.

## Consequences

Native nights now have chase actors and accelerated patience, with harmless bites while the next systems are built. The fight bot, real gun-to-Gary acceptance and device performance are still pending; actor/route/render tests do not substitute for them. No boss/gate requirement or weapon economy is enabled in this step. The full headless career takes 221.2s wall versus the earlier ~85–97s; Android beat/replan/save profiling is queued before night-device acceptance.
