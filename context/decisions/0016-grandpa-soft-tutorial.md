# ADR 0016 — A soft tutorial narrated by Grandpa Bovine

**Status:** Accepted
**Date:** 2026-10-07
**Supersedes:** _(none)_. It replaces the chapter intro toast (`STAGES[i].intro`, shown for 5 s in `moo.gd`) as the way the game introduces itself.

## Context

The user asked: "i want to create a session for the tutorial". Their standing direction is "THE GAME SHOULD BE FUNNIER".

Today the Godot port teaches with:
- a 22-word intro toast;
- the guide arrow;
- short warnings.

The prototype also had a 25-word gun-aim toast. There was no narrator, and `research/fun-additions.md` lists Grandpa Bovine as an unbuilt story idea. The arrow bot reaches its first sale at 15.1 s and the first pad at 35.1 s, and the player is moving 94% of the time. The loop is already fast, so the tutorial must ride on it.

## Decision

The user's cards (verbatim in `design/tutorial.md` §1):
- **Narrator:** Grandpa Bovine (T1 A).
- **Soft beats:** only in the opening of chapter 1 (T2: "just part of part 1 soft bets"), ending at the first paid pad (T5 A). They never lock anything and complete out of order.
- **No skip** (T3: "its a soft one easy to follow so no skip").
- **Stuck help is the arrow only** (T4 B): no nags, no ghost hand.
- **After the beats:** constant commentary (T6 C), with no toggle (T10 B), held in check by cooldowns.
- **Bubbles never pause the game** (T7 A), and they're 12 words max.
- **First night:** a practice zombie, "Gary" (T8 A). Without a gun, the arrow sends the player to the armory first (T9 C).

The spec, numbers and test plan are in `context/design/tutorial.md`.

## Alternatives considered

- **Hard-rail tutorial** (T2 B): it locks everything except the current step. Safe, but it feels like homework, and it fights the fast loop.
- **No narrator, arrow and toasts only** (T1 C, T2 C): cheap, but not funny.
- **Skip button / "First time on a farm?" prompt** (T3 A/B): unneeded for a 45-second soft opening.
- **Escalating hint ladder or Grandpa-does-it** (T4 A/C): rejected by the user in favor of the arrow alone.
- **One-time cameos only, or a quiet toggle** (T6 A, T10 A): the user wants Grandpa always talking. Cooldowns (§2 of the design) are the only limiter.
- **Grandpa lends the gun** (T9 A): it would change the chapter-1 economy by 100 coins.

## Consequences

- New per-slot save key `tut`. Old saves are treated as finished. They get one hello line and skip first-time lines for things they already own (*provisional*).
- The sim must emit gameplay events (`ev_*`) that a separate `tutorial.gd` consumes. This fits the planned `sim.gd` split.
- Every future ported mechanic owes its Grandpa lines (first-time plus commentary, 12 words max) in the same task.
- Grandpa's look and voice come from the character session (`design/characters.md`).
- Adding a skip/replay, a quiet toggle, or a hint ladder later needs a new card, and an ADR if it reverses this one.
