# ADR 0008 — Extend the native world to two persistent districts

**Status:** Provisional implementation choice, pending Android Chapter 2 playtest
**Date:** 2026-10-07
**Supersedes:** None

## Context
The approved staged port now moves beyond Chapter 1. The slice built only Farm Kid, with a local navigation grid and a terminal dairy gate. The frozen HTML spec keeps unlocked districts alive in one world. Rebuilding a single active district would discard the old farm's production and contradict that behavior.

## Decision
Build districts 0 and 1 together in their original adjacent map positions. Gate 0 opens Farmer and travels to its corn field; gate 1 marks the implemented slice complete until Baker is ported. Keep unlocked production, upgrades and stock in both districts. Resolve pad/helper/conveyor references by district plus module ID, because A/B/C IDs repeat. Show three unfinished pads per unlocked district, and allow menu travel to unlocked areas.

Expand navigation to both districts and block unrevealed cells and coordinates outside the walkable world. Preserve keyed saves; ten-pad Chapter 1 saves restore via keys (or old array), and old `done=true` migrates to dairy ownership/Chapter 2 without marking Chapter 2 complete. No reset or forced new game.

Daytime Farmer has corn/milk/cheese and eggs, helpers and 12 pads. Its night taco module/pads remain deferred with night/combat. No architecture dependency changes.

## Alternatives
- Replace the old farm when entering Chapter 2: simpler, but loses the prototype's persistent world and requires a different save contract.
- Port all nine districts now: expands unverified scope and conflicts with staged delivery (ADR 0005).

## Consequences
Two-district stock/upgrades survive saves and travel. Simulation cost grows with open districts; visible drawing remains culled/cached. Headless bots must purchase both gates naturally, prove cheese sales and route isolation, and exercise populated saves and old completion migration. Android installation and a rendered dairy review remain required before landing.
