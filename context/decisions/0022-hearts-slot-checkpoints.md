# ADR 0022 — Hearts and slot-local retry checkpoints

**Status:** Provisional builder choices, pending Claude review (ADR 0015)
**Date:** 2026-10-07
**Supersedes:** None. Implements S2 of ADR 0018 after ADRs 0019–0021.

## Context

The user said "ok continue" after the proposed hearts/checkpoints step. Native zombie windups and per-slot night state already exist. Loss must restore the appropriate chapter/dusk backup while retaining tutorial progress, lifetime stats and preferences. Ordinary saves historically exclude pending item flights; a rollback must preserve checkpoint inventory without callbacks delivering twice.

## Decision

- Compose `sim/hearts.gd` with a typed weak owner. MooSim owns `checkpoints`, `faint`, `inv_t` and the public API; `S.hearts` starts at five. Completed real zombie windups call the damage hook directly; Gary never calls it. One accepted hit grants one second of immunity. Ordinary bites remove up to three arrived goods; Karen removes six. Neither changes the wallet. Pending reservations survive a bite.
- Sunrise refills hearts. Gate entry grants no extra healing. Retry restores checkpoint health (minimum one for a legacy zero-health baseline), clears immunity/faint and input, and rebuilds the owned world. Boss-night loss chooses `chapter_start`, ordinary loss chooses `dusk` with chapter baseline fallback. Chapter retry resets day/time/cn to 1/.08/0 and removes real-night actors while preserving the baseline threat RNG and any still-unfinished Gary practice actor. There are no boss actors yet; the existing every-third-night clock supplies this selection seam.
- Store two flat snapshots inside the active slot's existing JSON file. New game and first chapter ownership capture `chapter_start` after reveal/travel; first ownership clears the former chapter's dusk. Every real clock dusk captures after night count/initial wave initialization and saves immediately. Snapshots omit their own checkpoint bank and wall timestamp, preventing recursive growth. Travel, menu and ordinary reload do not capture checkpoints.
- Persist health/immunity/pending faint, tutorial, wardrobe array, arbitrary lifetime-stat dictionary, checkpoints and the main RNG decimal string. Preserve the separate saved threat RNG. Fresh state resets the main stream to the instance's seed; load restores its saved state after world rebuild. Old saves migrate completely before acquiring a chapter baseline; old mid-night saves also acquire a fallback dusk at their first loaded state. Old price-rescale migration remains intact. Chapter retry normalizes the legacy baseline's clock rather than restarting the old boss night.
- Rollback preserves all native save progression and district inventory. Checkpoint-only inventory capture counts reserved incoming goods and settles them once on restore, including sparse tray IDs and helper cargo. Dispose abandoned flight callbacks first. Ordinary saves keep ADR 0013's arrived-goods contract; their optional `helper_cargo` also retains arrived helper goods, route identity, state and rounded position. Canonical route/district/belt keys preserve helper cargo independently of purchase/replay order. Helper timers/walk and checkpoint floats use six decimals to avoid one-ULP JSON parser drift; live clock/night snapshots retain full precision. paths are replanned through existing A*. Production/queue timers still follow ordinary world rebuild semantics; this is a saved-state rollback, not an exact replay of every live frame.
- Retry overlays current `tut.*`, wardrobe and lifetime statistics onto the backup before applying it. This filters completed Gary out of old night actor snapshots. Settings and sound stay in their separate autoload/store. Native wardrobe has no purchase UI yet, but its optional metadata survives retry. Vehicles remain outside the current native slice.
- Zero hearts persists a pending faint and freezes simulation before future ticks. HUD shows five procedural hearts away from money/Grandpa/joystick and a "You fainted!" card whose Grandpa line names the attacker. An explicit retry button restores the backup. OS suspension blocks retry independently of menu pause. No automatic restore hides the loss card.
- Production/career regressions explicitly instantiate `MooEconomySim`, a test-only override that rejects damage. Real MooSim damage remains enabled and is exercised through actual windups, disk retry and rendered UI. Weapons are S3; these fixtures do not claim a surviving armed career or the required ten-seed fight bot. The determinism test pins both the new save fingerprint and the unchanged S1 economy projection.

## Alternatives rejected

- **Separate files for each checkpoint:** would multiply slot deletion/switch/migration responsibilities and permit mixing a slot's backups. One save envelope keeps ownership explicit and preserves existing isolation.
- **Use ordinary settled-goods snapshots unchanged for rollback:** would drop inventory that was already reserved or carried by a helper. A checkpoint settles its frozen reservations without rewriting the normal manual-save contract or live flight system.
- **Instant automatic respawn:** would hide the named-loss card. Freeze until explicit retry, retaining that state across cold reopen.
- **Temporarily disable damage in the shipped simulation to keep economy bots green:** would ship harmless bites again. Use a visibly named economy test fixture and separate real-game acceptance instead.

## Consequences

Five hearts and actual night loss are now native. Weapons, dash immunity, boss powers/actors, robbers and the full Grandpa tutorial remain later steps. The slot JSON grows by two bounded backups; Android checkpoint/save profiling remains required before device night acceptance. No APK/device verification is claimed in this landing.
