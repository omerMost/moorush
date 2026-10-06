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
- Native app: **TBD**. The options are a Godot 4 port (like Blast Ranger), Capacitor wrapping the HTML, or something else. It needs an ADR.

## UI / presentation layer

- Canvas 2D with hand-drawn sprites plus emoji. DOM overlays for the HUD, menu and modal. The font is Baloo 2 from Google Fonts.

## Data layer

- Content is JS object literals in the file: `STAGES`, `HARBOR`, `VEHICLES`, `GUNS`, and the `PM`/`TUNE` economy multipliers. There is no backend.

## Auth / storage / persistence

- Saves: localStorage, with 3 slots, settings, and migration from v1 and older versions. Cloud: `window.claude` db/user, inside claude.ai only.

## External integrations

- None yet.

## Tooling (build, test, lint, CI)

- Test hook `window.__moo`. **No test suite is committed yet** (backlog). Local run: the `prototype` config in `.claude/launch.json` (port 8090).

## What we deliberately did NOT pick

_(Things that were on the table and lost. Each entry: what it was, why it lost. Saves future-you from re-litigating.)_

- _(Nothing decided yet.)_
