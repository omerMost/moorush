# ADR 0018 — Zombies with stakes: hearts, chapter restart, boss exams, and fewer systems in chapters 1–3

**Status:** Accepted
**Date:** 2026-10-07
**Supersedes:** _(none)_. It changes the v9 fun layer as the port's target. The HTML prototype stays the frozen behavior spec (ADR 0005), except where `context/design/fun-systems.md` overrides it.

## Context

The user opened a design session on the fun systems. Their verdict on v9:
- "i think some of them are just too much that the game loses it pointing";
- "i feel like the zombie part could get more intresting but the game is soo full of staff that its just there".

v9 throws about 12 systems at a player in the first ~13 minutes of chapter 1, and none of them can make you lose. A bite costs a few items. The ch1 boss dies in about 14 s.

Claude proposed making zombies more interesting through the shop (serve the zombie its order, day mistakes return at night, cured zombies become staff, defending the shop). The user rejected that: "i did not like your ideas … i think you need to be able to loose and start the chapter from your saving after, maybe you need to buy a weapon that will help you defet the zombies and the boss that have extended life and are hard to kill and the boss should actully have powers".

## Decision

From the user's cards F1–F11 (verbatim answers in `design/fun-systems.md` §1):

- **Hearts:** you lose when they run out (F1).
- **Where you go back to:**
  - a loss on a **boss night** → back to the **start of the chapter** (F2);
  - a loss on a normal night → back to **dusk** (F6).
- **Every night has zombies, and each night is harder** (F6).
- **The boss** is the chapter's final exam (F3). He comes every 3rd night (F5, F9) and has real powers. To leave a chapter, you **beat the boss AND buy the gate** (F10).
- **A new weapon each chapter** (F4), with ammo taken from your carried stack (F7). Zombies and bosses get much more HP.
- **Chapters 1–3 keep only robbers** among the side systems (F8), and robbers are daytime only (F11).
  - Out of ch1–3: BREAKING MOOS events, MOO FEVER, weather, daily goals.
  - *Provisional* (Claude): turrets, floodlights, guard dog, pocket overflow and collectors, and hats also wait.

The numeric spec and the test list are in `design/fun-systems.md` §3 and §5.

## Alternatives considered

- **Port v9 as is.** It's the "too much" the user described, with zombies that are "just there".
- **Shop-centred zombie ideas (Claude's Z1–Z5).** Rejected by the user.
- **A softer restart (back to dusk or sunrise even on a boss loss).** Offered on F2; the user chose the chapter start.
- **The player triggers the boss night when ready.** Offered on F5 (Claude's recommendation); the user chose a fixed every-3rd-night rhythm.

## Consequences

- **Saves gain two checkpoints per slot** (`chapter_start`, `dusk`), and a restore that keeps settings, wardrobe and tutorial flags. Slot isolation and the price-rescale migration rule still apply.
- **A boss loss can cost up to about 35 minutes** in ch2 or ch3 (career-bot pace). Fight tuning must be proven with bots (`fun-systems.md` §5) so that losses feel fair. The first playtest should ask about this directly.
- **Ch1 pacing conflict:** the gate is affordable at about 7.4 min, but the first boss night is at about 13.1 min. This needs a card after measurement.
- **MOO FEVER, events, weather and goals stop being port targets for ch1–3.** The v9 tests for them (the debate timeout, fever exactly doubling prices) move to whenever those systems come back.
- **The tutorial's Gary and the armory arrow** (ADR 0016) fit as is: ch1 night 1 is Gary only, and the Milk squirter stays at 100.
- **Reversing any of these** (a no-fail mode, bringing fever back early, softening the restart) needs a new ADR.
