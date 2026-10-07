# Fun systems: what each one causes, and what we keep

**Status:** decided by the user on 2026-10-07 (cards F1–F11, answers verbatim in §1). Anything marked *provisional* is Claude's call and can be overturned after a playtest.
**Behavior spec:** `prototype/index.html` v9 (the frozen spec, ADR 0005). Line numbers (L…) refer to it.
**Builder:** Codex builds in `godot/`, Claude reviews (ADR 0015). Godot today is daytime only (chapters 1–3).
**Direction:** ADR 0018. **Related docs:** `design/tutorial.md` (Grandpa, Gary at the first dusk, the armory arrow), `design/characters.md` (zombie looks, Zombie Granny, bosses as Chad in mascot suits).

## 0. The diagnosis (why this doc exists)

The user's words:
- "i think some of them are just too much that the game loses it pointing"
- "i feel like the zombie part could get more intresting but the game is soo full of staff that its just there"

What v9 does to a player in chapter 1:
- About **12 systems in the first ~13 minutes**: robbers, a UFO, goals, weather, a gun, zombies from day 2, a blood-moon horde plus a boss on day 3, overflowing pockets, collectors, fever…
- **There is no way to lose.** A bite only knocks off items or 2% of your wallet. The ch1 boss (30 HP) dies in about 14 s of held fire with the Milk squirter.
- **Measured in Godot ch1** (tutorial session, `tutorial.md` §2): the arrow-following bot walks **94% of the time** (418 of 445 s).

**The new direction (ADR 0018):** fewer systems in chapters 1–3, and real stakes.
- The farm earns money → you buy the chapter's weapon → you survive nights that get harder → you beat the chapter boss (a real fight with powers) → the next chapter.
- If your hearts run out you lose. Losing to the boss sends you back to the start of the chapter.

## 1. Decision log (verbatim)

| Card | Question | User's answer |
|---|---|---|
| (round 1) F1–F4 v1 | Night shape / cure pay / chasers / losses | "[No preference]" on all four. Then: "i want to first discuss on all the fun part…" |
| (discussion) | Z1–Z5 zombie ideas (serve the order, day mistakes return, cured become staff, defend the shop, fewer types) | **Rejected:** "i did not like your ideas there are also boss . i think you need to be able to loose and start the chapter from your saving after , maybe you need to buy a weapon that will help you defet the zombies and the boss that have extended life and are hard to kill and the boss should actully have powers" |
| F1 | What makes you lose? | "Your hearts run out (Recommended)" |
| F2 | When you lose, where do you go back to? | "Start of the chapter" |
| F3 | What role does the boss play? | "Chapter's final exam (Recommended)" |
| F4 | How do weapons work? | "New weapon each chapter (Recommended)" |
| F5 | When does the boss fight start? | "Fixed: every Nth night" |
| F6 | Do normal nights still have zombies that can take hearts? | "Yes, getting harder (Recommended)": losing a normal night sends you back to dusk; only losing to the boss sends you to the chapter start |
| F7 | What do weapons shoot? | "Your carried stack (v9, Recommended)" |
| F8 | Which other systems stay in ch1–3? | "Robbers" (only). Surprise events, MOO FEVER, weather and daily goals are out of ch1–3 |
| F9 | N for the boss night | "Every 3rd night (Recommended)" |
| F10 | What do you need to finish a chapter? | "Beat boss AND buy the gate (Recommended)" |
| F11 | When can robbers chase you? | "Daytime only (Recommended)" |

## 2. The loop after the decisions

```
 DAY (robbers only) ── farm, serve, earn ──► buy the chapter's WEAPON + its upgrades + farm pads
        │                                                     │
        ▼                                                     ▼
 DUSK auto-save ──► NIGHT k: zombies in 3 beats, harder every night ── hearts 0 ──► back to DUSK
        │                     (lost customers near you turn too)
        ▼
 every 3rd night = BOSS NIGHT (Chad in a mascot suit, with powers) ── hearts 0 ──► back to CHAPTER START
        │ beaten                                             │ survives to sunrise: he flees, no penalty, back in 3 nights
        ▼
 boss_beaten[ch] + gate bought ──► next chapter (a new chapter-start save)
```

**The tension:** what you carry is stock for the counters *and* ammo (F7). On a boss night you run between the boss and your trays to reload.

## 3. Per-system decisions and specs

Numbers marked *provisional* are starting points. Codex builds them so they can be tuned (constants in one place) and proves them with the bots in §5.

### 3.1 Hearts and losing (F1)
- **5 hearts** *(provisional)*. They're shown in the HUD, without colliding with Grandpa's bubble (top-left under the money pill, `tutorial.md` §3) or the joystick zone.
- **−1 heart** from:
  - a zombie bite (the v9 0.55 s windup still applies; the bite also knocks off up to 3 carried items, but **no wallet loss**, *provisional*);
  - boss contact;
  - a boss power that deals damage.
