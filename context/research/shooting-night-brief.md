# Research: shooting and night redesign (2026-10-04, condensed)

> This is a condensed version of the brief produced in the claude.ai chat (msg 31). The full text with all its citations is in that chat. The numbers are **starting points to tune in playtests**, drawn from comparable games, fan wikis and practitioner write-ups. They are not standards. Mark what v9 implemented as ✅.

## Shooting
- **The problem:** auto-fire while moving means the player makes no decision. Archero gets away with it only because firing is tied to standing still.
- **The fix:** a Brawl Stars-style right-half aim stick: drag to aim, hold to fire, tap for an auto-aimed quick shot, drag back to the centre to cancel. ✅ (hold-to-fire, quick shot)
- **Aim assist** (from Relic Hunters):
  - a narrow ±12–15° cone, checked after projecting the input toward the target;
  - an instant snap plus an aim-line tint;
  - toggleable, on by default for touch and off for mouse. ✅ (±14°, toggle)
  - Also: interpolate the aim at about 720°/s, and use sticky aim at ×0.4 while the aim line is on a zombie.
- **Stick numbers:**
  - radius about 11–13% of the screen's short side;
  - a radial dead zone of 10–15% for moving, and 18–20% (plus a 200 ms limit) for telling a tap from an aim.
- **Firing:**
  - projectiles at least 4–5× the walk speed;
  - range about 45–55% of the screen's short side;
  - a basic zombie dies in 3–4 hits.
- **Juice:**
  - hit-stop 30–40 ms per hit, 60–80 ms per kill, capped at 120 ms;
  - shake 4 px on a hit, 8 px on a multi-kill, 12 px when bitten, decaying over 0.2–0.3 s;
  - a 60–80 ms white flash;
  - combo pitch rising a semitone per step;
  - all of it toggleable. ✅ (flash, knockback, hit-stop, shake, combo)
- **Input layer:** Pointer Events, tracking each finger by `pointerId`, with `setPointerCapture` and `touch-action:none`. Desktop is WASD plus a mouse reticle.

## Zombies at 1.3× the player's speed (the counterplay that makes it fair)
- **Speed:** reach top speed over 0.6–0.8 s, and turn at most 180°/s.
- **The bite:** a 0.5–0.6 s windup with a "!"; the bite only lands if you're still in range; afterwards the zombie stands still for 0.8–1.0 s. ✅
- **When shot:** knockback of 0.4–0.6 body lengths over 120–150 ms, plus speed ×0.5 for 0.4 s. Big zombies resist knockback, and bosses are immune.
- **The player:**
  - 0.7–1.0 s of i-frames after a bite;
  - a **dash**: 2.5× speed for 0.18 s with i-frames, on a 2.5 s cooldown. ✅
- **Not built yet:**
  - a lunger variant;
  - chase leash after 8–10 s;
  - lit safe zones;
  - horde caps per night beat (2–3 → 4–5 → 6–8, max about 10 on phones).
- **For scale:** Left 4 Dead's common zombies are only about 14% faster than a healthy survivor, and you can shove them.

## Turning into a zombie and the night
- **Turning in two phases:** patience (25 s by day, 6 s at night), then turning with a red ring and a cure window (8 s by day, 5 s at night), then rising (1 s). Serving during the turn saves them for a ×1.5 tip. ✅ (about 33 s by day and 11 s at night, plus the save tip)
- **The night:**
  - 2–2.5 minutes long;
  - a dusk warning;
  - three escalating beats, ending in a "Blood Moon minute";
  - a **dawn payout** worth more than staying idle (the Dying Light: The Beast lesson).
  - *(Partly built: blood moons and bosses exist. The dawn payout screen and the night beats aren't checked.)*
- **Accessibility settings:**
  - aim assist Off / Light / Standard / Full auto;
  - one-thumb mode;
  - a left-handed swap;
  - zombie speed and turning-time multipliers;
  - shake and hit-stop toggles;
  - turning shown by shape as well as colour.
