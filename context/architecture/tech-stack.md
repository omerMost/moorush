<!--
What this file answers: what did we pick for each layer of the project, and why.
When to update: any time a new dependency is locked in, swapped, or removed — same turn as the code change.
Example entry: "UI framework: Expo Router 7 — file-based routing, already Expo-blessed."
Seed this file during install (don't leave blank) — stack choices are usually known up-front. If you genuinely don't have an answer for a section yet, write "TBD" instead of deleting the section.
-->

# Tech stack

One section per layer. For each choice: what we picked + one-line rationale. Resist writing prose — this is a lookup table, not an essay.

## Runtime / language

- Prototype: vanilla JavaScript, one HTML file (`prototype/index.html`), no build step.
- Native app: **Godot 4.7.x + GDScript** in `godot/` (ADR 0005). Android first. Built as a chapter-1 slice first, keeping the code-drawn look (`_draw()`).
- The prototype is now a frozen **spec**. No new features go into it.

## UI / presentation layer

- Canvas 2D with hand-drawn sprites plus emoji. DOM overlays for the HUD, menu and modal. The font is Baloo 2 from Google Fonts.

## Data layer

- Content is JS object literals in the file: `STAGES`, `HARBOR`, `VEHICLES`, `GUNS`, and the `PM`/`TUNE` economy multipliers. There is no backend.

## Auth / storage / persistence

- Saves: localStorage, with 3 slots, settings, and migration from v1 and older versions. Cloud: `window.claude` db/user, inside claude.ai only.

## External integrations

- None yet.

## Tooling (build, test, lint, CI)

- Tests: **headless Godot bots** behind `check.sh` (ADR 0005, G4). Not built yet. There is no Playwright suite on the HTML.
- Prototype: test hook `window.__moo`. Local run: the `prototype` config in `.claude/launch.json` (port 8090).
- Android export: needs JDK 17, the Android SDK and the Godot 4.7.2 export templates. **Not installed yet.**

## What we deliberately did NOT pick

_(Things that were on the table and lost. Each entry: what it was, why it lost. Saves future-you from re-litigating.)_

- **Capacitor wrapping the HTML.** It's a web view with canvas performance limits (ADR 0005).
- **A Playwright suite on the HTML.** The tests live in Godot only (ADR 0005).
- **New sprite art during the port.** We keep the code-drawn look for now (ADR 0005).
