# ADR 0019 — Split MooSim with composed systems and a stable facade

**Status:** Provisional builder choice, verified locally; pending Claude review (ADR 0015)
**Date:** 2026-10-07
**Supersedes:** None; preserves ADRs 0006, 0009, 0010 and 0013.

## Context

The native simulation was 1,614 lines in one RefCounted class. S1–S8 night/combat work would expand it substantially. S0 must preserve gameplay, numbers, RNG order, saves and every existing public member/static helper without adapting callers or tests.

## Decision

Keep `class_name MooSim`, constants, all mutable state, RNG, static utilities, input and the unchanged `update()` sequence in `godot/scripts/sim.gd`. Compose seven RefCounted systems in `godot/scripts/sim/`: world (construction/pads/reveal/belts), items (transfers/player actions), customers (queues/counters/payments), agents (machines/helpers/guide), nav (scenery/collision/grid/A*/walking), saves (snapshot/migrations/slots/travel) and feedback (toasts/speech/ground coins).

Each system exposes a typed `MooSim` owner getter backed by WeakRef. MooSim owns the components strongly; the weak reverse edge avoids a RefCounted ownership cycle. Existing `dispose()` still clears in-flight callbacks. Components are constructed before `fresh_state()` and their constructors consume no RNG or change state.

MooSim forwards every moved method with its original signature, defaults and return type; moved static helpers forward to the component script. Bodies retain their statements and execution order, qualifying state/instance-method calls through the owner and shared constants/static utilities through MooSim. Instance-method calls, including those within a system, go through MooSim so existing subclass overrides still dispatch (the CountingSim route regression exercises this). Static calls within a system stay local. Navigation, incremental masks, destination-aware pickup, migration and tray slots are moved without algorithm changes. Renderer caches are untouched.

Future clock, zombies, combat, hearts, bosses and robbers use the same component seam, with explicit tick calls in MooSim rather than implicit system scheduling. S0 adds none of those systems. No simulation file exceeds 450 lines.

## Alternative rejected

An `extends` chain could expose inherited state without owner qualification, but a base GDScript cannot call methods defined only by a subclass. This simulation has mutual dependencies (world/reveal/navigation, actions/saves/travel, agents/items/customers). Stubs and overrides would conceal those dependencies and force an artificial inheritance order. Composition makes those calls explicit while preserving the public facade.

## Verification and consequences

The new fixed-seed test uses MooBot at 30 Hz for exactly 36,000 ticks. It hashes JSON of the snapshot after setting its wall-clock metadata `t` to zero **in the test only**; production save format and timestamps remain unchanged. Pre-split hash at `0f1cb8f`: `1337840505`, money 338, 19 bought pads, T 1200.0. Post-split must match.

Existing tests remain unchanged. Full checks, original career times (444.6s / 1,963.5s / 4,932.2s including the final 300s unattended phase), a rendered chapter-1 run and token comparison of all 105 non-constructor method signatures/bodies validate the move. This is no claim about Android performance; device performance work remains separate.
