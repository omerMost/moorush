# Done

Append-only log of completed backlog items. Newest at the top. Date format: `YYYY-MM-DD`.

When you complete a backlog item, move its bullet from `backlog.md` to here in the same turn — prepend the completion date and (optionally) a one-line note on what shipped.

---

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
