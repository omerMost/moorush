# STATE — current snapshot

**Rewritten (not appended to) at the end of every session.** Sessions are append-only history; ADRs are decision records; STATE is the snapshot of "what does this project actually look like right now."

If this is out of sync with the code, the code wins — but raise it as a bug, because keeping STATE current is part of the working discipline (see CLAUDE.md).

**Last updated:** 2026-10-07

---

## At a glance

**Working methods (ADRs 0002–0004, adopted 2026-10-07, taken from the friend's RareDrop project):** the AI builds and verifies everything (`check.sh`, bots, decision cards, playtest notes). The root AI (Claude or Codex) commits its own verified work and pushes `main` after every landing. Overnight runs leave a morning page.

**Moo Rush: Corn to Capitol** is a top-down tycoon game for touch screens and desktop. You start as a Farm Kid with a corn patch and three cows, and you climb through 9 chapters to President of the USA. Along the way: production chains, conveyors, hired helpers, vehicles, a harbor, robbers, day and night with customers who turn into zombies, aiming weapons, bosses, MOO FEVER and prestige.

- **The game is [`prototype/index.html`](../prototype/index.html):** version 9, one HTML file of 2,233 lines, plain canvas 2D, no libraries.
- It was built in a claude.ai chat from 2026-10-03 to 10-04 and imported on 2026-10-06. History is in `sessions/2026-10-03-*` and `2026-10-04-*`, and research in `research/`.
- **The repo copy is now the source of truth.** The public claude.ai artifact (https://claude.ai/artifact/YFNZ2jPt6E6tRczYqF74EY) is a frozen copy.
- **Native app: Godot 4 + GDScript in `godot/`, Android first (ADR 0005).**
  - We start with a chapter-1 (Farm Kid) slice, now extended through daytime Farmer and Baker that keeps the code-drawn look, and `check.sh` runs headless Godot bots.
  - The HTML prototype is now a frozen spec.
  - `godot/` is playable: Farm Kid, daytime Farmer and Baker production (corn/milk/cheese/eggs/wheat/bread/apples/pies), 34 pads, three persistent districts, helpers, fog/bounds, code-drawn world, camera, HUD, touch/keys, district travel and 3 isolated save slots.
  - Signed debug APK: `build/moorush-debug.apk` (`com.omer.moorush`, 0.3.3, arm64, minSdk 24, targetSdk 36). Installed and launched on the user’s connected POCO device (model 2412DPC0AG); Vulkan/Mali-G720 startup succeeds. User confirms improved smoothness, working sound effects and progress restored after force-stop/cold reopen on the prior build. Old completed Chapter 1/2 saves open Farmer/Baker. Before this update the actual phone save contains 1,589 coins, capacity 14 and unfinished Farmer progression; loading with Baker available preserves wallet, capacity, all prior payments and stable inventories. 0.3.0 resumed that phone save with 34 payment entries and the existing sound OFF preference; initial five-second engine window is 72.6 FPS, p95 14.35ms and draw CPU 8.28ms. Chapters 2–3 phone gameplay feedback pending. Background/suspend lifecycle, full layout review and sustained performance remain pending.

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
- Native app: **Godot 4.7.2** (installed at `/opt/homebrew/bin/godot`), GDScript, Android first (ADR 0005).
- **Android export toolchain: installed and proven** (2026-10-07). JDK 17 (brew `openjdk@17`), the SDK in `~/Library/Android/sdk` (build-tools 36.1.0, android-36, platform-tools), the Godot 4.7.2 Android templates, a debug keystore and the editor settings. A probe project exported a signed debug APK headless (minSdk 24, targetSdk 36). The exact recipe is in `architecture/tech-stack.md`. No NDK; the Gradle build isn't used.

## Known gaps (not bugs, just not done)

- `./check.sh` imports/boots Godot and runs the Chapter 1 gate bot (~417 simulated seconds), Chapter 2 bot (bakery gate), full three-chapter bot (supermarket gate at 4,521.6s), unattended counters, populated three-district save round-trips and older slice migrations, audio waveform/mute/persistence checks and touch HUD/font checks at 1080×1920 and 1440×2560. Process failures and engine errors fail the checks.
- Local rendered test: `godot --path godot -s res://tests/test_windowed_chapter1.gd`; milestone screenshots under `build/`. Native New Game/menu/Resume were exercised via desktop UI; brief keyboard/drag automation did not visibly confirm movement (headless touch/input checks pass).
- Android smoothness improvement (ADR 0006): input sampled before simulation, cached procedural item textures/curves/text and batched grass; debug Android frame timing logs every 5s while playing. Local draw CPU mean 21.083→8.315ms; user confirms "yes much better"; four five-second Android engine windows report 78.4–99.9 FPS (frame p95 10.42–13.33ms). User confirms close/reopen saves; longer 0.1.1 logs drift from ~97 to ~43 FPS over ~8 minutes, with draw CPU increasing; heat versus scene load is not isolated. Sustained performance and background/suspend lifecycle checks remain pending.
- **The core fun problem is open:** the "2-second loop" versus the "one big world" (`research/fun-additions.md`).
- Untested: the debate when its timer runs out, and MOO FEVER exactly doubling prices.
- Slice exclusions remain provisional: always daytime, no zombies/special customers, shops marked coming soon, Farmer night taco stand/pads deferred, supermarket gate marks completion until Chapter 4. Baloo 2 weight 800 is bundled offline with OFL license; emoji use OS fallback. Chapter 1 sound cues are synthesized once and played from a bounded pool, with a persistent menu toggle; user confirms audible phone output in 0.1.3: "yes now i can hear it" after the Test sound prompt. Dark explicit ON/OFF control, Test sound celebration and +6dB voice gain are installed. Device taps persist mute correctly; manual muted listening remains pending; user reports "looks smooth and sound effect works continue".
- All three districts and their inventories/upgrades persist across travel and saves (ADR 0010, provisional). Native saves retain the prototype's omission of in-flight goods and helper cargo. Full legacy HTML save import is not implemented; current Godot slots are tested. No ads, analytics or store listing.

- Chapter 2 rendered bot verified natural cheese in press/store/held stacks and menu travel. Nine headless suites GREEN; tests use isolated save directories to avoid parallel-run collisions.

- Upgrade completion patch (ADR 0009): removes upgrade shake/temporary focus and updates only changed navigation cells. Ordinary local completion ~0.1–20ms versus ~69–110ms full-grid baseline. Full-mask equivalence passes for all 34 upgrades/reset/migration; user confirms the reported upgrade glitch is gone on 0.2.1 ("yes" after retest prompt).

- Baker adds wheat→bread and apples→pies, four cached item textures and three-button unlocked travel. Natural bots buy all 34 pads with earned money, verify four conveyors/13 local helpers and six counters selling unattended. Rendered bread/pie/fields/menu reviewed; Chapter 3 subjective Android feedback remains pending.

- Android visual patch (ADR 0011, provisional): restored deterministic map trees/ponds with solid collisions, depth-sorted trees, user-selected cached cut-wheel cheese, and cached customer paths that exclude crop beds and item holders. Player/helper harvesting stays enabled. Customer queue/departure, scenery collision/determinism and both incremental masks are checked; 0.3.1 is installed and resumed on POCO; saved slot and sound OFF preference were identical across install. Subjective phone retest pending.

- Tray follow-up (ADR 0012): light wood output crates replace dark trays; public traffic excludes active trays with a 25-unit margin and uses safe entry/exit points. Real holder-route/pickup tests extend the existing suite. 0.3.3 is installed and resumed on POCO, preserving wallet/capacity/prior payments and audio preference. User chose C1 option C, the cut wheel: cached production sprite and 24×17 stock spacing now match that preview. Carried spacing and pickup regions retain their behavior.
