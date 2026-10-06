# ADR 0009 — Keep upgrade feedback local and update navigation incrementally

**Status:** Accepted following Android playtest (user: "yes", 2026-10-07)
**Date:** 2026-10-07
**Supersedes:** None; refines ADR 0008's navigation implementation

## Context
User reports: "when i finish to pay for new upgradge i get a glitch not nice to the eye". Every paid upgrade adds camera shake; module unlocks hold camera focus for 1.3s. Each completion rebuilds the entire two-district collision grid synchronously. Local isolated completion profiling measured about 69–110ms, with the first chapter gate about 190ms (two reveal calls).

## Decision
Keep confetti, sound, toast, fog reveal and save feedback; remove shake and temporary focus from ordinary upgrade completion. Preserve chapter travel. Refresh cell obstacles, compare old/new geometry, and update navigation only within changed cells plus a 60-unit margin (covers 50-unit walkability margin and collision radii). Skip map/path invalidation if geometry is unchanged. Build a full grid at world creation/reset. No gameplay price or production change.

## Alternatives
- Rebuild the full map at every upgrade: correct but causes a visible main-thread hitch.
- Spread grid rebuilding over frames: would require pending navigation state and temporarily inconsistent collision.
- Retain shake while optimizing only the map: leaves the known visual disturbance on every completion.

## Consequences
Headless equivalence tests compare the incremental mask to a full rebuild after all 22 payments, reset and old save migration. Existing bots must still reach both gates. Local completion after the change is about 0.1–20ms for ordinary upgrades; opening the next district still does more work. Android subjective glitch confirmation remains pending, so the visual cause is not claimed conclusively.

## Validation update
User replied "yes" to the 0.2.1 upgrade-glitch resolution prompt. The reported visual issue is resolved on the phone; this does not isolate which original contributor the user noticed.
