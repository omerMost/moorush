# 2026-10-07 — Walked through the game and folder; chose Godot (ADR 0005)

- The Root Orchestrator went over `prototype/index.html` (v9, 2,233 lines). The section map:
  - content: L103–370;
  - world geometry: L371;
  - state and modules: L427;
  - core loop: L594–720;
  - input and pathing: L719–950;
  - robbers, night and zombies: L950–1295;
  - fun layer: L1295–1540;
  - drawing: L1540–2050;
  - sound, saves, menu and cheats: L2050+.
- It also went over the repo and the toolchain:
  - Godot 4.7.2 is at `/opt/homebrew/bin/godot`.
  - Missing: the export templates, JDK and Android SDK.
  - The specialist agents' briefs still only cover the HTML.
- Decision cards G1–G4 were answered, all with the recommended option. **ADR 0005** records them:
  - Godot 4 + GDScript in `godot/`;
  - a chapter-1 slice first;
  - the code-drawn look kept;
  - Android first;
  - tests in Godot only, with the HTML as a frozen spec.
- Backlog changes:
  - The engine decision and the HTML test-suite item moved to done.
  - New Now items: the Godot chapter-1 slice (with `check.sh`, a headless bot, and the unattended-selling and save round-trip tests), and the Android toolchain.
  - New Next items: port the rest, give the agents a Godot section, bundle the font.
- Also updated: `tech-stack.md` and STATE.

## Checks
- Docs only. No code changed, so there was nothing to run.

## Dialogue trace
- User: "ok this is the root orchestrator , i want to build the game using godot go over the game and the folder"
- Claude: gave the overview, then asked cards G1 (staging), G2 (look), G3 (platform) and G4 (tests).
- User: G1 "Chapter-1 slice first", G2 "Keep the code-drawn look", G3 "Android first", G4 "Tests in Godot only". All were the recommended options.
