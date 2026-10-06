<!--
What this file answers: the shape of the project — what modules exist, where responsibilities live, and why it's drawn this way.
When to update: any new module, renamed boundary, or refactor that moves responsibility across a boundary. Same turn as the code change.
-->

# System design

## Shape (one paragraph)

Moo Rush is one HTML file (`prototype/index.html`) with no build step and no backend. The content is data tables at the top: `STAGES`, `HARBOR`, `VEHICLES`, `GUNS`, and the `PM`/`TUNE` economy. That data is laid out as one big world: 10 areas (9 chapters plus the harbor lake), each a grid of 470×420 cells. Each module has a type (`field`, `machine`, `counter`, `supply`, `gate`, `garage`, `armory`, `bank`, `dock`, `debate`, `states`, …), and each upgrade pad has an effect `fx` that changes the world when paid. A per-frame `update` runs the player, the helpers, belts and trucks, customers turning into zombies, robbers, day and night, events and bosses. Then the canvas `draw` runs, with DOM overlays for the HUD, menu and modal.

## Block diagram

```
STAGES/HARBOR/VEHICLES/GUNS (data) ──buildWorld()──► mods, pads, cells, solids
input (touch sticks / WASD+mouse) ─► player move + act() (take/give/buy pads) + aim/fire/dash
update(dt): helpers & belts, trucks, customers→zombies (findPath/NAV), robbers, day/night,
            weather, goals, events, bosses, fever ─► computeReveal() (fog/bounds)
draw(): canvas world + DOM HUD/menu ; sfx (Web Audio)
save: snapshot() ⇄ localStorage slots (+ window.claude db when inside claude.ai)
```

## Module boundaries
- **Data tables:** only content and numbers. `PM`/`TUNE` rescale the prices when the page loads.
- **`buildWorld` / `buildModule`:** the only place that lays out the geometry.
- **`applyPad`:** the only place an upgrade changes state. It's replayed when a save loads (`fromLoad`).
- **Saves:** `snapshot`/`applyState` plus the slot functions, with migrations for older versions.
- **`window.__moo`:** the test surface, the only thing tests should use.

## Why this shape
It was built as a claude.ai artifact, which had to be a single page. The single solid boundary of land and clouds, and pathfinding instead of straight-line chasing, both fixed real stuck bugs (see `sessions/`). Don't regress them.
