# ADR 0017 — Character art direction: a code-drawn cast with brow faces

**Status:** Accepted
**Date:** 2026-10-07
**Supersedes:** _(none)_. It keeps ADR 0005 G2 (the code-drawn look) and narrows it for characters.

## Context

The user asked for a character-design session ("another one for charchter design"). Their standing direction: "THE GAME SHOULD BE FUNNIER" and "I am not looking to copy the ad". Today every person is the same `drawPerson` body with dot eyes. The joke zombies differ by small props that disappear at phone size. Bosses are a dark blob with an emoji in it. The story characters (Grandpa Bovine, Chad Cornwell) were never drawn.

## Decision

The user picked from rendered option sheets (cards D1–D8 and Z1, verbatim in `design/characters.md`):
- **Stay code-drawn.** Every character is built from the prototype primitives on the `drawPerson` body plus a few proportion knobs (`bodyW`, `bodyH`, `legH`, `headR`, `neck`, `lean`). There are no sprite files; ADR 0005 G2 stands.
- **Faces:** dot eyes, brows and blush for every human (D1 C). The brows carry the acting (moods).
- **Zombies:** a "Grumpy" face (eye bags, red pupils, angry brows, buck teeth) and a torn hem (Z1 A). Each joke zombie gets its own **body shape** plus a bigger prop (D5 B).
- **Identity comes from the silhouette, not the face.** Each character needs one signature shape that breaks the outline by at least 6 px at 1×.
- The specs (colours, proportions, primitives, beats) live in `design/characters.md`. The reference PNGs and their generator are in `docs/design/characters/`.

## Alternatives considered

- **Googly eyes (D1 A).** Sillier, but the user chose brows.
- **Sprite art now (ADR 0005 G2-B).** Too slow. It would also drop the drawing knobs that make growth and joke-zombie shapes cheap.
- **Props only for joke zombies (D5 A)** or **colour rings (D5 C).** Props alone don't survive phone size, and rings add clutter.

## Consequences

- `paint.gd` needs a parameterised person drawer (the knobs above), face moods and per-type zombie bodies. Bake each costume/body variant once into cached textures (ADR 0006); don't redraw primitives every frame.
- The player's draw scale grows from 0.88 to 1.22 across chapters, but the hitbox does not. Tests must not assume the drawing size equals the collision size.
- Moving to sprite or illustrated art later needs a new ADR superseding this one and ADR 0005 G2.
