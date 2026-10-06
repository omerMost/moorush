# ADR 0010 — Extend persistent progression through Baker

**Status:** Provisional implementation choice, pending Chapter 3 Android playtest
**Date:** 2026-10-07
**Supersedes:** [ADR 0008](0008-two-persistent-districts.md) for the two-district limit and terminal bakery gate; district-qualified persistence remains unchanged.

## Context
The user approved Baker as the next staged port. The previous native endpoint was buying the bakery, while the frozen HTML continues into wheat/bread and apple/pie production. A hard-coded two-district grid and chapter clamp cannot support this approved step.

## Decision
Use `MooData.STAGE_COUNT` (currently 3) for world construction, navigation bounding box, gate progression, save migration and HUD limits. Keep all unlocked districts producing at their prototype positions. The bakery gate now opens Baker; the supermarket gate ends the implemented slice until Chapter 4. Port Baker's seven modules and twelve pads with the prototype prices/tuning; retain daytime-only scope.

Replay keyed payments and support old ten/22-pad array prefixes. Old completed endpoints become ownership of the next implemented district, preserving wallet, capacity, inventory and prior upgrades without granting its upgrades. Travel accepts only implemented, unlocked districts. Keep incremental obstacle refresh from ADR 0009 and cache the four new procedural item drawings.

## Alternatives
- Add another collection of hard-coded chapter limits: smaller immediate edit but repeats the same migration/grid issue on the next staged chapter.
- Load only the visited district: reduces simulation cost but contradicts the persistent-world contract and discards unattended production.

## Consequences
Bots must buy all 34 pads naturally, prove bread/pie sales and local routes, restore populated three-district saves and older endpoints, and compare incremental navigation with full rebuilds. Rendered and phone-sized menu checks cover three travel buttons. Real phone data is backed up and validated before replacing the APK. Night/combat and Chapter 4 remain queued; full-career sustained device performance still needs playtesting.
