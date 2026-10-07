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

## Native Chapters 1–3 (ADRs 0005, 0010)

`godot/scripts/data.gd` holds Farm Kid, daytime Farmer and Baker content (corn → milk → cheese, eggs, wheat → bread and apples → pies). Three persistent districts are built at their original adjacent coordinates; district-qualified module references keep conveyors/helpers local. `MooSim` (`sim.gd`, RefCounted) owns all mutable state, economy/threat RNGs the tick order and source-compatible forwarding API. Eleven composed RefCounted systems in `scripts/sim/` hold world/pads/belts, items/actions, customers/counters, agents/guide, nav/collision, saves/travel, feedback, clock, zombie, combat and heart/checkpoint logic (ADRs 0019–0023); typed weak owner references avoid ownership cycles. The clock advances chapter-local day/phase/night state before production; its boundary segments drive waves and dawn conversion; dusk captures a slot-local checkpoint and sunrise refills hearts; combat ticks before zombie bites; the `Moo` autoload exposes it to UI and bots. `world_view.gd` advances and draws it with `Paint`; `hud.gd` handles the slot menu, joystick, keyboard and HUD. `main.tscn` wires these together. The view uses a logical 540×960 expanding portrait canvas.

`check.sh` imports and boots the project, then runs fourteen headless suites: clock transitions/persistence, night escalation/turning/Gary/routes/saves, fixed-seed snapshot determinism, Chapter 1/2/3 bots, unattended counters, saves, touch HUD, audio, upgrade/navigation equivalence, customer routes/scenery collisions and spatial transfer/concurrency regressions and app lifecycle. Tests and the running autoload dispose in-flight callbacks when discarding a simulation, releasing callback reference cycles. Android exports through the committed preset. Optional `test_windowed_chapter1.gd` instantiates the real main scene and drives the guide bot while rendering milestone screenshots; it is separate from headless check.sh.

Slice limits are explicit: night bites cost one of five hearts, with one-second immunity and an explicit checkpoint retry card; Milk/Egg/Pie weapons and dash are enabled; bosses and special customers remain subsequent ports, placeholder vehicle/bank shops, deferred Farmer night taco module/pads, and a completion flag at the supermarket gate until Chapter 4. Old Chapter 1/2 completion migrates to Farmer/Baker ownership; stock, upgrades, wallet and carried goods survive. Menu travel preserves progression and all unlocked districts keep producing. The navigation grid spans the implemented district bounding box and blocks land outside the revealed world. The HTML remains the frozen specification.

## Drawing cache (ADR 0006)

`Paint.prime_items()` renders the nine procedural product/coin drawings including cheese and Baker products into 4× transparent SubViewports once, copies them into ImageTextures and releases the temporary nodes. Opaque item draws use those textures; translucent items and headless tests retain the primitive path. Bounded local rounded/ellipse points and text sizes are reused; grass uses a retained point array and multiline batches. `HUD.process_priority=-10` samples input before World’s simulation update. Debug Android `Moo` reports five-second frame timing windows; explicit `--profile=300` measures World draw CPU on desktop.

## Sound and offline font (ADR 0007)

The `Moo` autoload owns a `MooAudio` child. `World` consumes the simulation’s event queue through it before clearing events, and menu/load actions schedule short cues. Six clips are synthesized once; eight players bound overlapping sounds. A menu CheckButton persists mute separately from save slots. `Paint` uses the bundled Baloo 2 variable FontFile through FontVariation weight 800; emoji retain system fallback. The font and OFL license ship in the APK.

Sound menu exposes explicit ON/OFF and a Test sound celebration, disabled when muted; enabling plays confirmation. Voices use +6dB gain for short phone cues. User confirms audible output on 0.1.3; full gameplay cue coverage and manual muted listening remain pending.

`test_windowed_chapter2.gd` drives the real bot through dairy production and captures press/store/menu, then checks travel to the farm in isolated storage.

Upgrade feedback (ADR 0009): sound/toast/confetti remain local; ordinary payments do not shake or hold the camera. Obstacle refresh updates only changed cells plus a 60-unit margin in the navigation mask, and preserves helper paths when geometry is unchanged. Full map build remains at world reset.

