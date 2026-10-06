# 2026-10-04 — Shooting and night research, fun research → v9 (aim, MOO FEVER, bosses, hats, prestige)

> **Imported** from claude.ai chat "Creating a game from an ad" (https://claude.ai/chat/645c8425-a2a0-41fb-9c03-2908bc0973e1, shared copy https://claude.ai/share/619469d2-2ba6-44c5-bf35-61d6c89a62d0). The work happened before this repo existed, and the times are the chat's real message times (local +03:00). The code lived in the claude.ai artifact https://claude.ai/artifact/YFNZ2jPt6E6tRczYqF74EY and is now `prototype/index.html`.

## What happened
- **The user said** "The shooting is not fun. Instead of just auto shoot you need to aim… night time is boring, make becoming a zombie a lot faster… their speed like 1.3 from my speed." This produced the research brief **`context/research/shooting-night-brief.md`**: a Brawl Stars-style aim stick, a 0.5–0.6 s bite windup, knockback, i-frames, a dash, and night turning in about 12 s.
- **The user said** "search web and suggest what more should i add… think about the fun part." This produced the research report **`context/research/fun-additions.md`**. Its verdict: feel over content, the 2-second loop rule, a juice pass, a MOO FEVER meter, readable joke zombies, bosses, secret characters, BREAKING MOOS events, a debate mini-game, and prestige.
- **The user said "Ok do it." This built v9** ("Version 9 · aim · fever · bosses · hats"):
  - **Aiming:** a right-half aim stick with hold-to-fire and tap for a quick shot, and the mouse on desktop. The aim line is yellow when locked and red when empty. Aim assist is ±14° and can be toggled. Classic auto-fire is kept as a setting.
  - **Hits:** a white flash, knockback, hit-stop, shake, and pitch-rising combos.
  - **Zombies:** 1.3× speed with acceleration, a 0.5 s bite windup with "!", a recovery after biting, and a **dash** (button, Space, or double-tap). Turning takes about 33 s by day and 11 s at night. Serving a customer whose ring is red saves them for a 1.5× tip.
  - **Zombie types:** Karen, Lactose-intolerant, Pole-vault, Influencer, and the Flag zombie.
  - **MOO FEVER:** 15 s of double coins and speed, with Ode to Joy. **BREAKING MOOS events:** UFO cow, goose thief, golden cow, granny race.
  - **Chapter bosses** on blood moons (Cornelius the Kaiju Cob, the Filibuster, …).
  - **A presidential debate quiz** in the Senator chapter. A **wardrobe** of 14 hats shared across slots.
  - **Retire to the Farm prestige** with Golden Udders.
  - Tests: 26/26 new, the chase tests, all old tests, and old saves (v5/6/8) loading. The full bot took about 80 minutes, which was too fast, so later chapter prices and the vote thresholds went up.

## Known untested (from the chat)
- The debate when the timer runs out.
- Whether MOO FEVER exactly doubles prices (the test only checks that sales happen).

## Open threads from the research, not yet built
- **Two-second loops**: shorten the walking. The big world (from v3) conflicts with this, which is the core tension.
- One-thumb mode. Secret characters, cow-breed album and farm decoration. Grandpa Bovine narrator and the rival Chad Cornwell. Share cards. Weekly mutators. Cow Cannon fast travel. The Tower of Babel stack.
