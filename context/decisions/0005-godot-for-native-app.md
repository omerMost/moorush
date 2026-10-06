# ADR 0005 — Godot 4 for the native app (Android first, chapter-1 slice first)

**Status:** Accepted
**Date:** 2026-10-07
**Supersedes:** _(none)_. Settles the backlog item "Decide the native-app engine". It also changes how ADR 0002's "the AI builds and verifies everything" is carried out: `check.sh` runs headless Godot bots, not Playwright on the HTML.

## Context

Moo Rush exists as a 2,233-line single-file HTML5 canvas prototype (v9). The game needs to become a native mobile app. Godot 4.7.2 is already installed on the dev Mac. The sibling project Blast Ranger chose Godot 4 (its ADR 0002), and so did the friend's RareDrop.

The user said: "i want to build the game using godot". Then, on the decision cards G1–G4, they picked the recommended option every time.

## Decision

- **Engine:** port the game to **Godot 4 (4.7.x) with GDScript** in `godot/`.
- **G1, staging:** a **chapter-1 vertical slice first**. That means Farm Kid: corn → cows → milk stand, the pads, helpers, the gate and saves. It's ported faithfully and proven with a headless bot. Then the other chapters and systems are added in small verified steps.
- **G2, look:** keep the **code-drawn look**. The prototype's procedural canvas drawing and emoji are re-created with `_draw()`. An art upgrade comes later.
- **G3, platform:** **Android first.** That needs JDK 17, the Android SDK and the Godot export templates. iOS comes later.
- **G4, tests:** **tests in Godot only.** `check.sh` runs `godot --headless` bots and feature tests. The HTML prototype is a frozen **spec**: no new features and no Playwright suite.

## Alternatives considered

- **Capacitor wrapping the HTML.** It's the fastest way to ship, but it's a web view, with canvas performance limits on low-end Android and no editor.
- **Full 1:1 port before playing on a phone (G1-B).** Nothing would be verifiable for a long time.
- **Port and redesign the fun core together (G1-C).** That mixes two risks. The "2-second loop" decision stays a separate backlog item.
- **New sprite art now (G2-B) or gray boxes (G2-C).** Too slow, or they lose the prototype's charm.
- **A Playwright suite on the HTML too (G4-B).** Rejected so we don't maintain two codebases' tests.

## Consequences

- Around 2.2k lines of JS logic get rewritten in GDScript. The hard-won fixes have to be carried over on purpose: `findPath`/`NAV` pathfinding, the solid world boundary plus the unstick safety net, helpers picking up only what something needs, isolated save slots, and migrations that keep finished upgrades after a price rescale.
- The specialist agents are written for `prototype/index.html`. Their briefs need a Godot section (backlog).
- The toolchain must be installed before the first APK build.
- Switching engines again would need a new ADR.
