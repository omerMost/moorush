# ADR 0014 — Explicit app suspension independent of the slot menu

**Status:** Provisional implementation choice; local lifecycle regression and phone Home/cold-reopen verified; lock/wake pending
**Date:** 2026-10-07
**Supersedes:** Implicit reliance on the OS stopping the simulation after focus loss.

## Context
Android background/lock testing exposed an unverified lifecycle contract. The old notification handler saved on focus loss/pause but did not explicitly freeze simulation, stop voices or clear sampled input. HUD cleared touch on focus loss only; pause-only or stale sampled input depended on a later frame/OS behavior.

## Decision
Track OS focus and app pause separately from menu pause. Suspension is the union of lost focus and app pause; gameplay resumes only after both conditions clear. Entering suspension saves once, stops active audio, discards queued cues, clears touch and sampled/test movement. World stops simulation/audio dispatch while suspended. Repeated and reversed notifications are idempotent. Menu visibility/pause and sound preference survive without modification. The first resumed frame samples fresh input before simulation.

Debug Android logs suspension transitions. A stdlib host collector records bounded engine frame windows and battery-temperature checkpoints without changing game/save/device settings. It retries transient read failures and resumes only the same app process/duration. Resume stores the original epoch; legacy summary recovery from file mtime is explicitly marked estimated and cannot count as uninterrupted performance acceptance. Suspension markers also invalidate a run independently of the periodic foreground checkpoints; brief app switches must not be missed.

## Alternatives
- Rely on Android to stop processing: leaves pause-only/stale-input behavior implicit and untestable locally.
- Reuse menu pause: loses whether the menu was open and risks automatic menu dismissal/resumption.
- Force the slot menu on every interruption: changes the existing return-to-game flow unnecessarily.

## Consequences
Headless real-scene regression checks notification ordering, disk save and cold reload, sparse inventory, input/audio cleanup, frozen updates and menu preservation. Real Home/cold-reopen/app-switch handling is verified on POCO. Lock/wake and uninterrupted sustained performance still require exclusive use of the unlocked connected phone. In-flight goods/helper cargo remain omitted under ADR 0010; there is no offline progress simulation.
