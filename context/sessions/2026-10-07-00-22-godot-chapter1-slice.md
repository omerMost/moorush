# Godot chapter-1 slice (ADR 0005)

**What:** created `godot/` (Godot 4.7.2, GDScript) and ported Farm Kid from `prototype/index.html`.
- `scripts/sim.gd` (MooSim): pure-logic port of geometry, buildModule/buildWorld, applyPad, computeReveal, act(), counters/payInto/ground coins, machines, belts, helpers, guide arrow, walkable boundary + fog push-out + unstick safety net, NAV/findPath A*, snapshot/applyState, 3 slot files.
- `scripts/data.gd` STAGES[0] + PM/TUNE `nice()`; `paint.gd` canvas-style `_draw()` helpers; `world_view.gd` world + camera; `hud.gd` money/rank/toasts/joystick/slot menu; `moo.gd` autoload = test API (+ `--demo=S --shot=PATH`).
- `tests/` follow-the-arrow bot, counters-unattended, save-slots; `check.sh` at repo root.

**Provisional calls (mine):** no VIP/granny/critic customers, always daytime, lost customers storm off (no zombies); V/W/K cells drawn as "Coming soon" shops without pads; gate = "chapter complete" flag (no ch.2); NAV grid limited to district 0 + margin; no sound yet; helpers keep the prototype's single-destination rule (the destsFor "only pick up what's needed" rule is the player's, as in the spec).

## Checks
- `./check.sh` GREEN: boot clean; bot buys the gate at 430.9 s game time (7.2 min); Milk stand 1044 / Egg stand 1434 coins unattended in 300 s; 3-slot round-trip ok.
- Reference (qa-playtester on the HTML prototype, same bot): gate at 499–718 s, but it also bought 800 coins of out-of-scope shop pads and had events/night. Pad order matches.
- Windowed screenshot: `docs/screenshots/godot-ch1-t300.png`.

## Dialogue trace
- User: "port chapter 1 (Farm Kid) of the HTML prototype faithfully ... Don't redesign."

## Left
- Vault: STATE rewrite, architecture docs (tech-stack/system-design/data-flow) for godot/ — not done (usage limit).
- Sound, Baloo 2 font bundle, Android export.
