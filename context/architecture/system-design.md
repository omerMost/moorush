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

## Native Chapters 1–2 (ADRs 0005, 0008)

`godot/scripts/data.gd` holds Farm Kid and daytime Farmer content (corn → milk → cheese, plus eggs). Two persistent districts are built at their original adjacent coordinates; district-qualified module references keep conveyors/helpers local. `MooSim` (`sim.gd`, RefCounted) owns the real production/progression/navigation/save logic; the `Moo` autoload exposes it to UI and bots. `world_view.gd` advances and draws it with `Paint`; `hud.gd` handles the slot menu, joystick, keyboard and HUD. `main.tscn` wires these together. The view uses a logical 540×960 expanding portrait canvas.

`check.sh` imports and boots the project, then runs six headless suites: Chapter 1/2 bots, unattended counters, saves, touch HUD and audio. Tests and the running autoload dispose in-flight callbacks when discarding a simulation, releasing callback reference cycles. Android exports through the committed preset. Optional `test_windowed_chapter1.gd` instantiates the real main scene and drives the guide bot while rendering milestone screenshots; it is separate from headless check.sh.

Slice limits are explicit: daytime only, no combat/special customers, placeholder shops, deferred Farmer night taco module/pads, and a completion flag at the bakery gate until Chapter 3. Old Chapter 1 completion migrates to Farmer ownership; stock, upgrades, wallet and carried goods survive. Menu travel preserves progression and both farms keep producing. The navigation grid spans both districts and blocks land outside the revealed world. The HTML remains the frozen specification.

## Drawing cache (ADR 0006)

`Paint.prime_items()` renders the five procedural product/coin drawings including cheese into 4× transparent SubViewports once, copies them into ImageTextures and releases the temporary nodes. Opaque item draws use those textures; translucent items and headless tests retain the primitive path. Bounded local rounded/ellipse points and text sizes are reused; grass uses a retained point array and multiline batches. `HUD.process_priority=-10` samples input before World’s simulation update. Debug Android `Moo` reports five-second frame timing windows; explicit `--profile=300` measures World draw CPU on desktop.

## Sound and offline font (ADR 0007)

The `Moo` autoload owns a `MooAudio` child. `World` consumes the simulation’s event queue through it before clearing events, and menu/load actions schedule short cues. Six clips are synthesized once; eight players bound overlapping sounds. A menu CheckButton persists mute separately from save slots. `Paint` uses the bundled Baloo 2 variable FontFile through FontVariation weight 800; emoji retain system fallback. The font and OFL license ship in the APK.

Sound menu exposes explicit ON/OFF and a Test sound celebration, disabled when muted; enabling plays confirmation. Voices use +6dB gain for short phone cues. User confirms audible output on 0.1.3; full gameplay cue coverage and manual muted listening remain pending.

`test_windowed_chapter2.gd` drives the real bot through dairy production and captures press/store/menu, then checks travel to the farm in isolated storage.
