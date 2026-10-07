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

Touch/keys in `hud.gd` feed `Moo.sim.move_in`; the world view calls `MooSim.update(dt)`. The facade retains state/RNG and the original tick order, dispatching to composed clock, world, items, customers, agents, nav, saves, feedback, zombie, heart and combat systems under `scripts/sim/` (ADRs 0019–0021). All original API calls and static helpers still work; component constructors do not advance RNG. Players and helpers harvest, feed machines, carry products and collect counter earnings. Standing on pads pays progressively, applies upgrades and reveals cells; the dairy gate opens Farmer and travels to its field, the bakery gate opens Baker, and the supermarket gate marks the three-chapter slice complete. Milk feeds the cheese press; helpers move corn, milk, cheese and eggs within their district. Baker harvests wheat/apples into bread/pie ovens and counters. The view draws this state with procedural sprites. Headless bots drive the same movement and simulation.

`MooSim.snapshot()` and slot methods forward to `scripts/sim/saves.gd`; the existing save flow writes each selected slot to its own `user://moo-rush-slot-N.json`; loading rebuilds all three persistent districts, migrates old Chapter 1/2 completion into dairy/bakery ownership, replays district-qualified finished pads and restores persisted goods, held stack and position. Current-version keyed payment restores exactly. In-flight items remain omitted; arrived helper cargo persists. Menu/focus/background transitions save; exiting clears in-flight callback references. Android uses the same flow with a logical viewport scaled to device pixels.

Native input sampling runs before World simulation each frame. Drawing reuses opaque item textures after the first rendered frame; fallback primitives cover warmup/translucency/headless. Repeated convex shapes reuse cached meshes and off-view helpers/leaving customers are not drawn (ADR 0024). These caches affect presentation only. Debug Android frame timing logs contain FPS/frame p95/draw CPU, with no save or gameplay changes.

Sound: simulation actions emit pick/drop/coin/warn/unlock/gate events; World sends them to cached audio clips before draining the queue. Gate suppresses duplicate unlock celebration, repeated actions are rate-limited, and mute prevents playback. Menu toggle writes only the audio preference file; game slot state remains independent.

Menu travel moves the player to an unlocked district without resetting the career, stock or upgrades. Three unfinished economic pads plus optional base/prerequisite weapon pads remain visible per unlocked district; all unlocked districts continue production while visited elsewhere.

Paid upgrades refresh obstacle geometry incrementally, rebuild affected navigation cells and invalidate helper paths only when needed. Confetti/sound/toast mark completion while the camera keeps following the player. Save writes and chapter travel retain their existing behavior.

World rebuild regenerates scenery from cell seeds without consuming gameplay RNG or changing saves. Tree/pond geometry participates in collision and navigation. Customer queue/departure goals use cached paths with the public crop/tray-exclusion mask; crops remain accessible for harvesting. Revealed trees draw at their depth alongside people.

Customers enter/exit at a clear counter boundary instead of inside the neighboring machine tray. Public navigation keeps them off item holders; player/helper pickup uses normal navigation and unchanged inventory geometry.

C1 presentation: cheese renders as the user-selected cut wheel; wider pile spacing affects display/flyer origins only. Inventory counts, pricing, production and pickup regions retain their existing behavior.

Spatial pickup: ripe crops use nearest distance within 40 units; tray pickup removes the closest exposed arrived slot and preserves survivor positions. New outputs reserve the first free slot until flight completion. Snapshots store optional visible `bx.tp` IDs plus existing counts, excluding incoming goods; old saves rebuild contiguous IDs. Pending stack-flight tokens rebase on current arrived stack height after Toss/drop. Toss, hopper/counter drops and belts transfer arrived goods only (ADR 0013).

Lifecycle: focus loss or application pause enters suspension once, saving the active slot under the existing settled-goods contract, clearing touch/move/test input, stopping audio and discarding queued cues. Repeated events do not write again or advance simulation. Focus gain and resume may arrive in either order; play continues only when both OS flags clear, preserving an open slot menu and sound preference. Cold start loads the same native slot files (ADR 0014).

Clock foundation (ADR 0020): each simulation tick advances the 300s chapter clock first. Boundaries emit phase/dawn events exactly once; night is the final 90s and increments cn. A newly owned chapter resets to day 1 / 8% / night count 0; menu travel retains the clock. Snapshot/apply_state preserve optional day/time/cn after pad replay, with fresh defaults for old native saves and no duplicate dusk event on reload. Sunrise saves the active slot. The view applies v9 darkness and bounded player/counter/helper radial lights; the HUD shows the phase/night count. Night actors are connected; hearts/checkpoints are connected; combat is connected.

Native night flow (ADR 0021): first evening creates Gary once per slot; dusk starts 2/4/6 beats (+1 on subsequent real nights), and clock segments trigger 30s/60s beats without skipping boundaries. Night queues accrue patience at 3x. Nearby lost customers become zombies, sharing the ten-actor cap; daytime/far/capped departures retain the rating penalty. After helpers, actors follow A* routes and emit bite-windup/recovery events. Completed windups call `zombie_bite` directly; it applies one-heart damage, one-second immunity and arrived-item loss without touching the wallet; `hit_zombie` exposes HP, knockback/slow and cure payout for actual weapon projectiles. Sunrise wakes real actors as confused leaving customers before saving. Chapter entry clears threats while menu travel retains them. Optional `tut`/`night` save fields retain Gary, scheduler/actors/paths/timers and an exact decimal-string RNG state; restore never replays old beats.

Loss flow (ADR 0022): new game/chapter ownership captures a flat chapter baseline; dusk initializes its wave then freezes a dusk snapshot and saves it in the same slot envelope. Snapshot metadata includes health/immunity/faint, both backups, lifetime stats/wardrobe, arrived helper cargo and exact main RNG string. Legacy saves acquire backups after migration. A fatal hit saves a named loss and freezes future ticks. HUD retry chooses dusk or chapter baseline on every third night, merges current tutorial/stats/wardrobe, disposes old flyers, rebuilds all owned districts and settles checkpoint stock/cargo reservations once. Chapter retry resets day 1/.08/cn 0. Sound/settings stay in their own store. Cold reload retains the loss card; changing/deleting a different slot cannot change this slot’s backups. Sunrise is the only healing boundary; entering a chapter grants none.

Weapons (ADR 0023): HUD controls sample independent move/aim touches or keyboard/mouse and queue fire/tap/dash before World ticks. Dash timers apply bounded movement amplification and immunity; ordinary collision still runs. After helpers, weapon fire consumes one arrived carried product, spawns a cached-item projectile and starts cooldown. Swept collision finds the first actor crossed; primary/splash hits dispatch HP/knockback/cure hooks once before zombie movement/bites. Kills emit combo/pitched sound and short hit-stop. An owned gun gives the player an ammo use for crops/trays even with full production destinations; helpers retain demand-only pickup. Optional armory upgrades use ordinary progressive payments; the guide reserves earnings to meet base/upgrades deadlines. Saves retain gun/cooldowns and keyed payments; clear transient shots/input on world rebuild/travel, preserve spent ammo on normal reload, restore checkpoint ammo/upgrades on retry. Old array-only native saves restore economic pads across the new armory entries.
