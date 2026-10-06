# Backlog

Active, actionable work. One bullet = one chunk you could pick up and finish in a session. **Cross items off and move them to `done.md` with the date in the same turn you finish them** — the backlog must reflect current reality.

## Now

_(Mid-flight or top-priority. Usually 1–3 items.)_

- [ ] **Godot chapter-1 slice (ADR 0005).** Create the `godot/` project (4.7.x, GDScript) and port Farm Kid faithfully: the world cells, corn field, cow barn, milk stand, coop and egg stand, the chapter-1 pads (feed, cap, more, unlock, helper, price), helpers, the gate, the code-drawn look (`_draw()`), touch joystick and keys, the camera, the HUD and saves (3 isolated slots). Includes `check.sh` with a headless Godot bot that plays chapter 1 to the gate, plus the tests "every counter sells unattended" and "save round-trip".
- [ ] **Android toolchain:** install JDK 17, the Android SDK and the Godot 4.7.2 export templates. Build a debug APK of the slice.
- [ ] **The fun core:** the 2-second loop versus the one big world. Decide with the user (`research/fun-additions.md`, item #2 is unbuilt). This stays separate from the port (ADR 0005, G1).
- [ ] Replace the placeholder icon mark in `scripts/generate-icons.js` when the brand exists, re-run it

## Next

_(Approved, ready to pick up, not started yet.)_

- [ ] Port the rest in verified steps after the slice: chapters 2–9, the harbor, vehicles, robbers, night and zombies (`findPath`/`NAV`), weapons, turrets, collectors, the fun layer (fever, events, bosses, hats, debate, prestige). Also the solid world boundary plus the unstick safety net
- [ ] Give the specialist agents (`.claude/agents/*.md`) a Godot section. They're written for `prototype/index.html` today
- [ ] Bundle the Baloo 2 font in the Godot project (offline)
- [ ] Godot tests for the two cases v9 never tested: the debate timer running out, and MOO FEVER exactly doubling prices (once those systems are ported)
- [ ] Decide on the old public artifact link (republish it from the repo or retire it)

## Later / stretch

_(Parking lot. Ideas, nice-to-haves, things you'd do if everything else were done.)_

- [ ] Research ideas not yet built (`research/`): one-thumb mode, a lunger zombie, safe zones, the dawn payout screen, secret characters, a cow-breed album, the Grandpa Bovine narrator and the rival Chad Cornwell, share cards, weekly mutators, Cow Cannon fast travel, the Tower of Babel stack
