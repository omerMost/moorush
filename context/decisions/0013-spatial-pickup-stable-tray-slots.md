# ADR 0013 — Spatial pickup with stable tray slots

**Status:** Provisional implementation choices, pending phone feel retest
**Date:** 2026-10-07
**Supersedes:** Count-compacted native output-tray layout; extends ADR 0010 save flow.

## Context
The user reports pickup taking items from the end rather than near the character, and unsmooth Toss transfers. Count-only piles erase the last slot regardless of the pickup origin. Carried counts include incoming goods, so Toss/drop could remove goods before arrival and leave flyers targeting outdated stack heights.

## Decision
Track stable slot IDs for machine output trays. Pick the closest arrived exposed item using the same coordinates as the drawing; a higher item in the same column must be removed first. Survivors stay fixed. Production reserves the first free hole, hidden until its flight lands. Crop harvesting likewise chooses the nearest ripe tile within the existing 40-unit radius.

Persist visible tray IDs in optional `bx.tp` alongside the existing `t` count. Old count-only saves reconstruct contiguous slots; invalid layouts fall back to counts. In-flight goods/helper cargo remain omitted under the existing save contract.

Incoming stack transfers have pending tokens and target the current visible stack height. Toss, machine drops and conveyors consume only arrived items and launch from the shared drawn/swayed stack position. Toss uses a fixed bin-mouth target, a 0.32-second eased arc and final shrink/fade. Rates, prices, capacities and pickup rectangles are unchanged.

## Alternatives
- Change only flight origin: still removes the wrong visible item and shifts survivors.
- Compact all positions after nearest removal: adds sideways jumps during rapid pickup.
- Introduce full physical item entities: larger simulation/save change without benefit for bounded trays.

## Consequences
Sparse tray saves round-trip without reshuffling. Arrival reservations prevent duplicate placements and premature consumption. Numerical spatial/concurrency checks and rendered pickup/Toss frames supplement natural career bots. Full phone feel acceptance remains the user's decision.