- **1.0 s of i-frames** after any heart loss (v9 value). The dash's i-frames still apply.
- **Hearts refill to full at sunrise.** No other healing in ch1–3 *(provisional)*.
- **Robbers never take hearts.** They steal coins, as in v9.
- **At 0 hearts:** a "You fainted!" card with a Grandpa line, which names what got you. Then the restore in §3.2.

### 3.2 Checkpoints and restart (F2, F6)
- **Two checkpoints per save slot.** Slots are isolated, a hard-won rule; nothing leaks across slots.
  - `chapter_start`: written once when a chapter is entered (a new game, or passing a gate).
  - `dusk`: written at every transition to night.
- **Loss on a normal night** → restore `dusk` (F6).
- **Loss on a boss night** → restore `chapter_start` (F2). The day and night counters restart at that chapter's day 1.
- **A restore restores everything in the slot**, including all districts (ADR 0010), wallet, pads, inventories and vehicles. It **keeps**: settings and sound, the hat wardrobe, the tutorial flags (`tut.*`, so Gary doesn't come back), and the lifetime stats.
- **Migration:** an older save without checkpoints gets `chapter_start` = its state at first load *(provisional)*. Old saves keep finished upgrades after a price rescale (a hard-won rule).

### 3.3 Night (F6, F9)
- **Clock:** the v9 clock (`DAY_LEN` 300 s; night = the last 30%, 90 s) and its darkness curve.
  - The night counter `cn` is per chapter: it resets on chapter entry and on a `chapter_start` restore.
- **Night 1 of ch1 = Gary only** (`tutorial.md` §7: he can't bite, and no hearts are at risk).
  - In ch2 and ch3, night 1 is a normal night.
  - In ch1, real zombies start on night 2, matching v9's `day>=2`.
- **Boss night:** `cn % 3 == 0` (nights 3, 6, 9…) (F9). It replaces the v9 blood moon: red sky and a banner.
- **Normal night k** (*provisional* numbers, from `research/shooting-night-brief.md`):
  - horde zombies arrive in **3 beats** at 0–30 s, 30–60 s and 60–90 s;
  - on the first real night of a chapter the beat sizes are **2 / 4 / 6**;
  - each later night adds +1 per beat;
  - at most **10 zombies alive** at once (a phone cap), counting turned customers.
- **Turning:** customers turn **only at night** (*provisional*; it follows F11, one chaser at a time). By day a customer who runs out of patience leaves and the rating drops by 0.5.
  - At night the v9 rules apply: patience 33 s × turn rate 3 → about 11 s; within 1,100 px of you they turn, further away they leave.
  - The red-ring save tip (1.5×) stays.
- **Sunrise:** zombies wake up as confused customers (v9 lines), hearts refill, and a short "Survived night k" toast appears.
- **The Farmer night taco stand** (ch2, v9 L135/L149) opens at night only, as in v9.

### 3.4 Zombies: "extended life, hard to kill"
- **Movement, bite and pathing** come from v9:
  - 1.3× player speed, 0.7 s acceleration;
  - a bite windup of 0.55 s and recovery of 0.9 s;
  - **`findPath`/`NAV` pathing, re-planned every 0.5–0.7 s** (a hard-won rule: never straight lines);
  - knockback and slow on a hit.
- **HP is set per chapter, so the chapter's base weapon kills a normal zombie in 3 hits** *(provisional)*:

  | | ch1 | ch2 | ch3 |
  |---|---|---|---|
  | Normal | 3 | 6 | 12 |
  | Karen | ×1.5, rounded up | ×1.5, rounded up | ×1.5, rounded up |
  | Big (20% of horde spawns) | ×3 | ×3 | ×3 |
  | Zombie Granny (`characters.md` §5) | +2 hits | +2 hits | +2 hits |

  With the **previous** chapter's weapon, a zombie takes about **6 hits**, which is the reason to buy the new one.
- **Joke types:**
  - kept from v9: Karen (double bite → still −1 heart, but she knocks off 6 items), Lactose (milk and cheese do 3×), Vaulter, Flag;
  - **Influencer:** the flash drops from blinding the screen to a 0.25 s camera-flash frame plus a line (*provisional*: v9's was annoying more than funny);
  - **Zombie Granny** as designed in `characters.md`.
- **Cure reward:** v9's (`want × price × 2`), and ×3 on a boss night *(provisional)*.

### 3.5 Weapons (F4, F7)
- **One new weapon per chapter, in that chapter's armory**, plus **2 upgrade pads** for it: "Bigger nozzle" (damage ×1.5) and "Faster pump" (cooldown ×0.75).
- **Ammo = your carried stack** (F7): one item per shot (per volley for spreads).
- *Provisional* stats:

  | Ch | Weapon | Damage | Cooldown | Range | Special |
  |---|---|---|---|---|---|
  | 1 | Milk squirter | 1 | 0.45 s | 230 | Price stays **100** (tutorial T9 arrow) |
  | 2 | Egg launcher | 2 | 0.6 s | 280 | splash 60 px, 1 dmg |
  | 3 | **Pie launcher** (new; Popcorn moves later) | 4 | 0.7 s | 300 | splash 70 px, 2 dmg |

- **Prices are set by the economy designer with the career bot.** The rule: in natural bot play, the base weapon is affordable by night 2 of its chapter, and both upgrades by night 6.
- **Kept from v9:** aim stick, hold to fire, tap for a quick shot, ±14° assist, projectile speed 720 px/s, juice (flash, knockback, hit-stop, shake, combo pitch), and the dash (2.6× for 0.18 s, cooldown 2.5 s).

### 3.6 Bosses: the chapter's final exam (F3, F5, F10)
- **The look** follows `characters.md` §7: Chad Cornwell in a foam mascot suit. When he's beaten, the head pops off and it's Chad: "...this was Dad's idea."
- **Spawn:** 6 s after dusk on a boss night, within 520 px of the player on a walkable cell.
- **Every power has a visible warning of at least 0.8 s, and a dash dodges it.**
- **HP** (*provisional*, in base-weapon hits): ch1 **40** HP, ch2 **120** (60 egg hits), ch3 **320** (80 pie hits).
- **If he's still alive at sunrise, he flees.** That's not a loss: he returns in 3 nights.
- **Win:** v9 reward `max(500, bp × 250)`, a trophy, and `boss_beaten[ch] = true`.
- **Chapter exit (F10):** the next chapter opens only when **the gate is bought AND `boss_beaten[ch]`**. If the gate is bought first, Grandpa says something like "Gate's paid. Now beat the mascot." and the HUD shows "Boss in N nights".

**Powers** (*provisional*; the user asked that "the boss should actully have powers"):

- **Ch1, Cornelius the Kaiju Cob:**
  1. **Kernel ring:** every 4 s, husks shake for 0.8 s, then 10 kernels fly out at 260 px/s; each hit costs −1 heart.
  2. **Burrow:** every 12 s he dives underground. A dirt mound (r 50) follows you for 2 s, locks in place for 1 s, then he erupts; within 50 px you lose 1 heart.
  3. **Corn snack:** within 60 px of a ripe crop, he eats it for **+2 HP per crop, one per second**. Grandpa: "He's eating the corn! Get him off it!" Knockback pushes him away.
- **Ch2, The Big Cheese:**
  1. **Wheel roll:** every 7 s a red line shows for 1.0 s, then he rolls 600 px at 3× player speed (−1 heart).
  2. **Stink cloud:** a 90 px cloud that lasts 5 s; you move at ×0.6 inside it, with no damage.
  3. **Split:** at 50% HP he splits into **3 wedges**, each with 20% of max HP, using smaller wheel rolls. He's beaten when all 3 are gone.
- **Ch3, The Sourdough Starter:**
  1. **Rising:** if he isn't hit for 3 s, he grows +10% in size and heals 2% of max HP per second, up to 150% size. Hits shrink him back.
  2. **Dough glob:** lobbed at your position, with its shadow showing for 0.9 s. If it hits, you're stuck for 1.2 s (no heart lost), and the dough puddle stays for 4 s.
  3. **Baguette summons:** every 10 s, 2 normal zombies (holding baguettes).
- **Ammo pressure is intended:** ch1 takes about 57 shots at a 70% hit rate, which is 4–7 refills at ch1 capacity.

### 3.7 Robbers (F8, F11)
- **v9 rules** (L950–1022) port into ch1–3, **by day only**. At dusk, any robber who is chasing you gives up ("Too spooky!") and goes back into hiding.
- **Per open district:** one hideout. Raccoon in districts 0–1 (steals 6%), Sneaky Pete from district 2 (steals 8%).
- **The chase:** 0.92× your speed, at most 9 s or 430 px. They trigger within 230 px if your wallet is ≥ 20.
- **When caught:** 40% of the stolen coins fall on the ground for 12 s; tackling the robber gives the sack back **doubled**.
- **No hearts.** The guard dog is not in ch1–3 *(provisional)*.

### 3.8 Out of chapters 1–3
- **The user's call (F8):**
  - BREAKING MOOS events (UFO, goose, golden cow, Granny race);
  - **MOO FEVER**;
  - weather;
  - daily goals.

  They aren't deleted from the spec. Whether any return in later chapters is a later card.
- **Claude's call (*provisional*):**
  - turrets and floodlights (they'd automate the "hard to kill" fight away);
  - guard dog;
  - pocket overflow and the 3 collectors (coins just pile at the counter as in Godot today);
  - hats and the wardrobe (Zombie Granny's scarf waits too).
- **Later chapters, not decided:** debate (ch8) and prestige (post-game).

### 3.9 Still open
- **The 2-second loop versus the one big world** (backlog Now). Night now adds reload trips, so this matters more.
- **Ch1 pacing:** the Godot ch1 bot buys the gate at about 7.4 min, but the first boss night (night 3) starts at about 13.1 min. Either the player waits about 6 minutes, or ch1 gets longer, or ch1's boss comes earlier. **This needs a card once the bot measures it with the boss in place.**

## 4. What v9 does (reference, condensed)

- **Clock** (L1031–1145): morning 0–75 s, midday 75–150, evening 150–210 (spawns ×1/0.7, turning ×1.25), night 210–300 (turning ×3). A blood moon every 3rd day: a horde of `6+2·ch`, turning ×1.3, the boss.
- **Patience** (L1033–1052, L641–660): 33 s. VIP 5% (0.6× patience, pays 5×), granny 8% (never turns), critic 3% (rating ±1). Each item served takes 3 s off the wait. The ring goes green under 40%, orange under 70%, then red, and serving in the red pays a 1.5× tip.
- **Zombies** (L1152–1230): HP 1 by day and 2 at night, big 5. Type weights: normal 55, Karen 12, Lactose 11, Vaulter 11, Influencer 11. A bite knocks off up to 3 items or 2% of your wallet. Cap 26 alive. They despawn after 15 s more than 1,500 px away.
- **Guns** (L332): Milk squirter 100, Egg launcher 6k, Popcorn cannon 200k, Confetti cannon 30M. Turrets 2,500 / 500k, floodlights 15k.
- **Fever** (L1302): +0.03 per sale, +0.05 per kill, decays 0.008/s; 15 s of ×2 coins and ×1.3 speed.
- **Events** (L1345–1395): every 110–200 s by day, reward base `max(30, bp×25)`.
- **Boss** (L1396–1418): HP `30+10·ch`, a ring of 10 shots every 3.2 s, summons 2 zombies every 8 s.
- **Pockets** (L666, L1061): cap `max(60, price×150)`, spill onto the ground; collectors keep 50/30/15%.
- **Goals** (L1100): 3 per day.
- **Weather:** 60% sun, 25% rain, 15% heat.
- **Prestige:** udders `max(3, ⌊√(lifetime/1M)⌋)`.

## 5. Done checks for Codex (headless, in `check.sh`)

| Test | Proves |
|---|---|
| `test_hearts` | A bite costs −1 heart, then 1.0 s of i-frames. Robbers cost 0 hearts. Hearts refill at sunrise. 0 hearts triggers the loss card |
| `test_checkpoints` | A normal-night loss restores `dusk`; a boss-night loss restores `chapter_start` (wallet, pads, all districts). Tutorial flags, wardrobe and settings are kept. Slot 2 is byte-identical after slot 1 restores. An old save gets a `chapter_start` on first load |
| `test_night_escalation` | Beat sizes are 2/4/6 on the first real night and +1 per beat each night after. At most 10 alive. Customers turn only at night. Ch1 night 1 is Gary only |
| `test_zombie_hp` | Normal zombies die in 3 hits from the chapter's base weapon and about 6 from the previous one. Zombies pathfind around an obstacle (path > 2 nodes). The unstick safety net still works |
| `test_boss_ch1..3` | Each power's warning lasts at least 0.8 s, and a dash dodges it. Cornelius heals from crops. The Big Cheese splits at 50%. The Starter rises when left alone. A boss alive at sunrise flees with no penalty |
| `test_gate_requires_boss` | A bought gate without `boss_beaten[ch]` doesn't open the next chapter. With both, it does |
| `test_robbers_day_only` | No robber chases at night; a chasing robber gives up at dusk. The tackle refund is 2× |
| Fight bot (per chapter, 10 seeds) | **Fully upgraded weapon:** the boss dies in ≤ 75 s. **Base weapon:** it wins in ≤ 90 s with at least 1 heart left in ≥ 7 of 10 seeds. **Previous chapter's weapon:** it can't win before sunrise. Tune HP until these hold, and report the final numbers |
| Career bot ch1–3 | Reaches the ch4 gate with natural play, buying weapons by the price rule in §3.5. Reports restarts, hearts lost per night, and the wait between buying the gate and beating the boss (input for §3.9) |
