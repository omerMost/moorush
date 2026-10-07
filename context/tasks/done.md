# Done

Append-only log of completed backlog items. Newest at the top. Date format: `YYYY-MM-DD`.

When you complete a backlog item, move its bullet from `backlog.md` to here in the same turn — prepend the completion date and (optionally) a one-line note on what shipped.

---

- 2026-10-07 — Claude/Codex coordination decided: Codex builds, Claude reviews (ADR 0015, card C1).
- 2026-10-07 — Soak collector validity: OS pause markers reject brief interruptions between foreground checkpoints; functional CLI checks cover stable samples, hidden suspension, transient USB recovery and changed process. Interrupted phone runs recorded without claiming sustained acceptance.

- 2026-10-07 — Explicit app suspension and local lifecycle regression: idempotent save, frozen background simulation, cleared movement/touch/audio, both resume orders and preserved menu. Read-only bounded Android soak collector added; 22 lifecycle assertions and eleven suites pass. POCO Home/cold-reopen/app-switch checks preserve progress; lock/wake and uninterrupted soak remain in backlog.

- 2026-10-07 — Spatial pickup and Toss: nearest ripe/exposed goods, stable tray holes and compatible saved slot positions; incoming-safe carried transfers, eased bin-mouth Toss. Android 0.3.4 and regression coverage.

- 2026-10-07 — Cheese C1: user chose C, cut wheel. Integrated exact native preview shape into the baked cache, matched display spacing, verified natural dairy stock/store/carry and full checks, installed 0.3.3.

- 2026-10-07 — Item-holder follow-up: shallow light wooden crates; public tray clearance and safe customer spawn/lost-exit points while pickup stays available. Route/full-game checks pass, Android 0.3.2 installed; cheese designs await user choice C1.

- 2026-10-07 — Android visual/world patch: clearer cached cheese wedge; restored solid seeded map trees/ponds; customers route around crop beds while harvesting remains available. Nine suites plus rendered scenery/dairy review pass; 0.3.1 installed, subjective retest pending.

- 2026-10-07 — Daytime Baker/Chapter 3 port: wheat→bread, apples→pies, helpers/conveyors and 12 new pads; three persistent districts/34 pads, older endpoint migration, cached products and unlocked travel. Eight suites and natural rendered bakery test pass; Android 0.3.0 installed, subjective phone feedback pending.

- 2026-10-07 — User confirms Android 0.2.1 resolves the reported upgrade completion glitch: "yes" after retest prompt.

- 2026-10-07 — Upgrade completion patch: remove screen shake/temporary focus, refresh navigation only for changed geometry; all 22 incremental masks match full rebuilds, both bots pass, Android 0.2.1 installed. User visual comparison remains in device playtest.

- 2026-10-07 — Daytime Farmer/Chapter 2 port: corn→milk→cheese, eggs, helpers, 12 new pads and bakery completion gate; two persistent districts/travel and old farm-save migration. Six suites and rendered dairy/farm tests pass, 0.2.0 installed; Chapter 2 phone gameplay feedback and night taco content remain queued.

- 2026-10-07 — Android 0.1.3 audible sound confirmed by user: "yes now i can hear it" after Test sound prompt. Manual mute and gameplay cue coverage remain in device playtest.

- 2026-10-07 — Chapter 1 sound and offline font: prototype harvest/drop/coin/warn/upgrade/gate tones, bounded cached playback and persistent mute; bundled Baloo 2 weight 800 with OFL license. Audio/UI/font tests added; phone listening check remains queued.

- 2026-10-07 — Android close/reopen save verification: user confirms "yes it saves" after force-stop and cold launch on POCO. Background/suspend lifecycle remains separately pending.

- 2026-10-07 — Android smoothness validation: user says "yes much better" after v0.1.1; four five-second engine frame windows report 78.4–99.9 FPS on connected POCO. Long sustained performance and suspend/resume remain separate checks.

- 2026-10-07 — Local native playtest and reusable windowed career smoke test: real scene/guide movement to gate (421.7s), rendered milestone captures; native New Game/menu/Resume checked and all four headless suites green. Direct UI keyboard/drag movement remains unconfirmed through automation.

- 2026-10-07 — Landed existing Godot Chapter 1 slice: Farm Kid production/pads/helpers/gate, code-drawn view, touch/keys and 3 slots. Gate bot 430.9s; unattended counters pass. Completed previously owed STATE and architecture updates.
- 2026-10-07 — Built and signature-verified native Chapter 1 debug APK (com.omer.moorush, 0.1.0, arm64, SDK 24/36). Added preset, placeholder icon generation and logical phone HUD scaling. Device playtest remains separately queued.

- 2026-10-07 — Android toolchain: JDK 17 (brew openjdk@17), SDK in `~/Library/Android/sdk` (cmdline-tools 15859902, platform-tools 37.0.1, build-tools 36.1.0, android-36), Godot 4.7.2 Android export templates (SHA-512 checked), a debug keystore and the editor settings. Proven with a scratch probe project: a signed debug APK that `aapt dump badging` reads. `godot/` wasn't on `main` yet, so the slice APK moved to the backlog item "Slice APK".
- 2026-10-07 — Engine decided: Godot 4 + GDScript, Android first, chapter-1 slice first, code-drawn look, tests in Godot only (ADR 0005, cards G1–G4).
- 2026-10-07 — Dropped "rebuild the test suite on the HTML": the tests move to headless Godot (ADR 0005, G4).
- 2026-10-06 — Imported the game (v9) from the claude.ai artifact into `prototype/index.html`, plus the chat history (4 sessions) and the research (2 docs). Checked locally: the menu loads at Version 9 with no console errors.

- 2026-10-07 — Tutorial designed with the user (cards T1–T10): `design/tutorial.md`, ADR 0016. Grandpa Bovine soft beats, commentary, Gary the practice zombie, `tut` save key and a headless test plan. Build items queued for Codex.

- [x] **2026-10-07 — Split `godot/scripts/sim.gd` by system before porting night and zombies (S0).** Seven composed systems and stable MooSim facade (ADR 0019); fixed-seed snapshot hash and original career times preserved, full checks and rendered Chapter 1 pass. No gameplay/save/RNG change.

- [x] **2026-10-07 — S1 chapter clock/day-night foundation (ADR 0020).** 300s v9 phases/darkness, 90s nights, per-chapter counter and third-night hooks, slot-isolated persistence/migration, bounded native radial lighting and HUD clock. Clock and rendered pixel checks pass; original economy fingerprint and career times preserved. Full Clock + night item remains open for waves, turning and Gary.

- [x] **2026-10-07 — S1 native night actors (ADR 0021).** Escalating 2/4/6 waves (+1/night), shared cap 10, nearby night-only customer turning/3x patience, safe rotating A* chase and unstick, sunrise conversion, persisted actors/scheduler/RNG, and Gary's wait/flag/timeout/hit/guide seams. Normal HP and bite/cure hooks ready for hearts/weapons. Player firing, damaging bites, Grandpa narration, full character art and phone acceptance remain queued.