`test_windowed_chapter3.gd` verifies naturally produced bread/pies, wheat/apple fields and the three-button travel menu. `MooData.STAGE_COUNT` drives world build, gate progression, save migration, navigation bounds and HUD chapter limits; old 10/22/34-pad arrays restore the economic-pad sequence.

## Scenery and public traffic (ADR 0011)

Unused cells regenerate the frozen HTML seeded trees/ponds at world build. Revealed trees join character depth sorting; tree circles and pond rectangles enter the normal collision/navigation mask. Customers cache A* paths for queue/departure movement. `NAV.public_blk` adds crop-bed and output-tray exclusion for customer routes; players and harvesting helpers use the normal mask. Incremental obstacle refresh updates both masks and invalidates customer/helper paths. The optional `test_windowed_decor.gd` captures naturally revealed scenery and cheese sprite comparison.

Output holders use shallow light wooden crates at the existing pickup geometry. Public routes exclude active trays by 25 units; safe customer entry/lost-exit points stay at the counter boundary. Blocked public goals retain an empty cached route until geometry/destination changes (ADR 0012). Decision C1 selects the cut cheese wheel from the native procedural previews. Its 24×17 pile spacing matches the option image, while carried spacing stays 14; stock counts and pickup rectangles are unchanged.

Output trays hold stable slot IDs, including separate arrival reservations. Pickup selects the nearest exposed arrived slot; output fills the first free hole. Stack transfer tokens dynamically target visible stack height during concurrent drops. Shared stack positions include sway. `flight_pose()` supplies drawing and numerical tests with the Toss eased arc, fixed mouth target, shrink/fade (ADR 0013).

OS lifecycle flags (`Moo.app_focused`, `app_paused`) combine into `suspended`, separate from menu `paused`. Entry saves once, zeros movement/touch, stops voices and clears queued cues; World freezes simulation/dispatch until focus and pause conditions both clear. HUD ignores suspended input and samples a fresh frame on resume. Debug Android transition logs and read-only host soak collection support device checks; suspension markers invalidate continuous-run claims even if every foreground checkpoint is true (ADR 0014).

`night_view.gd` draws one shader overlay after world pieces, with at most 24 v9 radial lights (player, active counters, helpers). `night_lighting.gdshader` applies blue/red darkness while the separate HUD remains bright. The HUD clock sits under the rank pill. Rendered `test_windowed_clock.gd` verifies pixel darkness/light holes, third-night tint and HUD isolation (ADR 0020).

Night actors (ADR 0021): `sim/zombies.gd` drives three escalating beats with a shared ten-actor cap, night-only nearby customer turning, and Gary-only chapter-1 night 1. Actors use NAV/A* with rotating four-plan replanning budget, safe collision movement and unstick; no failed-route straight fallback. An independent saved threat RNG avoids coupling path scheduling to customer RNG. `zombie_paint.gd` draws grumpy faces, joke props and Gary; full character body shapes and combat animation remain pending. `test_windowed_night.gd` verifies every actor appears under the shader and leaves the HUD unchanged.

Heart/checkpoint ownership (ADR 0022): MooSim holds health, immunity, pending faint and two immutable backups inside each slot JSON. The weak-owned hearts component applies damage, captures chapter entry/dusk and restores all native saved districts/progression/inventory, keeping tutorial/wardrobe/lifetime stats. Completed Gary does not return after retry. A pending faint survives cold load and freezes simulation until HUD retry; OS suspension/menu stay independent. Checkpoints settle reserved goods once; ordinary saves preserve arrived helper cargo under the existing arrived-goods contract. Main and threat RNG states serialize as decimal strings. Economy bots use an explicit test-only damage override alongside the separate real-damage fight driver.

Combat ownership (ADR 0023): MooSim owns three manual weapons, shots and timers; `sim/combat.gd` handles arrived-stock ammo, ±14° assist, swept collisions, splash, dash and bounded feedback. Three armories add nine optional pads alongside three economic-pad slots per district. Base purchases and upgrades replay through the existing pad API. `combat_controls.gd` belongs to the HUD and keeps left movement/right aim touch IDs independent, with tap/hold fire, mouse aim and dash button/keys. Product projectiles reuse drawing caches; pitched cure/pop clips reuse the bounded audio pool. Menu/suspension/faint/travel/reset clear combat input and active dash. Cooldowns persist, flights do not. Per-weapon upgrade state derives from payment replay and rolls back with checkpoints.
