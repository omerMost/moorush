# ADR 0012 — Keep customer traffic clear of item holders

**Status:** Provisional implementation choice, pending Android retest
**Date:** 2026-10-07
**Supersedes:** None; extends ADR 0011.

## Context
The user reports that characters still enter milk/cheese item holders after crop avoidance. The public mask excluded fields but not machine output trays. The old lost-customer exit at counter origin minus 60 lies inside the neighboring machine's tray. Players and helpers must still collect products there.

## Decision
Add active output trays with a 25-unit margin to the public traffic mask. Keep regular navigation open to pickup. Spawn and lost-customer exit points use counter origin minus 8, outside neighboring trays. Reject blocked public destinations and cache an empty failed route until destination or geometry changes; do not repeatedly search or fall back through a holder.

Replace dark output trays with shallow light wood crates at the existing geometry. Cheese appearance remains unchanged until the user chooses from native-rendered options (decision C1).

## Alternatives
- Make holders solid in all navigation: breaks existing pickup paths and helper stands.
- Change only exit coordinates: does not protect other routes that cross the holders.

## Consequences
Real queues/departures and forced tray crossings must keep feet clear. Normal pickup paths remain available. Both incremental masks must match full rebuilds; natural careers and saves must still pass. Visual acceptance of crate/cheese designs remains the user's decision.
