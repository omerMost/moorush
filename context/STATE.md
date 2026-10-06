# STATE — current snapshot

**Rewritten (not appended to) at the end of every session.** Sessions are append-only history; ADRs are decision records; STATE is the snapshot of "what does this project actually look like right now."

If this is out of sync with the code, the code wins — but raise it as a bug, because keeping STATE current is part of the working discipline (see CLAUDE.md).

**Last updated:** 2026-10-06

---

## At a glance

**Working methods (ADRs 0002–0004, adopted 2026-10-07, taken from the friend's RareDrop project):** the AI builds and verifies everything (`check.sh`, bots, decision cards, playtest notes). Claude commits its own verified work and pushes `main` after every landing. Overnight runs leave a morning page.

**Moo Rush: Corn to Capitol** is a top-down tycoon game for touch screens and desktop. You start as a Farm Kid with a corn patch and three cows, and you climb through 9 chapters to President of the USA. Along the way: production chains, conveyors, hired helpers, vehicles, a harbor, robbers, day and night with customers who turn into zombies, aiming weapons, bosses, MOO FEVER and prestige.

- **The game is [`prototype/index.html`](../prototype/index.html):** version 9, one HTML file of 2,233 lines, plain canvas 2D, no libraries.
- It was built in a claude.ai chat from 2026-10-03 to 10-04 and imported on 2026-10-06. History is in `sessions/2026-10-03-*` and `2026-10-04-*`, and research in `research/`.
- **The repo copy is now the source of truth.** The public claude.ai artifact (https://claude.ai/artifact/YFNZ2jPt6E6tRczYqF74EY) is a frozen copy.
- The native app's engine isn't decided yet (backlog).

## Surfaces / components / modules

- **`prototype/index.html`** — the whole game. It's checked locally: it opens on the Version 9 menu with no console errors.
  - **World and content:**
    - `STAGES[]` (9 chapters, each with modules `mods` and upgrade pads `pads`) plus the `HARBOR` area.
    - Price multipliers `PM` and tuning `TUNE` per chapter.
    - `VEHICLES`, `GUNS`, and the collector cuts `CUTS`.
    - One world of 3×3-cell areas per chapter plus the lake, with fog that clears as you buy upgrades (`computeReveal`).
  - **Gameplay systems:** helpers, belts, trucks, robbers, zombies with pathfinding (`findPath`/`NAV`), day and night, weather, goals, events, bosses, fever, the debate, hats, and prestige (`retire`).
  - **Saves:** 3 slots in localStorage (`readSlot`/`writeSlot`, with migration from older versions), plus settings (`SET`). The cloud save through `window.claude` (db/user) only works inside claude.ai; it's skipped standalone.
  - **Test hook:** `window.__moo` (`S`, `player`, `mods`, `pads`, `input`, `update`, `travelTo`, `snapshot`/`applyState`, `findPath`, `spawnBoss`, `startEvent`, …). The chat's bots and feature tests used it, but they **were not saved**. Only the game was exported.

## Stack

- Prototype: vanilla JS, canvas 2D and Web Audio in one file. The Google font "Baloo 2" comes from a CDN, with a system-font fallback.
- Native app: **TBD** (backlog). Godot 4 is what the sibling project Blast Ranger chose (its ADR 0002).

## Known gaps (not bugs, just not done)

- **No tests in the repo.** The chat's bots and feature suites (15 + 30 + 26 tests, the full-career bot) existed only inside the chat sandbox.
- **The core fun problem is open:** the "2-second loop" versus the "one big world" (`research/fun-additions.md`).
- Untested: the debate when its timer runs out, and MOO FEVER exactly doubling prices.
- No native build, ads, analytics or store listing. The font loads from a CDN, so the game isn't fully offline.
