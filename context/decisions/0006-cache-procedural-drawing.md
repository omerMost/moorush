# ADR 0006 — Cache procedural drawing for the native slice

**Status:** Provisional implementation choice, pending user playtest
**Date:** 2026-10-07
**Supersedes:** None; preserves ADR 0005’s code-drawn look.

## Context
The Android playtest feels like roughly 30 FPS to the user. Native rendering reconstructs hundreds of procedural items/curves and grass segments each frame. The local 300-frame draw CPU benchmark after a deterministic 240s demo measured 21.083ms mean, already above a 60Hz frame budget.

## Decision
Bake the existing corn/milk/egg/coin procedural drawings once into four transparent 192×192 textures (4× logical resolution). Opaque items use a single textured quad; translucent items retain the original path. Headless mode skips baking. Cache bounded local curve geometry and text measurements, and batch grass segments. Sample HUD input before simulation. Keep Mobile renderer, movement/economy and native resolution unchanged.

Debug Android builds print five-second frame timing windows only while playing. An explicit desktop --demo=240 --profile=300 mode measures draw CPU; it is not an FPS equivalence claim.

## Alternatives
- Only cache curve points: removes trig but retains most per-item draw calls.
- Change renderer/resolution: may help GPU limits, but no GPU bottleneck established yet.
- New artwork: changes visual direction and contradicts the port scope.

## Consequences
Four small GPU textures and bounded geometry/text caches exchange memory for CPU work. Initial baking requires a rendered frame, with original drawing as fallback. Headless tests exercise logic and fallback; rendered captures verify the cached path. Android gameplay comparison and frame timing remain required before calling smoothness resolved.
