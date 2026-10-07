# ADR 0019 — Cached shape meshes instead of per-call polygons

**Status:** Accepted for the code (provisional until the POCO soak confirms; see session 2026-10-07 perf note)
**Date:** 2026-10-07
**Supersedes:** _(none)_. Extends ADR 0006 (cached procedural drawing).

## Context

Android 0.1.1 drifted from ~97 to ~43 engine FPS over ~8 minutes as draw CPU rose; 0.3.5 partial runs averaged 57 FPS / draw 11 ms. A 32-minute headless full-farm run (`test_perf_drift.gd`) showed **no unbounded growth**: every collection plateaus (stock piles fill to their caps, ground coins expire after 30 s, object/node counts and memory are flat). The draw cost rises with *scene load* (more modules, helpers, customers and fuller piles as the farm progresses) and then levels off.

The per-element cost was the problem. A primitive micro-benchmark inside a real `_draw` (Mac, Godot 4.7.2):

| call | µs/call |
|---|---|
| `draw_rect`, `draw_line` | 0.1 |
| `draw_texture_rect` (baked item) | 0.5 |
| `draw_colored_polygon` (24 pts), `canvas_item_add_triangle_array`, `draw_circle` | **13–15** |
| `draw_mesh` with a cached `ArrayMesh` | 0.1 |

Godot 4 creates and frees a GPU vertex buffer for every polygon/circle command (triangulation itself was ruled out: a cached fan via `canvas_item_add_triangle_array` cost the same). `Paint.fill_rr`/`ell`/`circ` and people's hair/cap are polygons, so a full farm issued hundreds per frame (one person ≈ 210 µs).

## Decision

- `Paint.fill_shape` keys each convex shape by its exact local geometry (rounded rect w/h/r, ellipse rx/ry/segments, circle r in `draw_circle`'s 64-segment layout, person hair, person cap). The second time a key is drawn, one `ArrayMesh` is built from the same local vertices and drawn with `draw_mesh(mesh, null, translation, colour)`. Single-use keys (pulsing pads) keep the polygon path.
- Meshes not drawn for 300 world frames are released (`Paint.next_frame`), with a hard bound of 1,024; `shape_seen` is bounded at 4,096.
- `world_view.gd` skips helpers and leaving customers whose feet lie more than 140 units outside the already 60-unit-padded view (covers the tallest carried stack, speech and smile).
- `Paint.mesh_cache` / `World.cull_people` switches exist only for the A/B look test; `Paint.polygon_calls` counts uncached polygon commands for the regression budget.

## Alternatives considered

- **Cached fan indices with `canvas_item_add_triangle_array`.** Measured: no gain (buffer creation, not triangulation, dominates).
- **`draw_primitive` quads.** ~4.5 µs per rounded rect: 3× better, 40× worse than meshes.
- **Static layers (separate CanvasItems redrawn only on change).** Larger refactor with draw-order risk (fences over apple trees, piles over trays); not needed once each shape is cheap.
- **Baking shapes to textures / lowering resolution or segment counts.** Changes the look.

## Consequences

- Rendered draw CPU on the Mac drops from ~13.8 ms to ~3.0 ms for the full chapter-3 farm, flat over 32 simulated minutes. `test_windowed_shape_cache.gd` renders 8 views both ways: 7 pixel-identical, 1 with a single edge pixel rounded differently (GPU-side translation), tolerance ≤10 pixels.
- Headless (dummy renderer) cannot see the buffer cost; `test_perf_drift.gd` guards it via the polygon-call budget (≤40/frame; ~8 measured) plus collection plateaus and the 15% drift check.
- New convex shapes should go through `fill_shape`. Non-convex shapes stay on `Paint.poly`; the fan triangulation is only valid for convex outlines.
- A canvas item that draws a cached mesh once and is never redrawn could lose it after 300 frames. Today every Paint user (World, HUD) redraws each frame.
