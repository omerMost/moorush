<!--
What this file answers: the happy-path walkthrough of the project's primary flow, from user input (or request) to final output.
When to update: any change that alters the sequence, adds a step, or changes where a step runs. Same turn as the code change.
-->

# Data flow

## Primary flow: produce → sell → upgrade → grow the world

1. **Harvest:** the player walks over a field and picks ripe crops (`harvest`) into the carried stack, up to `S.cap`. Crops are only picked when something can use them.
2. **Process:** the stack is dropped on a machine's in-pad, into its hopper. Animals or stations turn the input into output on the machine's tray every `period` seconds. A conveyor (`feed`) or a helper automates this step.
3. **Sell:** output is carried to a counter's drop. Customers queue with a patience ring, are served, and leave coins or votes in the counter's cash pocket. A full pocket spills, which is where the bank collector comes in.
4. **Buy:** standing on a pad pays into it a little at a time. When it's fully paid, `applyPad` applies its effect: an unlock, a helper, more units, a price change, a vehicle, a gun, the chapter gate, and so on. Then `computeReveal` clears the fog, and the game saves.
5. **The chapter gate** opens the next area. In the political chapters gates cost votes. The candidate wins at 270 electoral votes, then gets the ending, and can retire (prestige).
6. **The threat loop:** an unserved customer turns into a zombie (faster at night). It pathfinds to the player, winds up, and bites, knocking out items or coins. Shooting it with carried products cures it and pays a bonus.

## Failure paths
- **Stuck player or helper:** the unstick safety net moves them to the nearest open spot.
- **localStorage blocked:** the try/catch means the game keeps running without saving.
- **Cloud save:** it's skipped when `window.claude` is missing (standalone).

## Trust boundaries
None. It's a client-only game, and the only external resource is the Google font.

## Native slice flow

Touch/keys in `hud.gd` feed `Moo.sim.move_in`; the world view calls `MooSim.update(dt)`. Players and helpers harvest, feed machines, carry products and collect counter earnings. Standing on pads pays progressively, applies upgrades and reveals cells; the dairy gate opens Farmer and travels to its field, while the bakery gate marks the two-chapter slice complete. Milk feeds the cheese press; helpers move corn, milk, cheese and eggs within their district. The view draws this state with procedural sprites. Headless bots drive the same movement and simulation.

`MooSim.snapshot()` writes each selected slot to its own `user://moo-rush-slot-N.json`; loading rebuilds both persistent districts, migrates old Chapter 1 completion into dairy ownership, replays district-qualified finished pads and restores persisted goods, held stack and position. Current-version keyed payment restores exactly. In-flight items/helper cargo remain omitted as in the prototype. Menu/focus/background transitions save; exiting clears in-flight callback references. Android uses the same flow with a logical viewport scaled to device pixels.

Native input sampling runs before World simulation each frame. Drawing reuses opaque item textures after the first rendered frame; fallback primitives cover warmup/translucency/headless. These caches affect presentation only. Debug Android frame timing logs contain FPS/frame p95/draw CPU, with no save or gameplay changes.

Sound: simulation actions emit pick/drop/coin/warn/unlock/gate events; World sends them to cached audio clips before draining the queue. Gate suppresses duplicate unlock celebration, repeated actions are rate-limited, and mute prevents playback. Menu toggle writes only the audio preference file; game slot state remains independent.

Menu travel moves the player to an unlocked district without resetting the career, stock or upgrades. Three unfinished pads remain visible per unlocked district; both farms continue production while visited elsewhere.
