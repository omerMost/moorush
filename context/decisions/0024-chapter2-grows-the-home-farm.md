# ADR 0024 — Chapter 2 grows the home farm; one of each production type; a discovery moment for unlocks

**Status:** Accepted
**Date:** 2026-10-07
**Supersedes:** _(none)_. It narrows ADR 0009: the "no temporary focus" rule still applies to ordinary pads, but unlocks now get a scripted discovery moment. It answers the backlog's open card N2 for ch2. ADR 0010's three districts are kept.

## Context

The user: "i want to remove most of chapter 2 , its mostly repeted chapter 1 insted of reopening corn cow and chiken field make in chepter 2 the filed fro, chepter 1 bigger . and i want to organize the map, and also i want to add animation when new field is discover … there are too many fields type at the moment and it remove the game intrest from the fun part , also the water part are cool but also needs to orgenize".

Godot's ch2 duplicates ch1's corn field, barn, coop and egg stand. Only the Cheese press and Cheese shop are new.

## Decision

From cards G1–G6 (verbatim answers in `design/chapter2.md` §1):

- **Ch2's pads make ch1's farm bigger, and cheese is ch2's new product** (G1). Milk reaches the press from the ch1 barn (N2 = A).
- **One of each production type in the whole game, and at most two products per chapter** (G2).
- **A discovery moment for unlocks** (G3): the camera glides and zooms, Grandpa says what's new, and the camera glides back. It doesn't play for ordinary pads.
- **The Harbor becomes its own later chapter**, with fish → sushi only; pearls are cut (G4).
- **The map keeps the 3×3 grid** (G5). Ch2's block holds only its new things.
- **Shops appear when they're useful** (G6): bank and vehicle shop hidden in ch1–3; the armory appears at the first dusk.

## Alternatives considered

- **Ch2 with nothing new (cut cheese), or merging ch1 and ch2.** Offered on G1. That would lose The Big Cheese boss and shorten the game.
- **One product per chapter (cutting pies).** Offered on G2; the user kept up to two.
- **A road layout or a farm-in-the-middle layout.** Offered on G5; the user kept the grid.
- **Camera-free reveals, or reveals that don't take control.** Offered on G3.
- **A milk truck or a new ch2 chain** (N2 B and C). Not needed once the farm grows.

## Consequences

- **Pads and helpers can target another district's module.** Saves need a migration that maps or refunds old ch2 pads (`chapter2.md` §5). Tests prove that nobody loses value.
- **Ch2 gets shorter or cheaper.** The career bot re-measures ch2 and the Egg launcher affordability deadline (ADR 0023).
- **The discovery moment must not bring back the "glitch not nice to the eye"** that ADR 0009 fixed: the nav update runs before the glide, there's no shake, and frame time is checked.
- **Later chapters (4–9 and the Harbor) follow the one-of-each and two-products rules**, with a card per chapter when they're ported.
- **Bringing back a duplicate farm** or moving to a different map layout needs a new ADR.
