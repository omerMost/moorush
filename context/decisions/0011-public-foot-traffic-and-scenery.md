# ADR 0011 — Restore solid scenery and route customers around crops

**Status:** Provisional implementation choice, pending Android visual retest
**Date:** 2026-10-07
**Supersedes:** None; extends ADRs 0006 and 0009.

## Context
The user reports odd cheese, characters crossing gardens and missing map trees in Android 0.3.0. The native port omitted the HTML's deterministic scenery and solid tree/pond shapes; customer movement used straight lines. Fields must remain accessible for player/helper harvesting.

## Decision
Restore the frozen HTML's seeded tree/pond placement in unused cells, keeping the walking lane clear. Trees have circular collisions, ponds rectangular collisions, and revealed trees share character depth sorting. Scenery regenerates deterministically rather than entering save data. Redraw cheese as a clearer wedge inside the existing baked item cache.

Customers use cached A* paths for queuing and departures. A separate public-traffic mask excludes active crop beds with an 18-unit margin; it combines with the regular solid/fog mask. Players and harvesting helpers retain normal field access. Incremental navigation refresh updates both masks and invalidates affected actor paths. An unreachable customer route waits rather than falling back to walking through a garden.

## Alternatives
- Make all crop beds solid: would break harvesting and contradict the intended player controls.
- Cosmetic trees without collisions: contradicts the prototype and makes the scene misleading.
- Per-frame pathfinding: unnecessary CPU cost on a phone; retain each route until destination or geometry changes.

## Consequences
Verify real queue/departure traffic, field-crossing detours, harvesting access, tree/pond collisions and both navigation masks. Run full natural careers/save checks and inspect rendered scenery/cheese before installing. Night combat remains a separate port step; this fixes the Android characters already present.
