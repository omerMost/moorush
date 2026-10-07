# ADR 0023 — Native weapons, carried ammo and combat controls

**Status:** Provisional builder choices, pending Claude review (ADR 0015)
**Date:** 2026-10-07
**Supersedes:** None. Implements S3 of ADR 0018 on the ADR 0019 component seam.

## Decision

- Compose weak-owned `sim/combat.gd`; MooSim owns shots, input and combat timers. Add a real armory in each supported district, with three optional pads each. Keep the three economic-pad reveal slots independent from weapons. Upgrades require their local base purchase, remain per weapon and replay from saved payments. Gates remain directly purchasable; boss ownership requirements follow S4.
- Final provisional coin prices: Milk 100/200/300; Egg 1200/1800/2400; Pie 4000/4000/5000 (base/nozzle/pump). The normal guide saves for the base after two local economic investments; it saves for remaining upgrades after local automation (all economic pads in ch1–2, six investments in ch3). This makes the natural economy bot's night-2/night-6 deadlines explicit assertions. Pie's initial 6000/8000 upgrade proposal was reduced and prioritized because late production purchases would miss the sixth-night target. Production and gate prices are unchanged.
- Ammo is any carried farm product, one **arrived** item per shot; incoming reservations/tokens remain untouched. An owned gun supplies a player-only destination for harvesting/pickup even when production inputs/counters are full. Helper demand filtering stays intact. Milk/cheese retain the Lactose ×3 multiplier.
- Implement specified damage/cooldown/range, two multipliers, 720px/s shots, ±14° assist, 150ms target magnetism, range expiration and swept segment collision. One actor receives primary damage; Egg/Pie nearby actors receive 1/2 splash damage respectively, once each. Snapshot iteration handles multiple cures/removals safely. Quick taps obey the same cooldown as held fire.
- HUD-owned `combat_controls.gd` splits simultaneous movement/aim touch IDs, tracks peak drag for quick taps, and supports mouse aiming/hold plus Space/Shift or a Dash button. Sample before the simulation. Disable desktop mouse-to-touch emulation and ignore touch-generated emulated mouse events in combat, preserving ordinary GUI taps. Releases clear their existing IDs even over Dash/menu. Dash is 2.6× for .18s at full input magnitude even with a partially deflected stick, with 2.5s cooldown and .33s immunity; movement still uses normal collision/fog/unstick. Vaulter's .55s burst handles hit knockback first and also follows safe A*, retaining the hard-won solid-world contract. Karen/Granny/big HP and joke props remain from S1; Granny comments when hit; Influencer flashes for .25s.
- Projectiles use cached product sprites. Add muzzle/hit flash, knockback/slow, short simulation hit-stop, shake, combo floaters and pitched cure audio through the existing bounded eight-voice pool. Cosmetic combat effects consume no economy RNG.
- Save equipped weapon and firing/dash cooldowns; derive upgrades from paid pads. Flights, active input, combo, flash and hit-stop are ephemeral. Menu, suspension, faint, reload, retry and travel clear combat input; clearing cancels active dash but retains its cooldown. Already-spent ammo stays spent in ordinary saves; retry restores the checkpoint's ammo and weapon payments. Historical array-only 10/22/34-pad native saves map through economic pads; keyed migration and prior price-rescale rules remain intact.

## Alternatives

- Putting weapon pads inside the three-pad economic queue could hide/delay production or weapon availability. Independent optional pads preserve both choices.
- Reusing incoming stack goods or instantaneous endpoint collision would allow premature ammo use or projectile tunneling. Settled-stock consumption and swept collision avoid both.
- Saving projectile references/held fingers would replay stale shots after reopening or crossing districts. Keep cooldowns, spent stock and ownership; clear transient actions.

## Verification and limits

`test_weapons`, dual-touch/pointer/lifecycle tests, actual armory/Gary rendered play, ten-seed normal-night fights per chapter, natural purchase deadline assertions and the full regression suite verify the step. Economy career bots continue to use their explicit damage override; normal-night combat fixtures exercise real damage, real harvesting/reload and projectiles. This does not claim a naturally surviving full armed career or the boss fight requirements; those depend on S4. Phone night performance acceptance and full Grandpa tutorial remain queued. No APK deployment in this landing.
