# Tutorial: the first-time player experience

**Status:** Design accepted 2026-10-07 (cards T1–T10, ADR 0016). Not built yet. **Codex builds it, Claude reviews it** (ADR 0015).
**Engine:** Godot (`godot/`). The HTML prototype is the frozen spec for mechanics, not for this feature.
**Narrator:** Grandpa Bovine, a cow farmer (card D3). His look, voice and backstory belong to `context/design/characters.md` §2, owned by the character session. This doc owns only **when he talks and what he says while teaching**. If `characters.md` changes his voice, rewrite the lines here and keep the triggers.

## 1. Decisions (the user's words, verbatim)

| Card | Question | Answer |
|---|---|---|
| T1 | Who teaches? | "A: Grandpa Bovine (Rec.)" |
| T2 | How strict? | "just part of part 1 soft bets" (soft beats, only in the opening of chapter 1) |
| T3 | Skip / existing saves | "its a soft one easy to follow so no skip" |
| T4 | Stuck player | "B: Arrow only" |
| T5 | Where the beats end | "A: Through first pad (Rec.)" |
| T6 | Grandpa after the beats | "C: Constant commentary" |
| T7 | Do bubbles pause? | "A: Never pause (Rec.)" |
| T8 | First night / shooting | "A: Practice zombie (Rec.)" |
| T9 | Gary but no gun yet | "C: Arrow to armory" |
| T10 | Quiet toggle | "B: No toggle" |

*Provisional* (Claude's own calls, not asked): how existing saves are treated (§6), all numbers in §2 and §7, the line texts, cooldown values, and the bubble placement.

## 2. Hard rules (numbers Codex tests)

| Rule | Number |
|---|---|
| Words per bubble | **≤ 12** (emoji don't count). Chars ≤ 64. |
| Bubbles on screen | **1** at a time. A new one replaces the old (except during the minimum display time). |
| Minimum display | 1.5 s (so a beat that completes instantly doesn't flash its line). |
| Maximum display | 6 s, then a 0.3 s fade. |
| Pausing | **Never.** `sim.T` keeps advancing while a bubble is shown, and input is never blocked. |
| Tapping | Never needed. Tapping the bubble does nothing (no skip, T3). |
| Locks | **None.** Every pad, machine and tray works from second 0 (T2 soft). |
| Stuck help | **The guide arrow only** (T4). No nag timers, no ghost hand, no idle lines. |
| Opening length (arrow bot) | Beats B0–B6 done by **T ≤ 45 s** of game time (baseline first pad: 35.1 s). |
| First sale (arrow bot) | Coins land in the Milk stand's cash pile by **T ≤ 20 s** (baseline 15.1 s). |
| Career impact | The chapter-1 bot's gate time stays within **±5%** of the baseline (444.6 s on 2026-10-07). |
| Commentary cooldown | **≥ 20 s** between commentary lines. The same trigger fires at most once per **120 s**. The same line doesn't repeat within **300 s**. |
| Commentary volume | Over a 600 s chapter-1 bot run: **10–30** commentary lines (not counting beats or first-time lines). |

Baseline from Claude's measurement on 2026-10-07 (an export of `91318e5`, `MooBot` following the arrow, fresh slot, DT 1/30):

| Event | t |
|---|---|
| first corn in hands | 0.1 s |
| first corn into the cow hopper | 2.5 s |
| first milk picked up | 6.7 s |
| first milk on the stand | 9.6 s |
| first sale (cash pile > 0) | 15.1 s |
| coins in the pocket | 20.4 s |
| Corn conveyor paid (50) | 35.1 s |
| Bigger arms (80) | 61.6 s |
| Milk runner (first helper) | 259.3 s |
| Buy the dairy (chapter 1 done) | 444.6 s |

The player moves 94% of the time (418 s of 445 s), and the longest stand-still is 1.5 s. The loop is busy, so the beats must ride on it, not interrupt it.

## 3. Grandpa's bubble (presentation)

- **Placement:** top-left, under the money pill. The 56 px round HUD portrait from `characters.md` §2 (white ring, 3 px `#6b4423` stroke, `#bfe3a8` background) plus a white bubble with dark text, Baloo 2 800. It must not cover the joystick zone, the money pill or the gate progress.
- **Voice:** a "moo-babble" blip, a few synthesized syllables (Animal Crossing style). It's precomputed like the other chapter-1 sounds (ADR 0007), plays once per bubble, and respects the sound setting.
- **Animation:** the portrait bounces in (0.2 s) and wobbles ±3° on each blip, and the mustache wiggles at 8 Hz while he talks (`characters.md`). The bubble fades out.
- **The arrow is unchanged** (T4): `guide_raw()` keeps choosing the target. The beats are designed so that the arrow already points at the thing each line is about. The tutorial never overrides the arrow, except for the T9 armory hook (§5).

## 4. The first 60 seconds: soft beats B0–B6 (T2, T5)

**How beats work.**
- They run only in a fresh slot (`tut.beat < 7`, see §6).
- One beat is current. When it becomes current, its line shows, **unless its completion flag is already set**. In that case it completes silently and the next beat becomes current (out of order is fine).
- Completion flags are "ever happened in this slot" events, set by the sim wherever the action really happens, whoever did it (player only; helpers don't count).
- Beats never change the economy, and nothing is locked.

| # | Trigger (becomes current) | Grandpa says (≤12 words) | Arrow is already at | Completes when (flag) | Bot budget |
|---|---|---|---|---|---|
| B0 | Fresh slot starts (replaces the 22-word intro toast) | "Kid! I left you a farm. And three cows. Good luck." | corn | 2.5 s elapsed **or** the player moves | ≤ 3 s |
| B1 | B0 done | "That's corn. Walk into it. Corn loves that." | ripe corn | `ev_harvest`: the player picked ≥ 1 corn | ≤ 3 s |
| B2 | B1 done | "Cows eat corn. Dump it on their mat. Don't ask." | the cow barn's in-pad | `ev_feed`: the player put ≥ 1 corn in a hopper | ≤ 6 s |
| B3 | B2 done | "Milk! Fresh-ish. Grab it off the crate." | the milk tray | `ev_pick_out`: the player took ≥ 1 milk from a tray | ≤ 10 s |
| B4 | B3 done | "Now the stand. Townsfolk will pay for milk. Weirdos." | the milk stand drop | `ev_stock`: the player put ≥ 1 milk in a counter box | ≤ 14 s |
| B5 | B4 done | "A customer! Coins land in the pile. Go grab them." | the cash pile | `ev_collect`: the player picked up ≥ 1 coin from a cash pile | ≤ 25 s |
| B6 | B5 done **and** wallet ≥ the cheapest visible pad's remaining cost (so the arrow is on the pad) | "See that glowing square? Stand on it. Spend, spend, spend!" | the Corn conveyor pad | `ev_pad`: any pad fully paid | ≤ 45 s |
| B6+ | B5 done but the wallet is still short | "Again! Corn, cows, milk, money. That's farming. That's it." (once) | the normal loop | (the line only; B6 waits) | — |
| end | B6 done | "A conveyor! I carried corn uphill. Both ways." | — | sets `tut.beat = 7`, and commentary mode starts | — |

**What each beat teaches** (the user's list):
- carrying stacks: B1 (the stack grows as you walk through corn, so the line is short and the stack is the visual);
- feeding machines: B2;
- picking up outputs: B3;
- selling: B4 and B5;
- paying for upgrade pads: B6.

The other mechanics are taught by first-time lines (§5): helpers, Toss, travel, Bigger arms (capacity), overflow, and later aiming and shooting.

**Not taught by text:** the joystick. The world teaches it: at B0, a hint of a joystick ring pulses at the touch point until the first move, which is the existing touch HUD and not a bubble. If the HUD has no idle ring, Codex adds a 1 s pulsing ring where the last touch was, shown only before the first move.

## 5. After the beats: constant commentary (T6 C, T10 B)

Two kinds of lines.

**(a) First-time lines.**
- Each fires once per slot, the first time the thing happens. They bypass the 20 s cooldown, but wait for the 1.5 s minimum display of any current bubble.
- They replace today's long toasts (the chapter intros, "Unlocked: X!" stays as a toast and Grandpa adds flavor).

| id | Trigger | Line |
|---|---|---|
| f_cap | "Bigger arms" paid | "Bigger arms! Now carry twelve. Your back is my problem now." |
| f_full | Stack first hits capacity | "Arms full. Even Grandpa had limits. Barely." |
| f_toss | First item into a Toss bin | "The Toss bin! Throw extras in. Coins come out. Magic." |
| f_nobody | First "Nobody needs X" warning | "Nobody wants that right now. Toss it or hold it." |
| f_helper | First helper hired | "You hired help! Pay them in compliments. Kidding. Coins." |
| f_belt | First conveyor runs | "Look at it go. Lazy, like your father." |
| f_overflow | First cash overflow | "Coins on the ground! Pick them up before the geese do." |
| f_unlock | First module unlocked (coop/stand) | "New building! Smells like progress. And chickens." |
| f_gate_seen | The gate pad first becomes visible | "That's the dairy next door. Buy it. Show those cows." |
| f_ch2 | Chapter 2 starts (replaces the intro toast) | "Farmer now! Milk makes cheese. Cheese makes money. Science!" |
| f_ch3 | Chapter 3 starts | "Baker! The whole town wants bread. Ovens on, kid." |
| f_travel | First district travel | "Road trip! Your old farm keeps working. Mostly." |
| f_ch_done | Chapter 3 done (current Godot end) | "Supermarket?! I'm telling everyone at bingo." |

**(b) Commentary lines.**
- These are event reactions with cooldowns (§2): global ≥ 20 s, the same trigger ≤ once per 120 s, and no repeat of a line within 300 s.
- **Never idle or "stuck" nags** (T4 is arrow-only).
- There's no toggle (T10).
- At least 3 lines per trigger, picked at random without repeats.

| Trigger | Lines (pick one) |
|---|---|
| A big sale (one customer pays ≥ 3× the base price) | "Big spender! Charge them double next time." / "Cha-ching! That's Grandpa's favorite song." / "They paid THAT? For milk? Brilliant." |
| A pad fully paid (not the first of its kind) | "Another upgrade. My farm never looked this fancy." / "Spend it all! Money's just paper. Shiny paper." / "Your grandma would be proud. Of me, for teaching you." |
| A stack is full for ≥ 1 s | "Careful, that tower's wobbling." / "That's a lot of corn, kid." / "Strong arms. Takes after me." |
| A customer leaves unhappy | "He left! Grumpy customers turn weird at night." / "Faster, kid! They've got short patience. Like me." / "Lost one. Happens. Mostly to you." |
| Money ≥ the gate cost for the first time | "You can afford the next place! Go, go, go!" |
| A helper delivers (≤ once per 300 s) | "Look at that helper go. You're management now." / "Free labor. Well, paid labor. Still great." / "Delegation! The secret of my success. And cows." |
| Wallet at 0 after spending | "Broke again. Classic farmer. Back to the corn." / "Zero coins. Grandpa's been there. Twice. Today." / "Empty pockets, full heart. And a conveyor." |
| A random event (when ported) | an event-specific line, written with the event |

**Night commentary** (when ported): first dusk, first zombie, first cure, first bite, first sunrise, first blood moon. One first-time line each, with short commentary pools for zombie types (Karen, Lactose-intolerant, Influencer, Pole-vault). These are written in the night port's own task, 12 words max, same rules.

## 6. Saves, slots, existing players (T3: no skip; *provisional* handling)

Slot JSON gets one new key, and nothing else changes:

```json
"tut": {"beat": 0, "flags": ["ev_harvest", "..."], "seen": ["f_cap", "..."], "gary": 0, "last": {"<line id>": 123.4}}
```

- **New slot:** `beat: 0`, empty arrays. B0 plays.
- **Old save with no `tut` key** (every save that exists today, HTML or Godot):
  - Treat it as `beat: 7` (no beats, ever). Set `seen` for every first-time line whose thing already exists in the save (e.g. `f_cap` if Bigger arms is paid, `f_ch2` if `ch ≥ 1`).
  - On the first load, Grandpa says one hello: "I'm narrating now. Nobody asked. Here I am." (id `f_hello_old`).
  - Wallet, pads, inventories and position are unchanged.
- **Mid-tutorial save/reload:**
  - The `beat` index and flags restore. The current beat re-shows its line once.
  - If a fresh-slot save somehow has a fully paid pad and `beat < 7` (e.g. a crash), the beats complete silently via their flags.
- **Isolation:** `tut` lives inside the slot. Deleting a slot deletes it. Slot 1's tutorial never affects slots 2 and 3. Like vehicles and the dog, this is a hard-won rule.
- **No skip, no replay** (T3). If the user later wants "replay", that's a new card.
- **Cooldown timestamps** (`last`) are sim-time, so they survive save/load and don't use wall clock.

## 7. The first night (when night is ported; T8 A, T9 C)

**Trigger:** the first dusk in this slot (the evening phase, `onPhase` → 2), in district 0. It happens once per slot (`tut.gary`).

1. **Dusk.** Grandpa: "Getting dark. Things get weird here at night." Gary (a scarecrow in a too-small green zombie mask; the look is in `characters.md` §6) walks out to the edge of the corn field and waits, waving.
2. **No gun (`S.gun == 0`, T9 C):**
   - Grandpa: "That's Gary. Practice zombie. You need a squirter. Armory!"
   - **Armory hook:** while `tut.gary == 1` and `S.gun == 0`, `guide_raw()` returns the Milk squirter pad first, when the wallet ≥ its remaining cost. Otherwise the arrow keeps its normal loop, and one extra line plays: "Save up 100 for the squirter. Gary will wait. He's patient."
   - Gary waits, idle-animating; he doesn't approach.
   - Normal night rules continue meanwhile: customers who wait too long can turn. *Codex: verify a gunless first night is survivable. If not, raise it as a card, don't change the economy.*
3. **Gun owned:**
   - Grandpa: "Drag on the right side to aim. Squirt Gary."
   - This replaces the 25-word gun-aim toast. On desktop the line ends "(mouse + click)", within the 12-word budget: "Aim with the mouse. Click to squirt. Squirt Gary."
   - Gary waddles toward the player at **40%** of zombie speed. He has 1 HP, he **can't bite** (he bonks off and says "boo?"), and he uses `findPath`/`NAV` like real zombies (a hard-won fix; no straight lines).
4. **Hit:**
   - Gary bursts into straw (`characters.md` §6). There's no drop and no reward.
   - Grandpa: "Gary's fine. He's straw. Real ones don't pop like that."
   - `tut.gary = 2`, and the night's own first-time lines take over.
5. **Gary never got hit:** if 60 s pass after the gun is owned, Gary trips over his costume and falls apart by himself. Grandpa: "Gary tripped. Close enough. Good luck tonight."
   - This is a timeout so the night is never blocked, not a stuck nag. T4 holds.

Night numbers to test:
- The arrow bot with a gun hits Gary in ≤ 20 s.
- Gary deals 0 damage.
- Gary appears once per slot.
- An old save with `S.gun ≥ 1` and `day > 1` never sees Gary (`gary` is set to 2 on migration).

## 8. Implementation notes for Codex

- **`godot/scripts/tutorial.gd`** (new, `class_name MooTutorial`): the beat machine, the line tables, cooldowns, and the `tut` save block.
  - It fits the planned `sim.gd` split. Land the split first or alongside, Codex's call.
  - The sim emits plain events: `ev_harvest`, `ev_feed`, `ev_pick_out`, `ev_stock`, `ev_sale(amount)`, `ev_collect`, `ev_pad(pad)`, `ev_unlock`, `ev_toss`, `ev_warn_nobody`, `ev_full`, `ev_helper_hired`, `ev_helper_deliver`, `ev_belt`, `ev_overflow`, `ev_customer_lost`, `ev_wallet_zero`, `ev_chapter(ch)`, `ev_travel`. Only the player's actions set the beat flags.
  - The tutorial consumes them and sets `current_line {id, text, t}`.
- **`hud.gd`** draws the portrait and bubble. **`audio.gd`** gets the precomputed moo-babble.
- **`moo.gd`:**
  - Remove `sim.toast(sim.stage.intro, 5.0)` on a fresh slot (B0 replaces it).
  - Expose `tutorial_state()` → `{beat, flags, seen, gary, line}` for tests.
- **`sim.gd` L362**, the chapter-change intro toast: replace it with `f_ch2`/`f_ch3`. Keep "Unlocked: X!" toasts.
- **`data.gd`** keeps `intro` strings (the spec) but no longer shows them.
- Line text lives in one table, so the 12-word test can scan it.

## 9. Headless test plan (add to `check.sh`)

| Test | What it does | Pass when |
|---|---|---|
| `test_tutorial_bot.gd` | Fresh slot; `MooBot` follows the arrow at DT 1/30 for 60 s game time. Logs each beat's completion time. | B0–B6 all complete; each beat within its §4 budget; `beat == 7` by T ≤ 45 s; first sale ≤ 20 s; every beat's line was shown (or silently skipped via a flag); `sim.T` advanced every frame a bubble was up (no pause). |
| `test_tutorial_order.gd` | Scripted player does things out of order: picks milk before feeding (preloaded tray), stocks, pays a pad with preset money. | Beats whose flags are set complete silently; no line for an already-done beat is shown; ends at `beat == 7`. |
| `test_tutorial_saves.gd` | (1) Save mid-tutorial at B3, reload: resumes at B3 with flags. (2) Load an old-format save (no `tut`, Bigger arms paid, ch 1): `beat == 7`, `f_cap` and `f_ch2` in `seen`, `f_hello_old` fires once, money/pads/inventories/position byte-identical to the pre-load snapshot. (3) Slot 1 mid-tutorial, slot 2 fresh, slot 3 old: each slot's `tut` is independent after switching back and forth. (4) Delete slot 1 and restart: B0 plays again. | All four assertions hold. |
| `test_grandpa_lines.gd` | Static scan of every line table. Then a 600 s chapter-1 bot run recording every line. | Every line ≤ 12 words and ≤ 64 chars; one bubble at a time; commentary gaps ≥ 20 s; same trigger ≤ once per 120 s; no repeat within 300 s; 10–30 commentary lines; each first-time line fired at most once; no line fires while the player stands still with nothing happening (no idle nags). |
| `test_bot_chapter1.gd` (existing) | Unchanged bot, with the tutorial active. | The gate is bought within ±5% of 444.6 s (the economy is untouched). |
| `test_tutorial_night.gd` (with the night port) | Fresh slot fast-forwarded to the first dusk: (a) gunless: the arrow targets the Milk squirter pad once the wallet ≥ cost, and Gary stays put; (b) with a gun: bot aims at Gary. | (a) holds; (b) Gary is hit ≤ 20 s and deals 0 bites; Gary pathfinds (path length > 2 nodes around an obstacle); Gary appears once per slot; the 60 s trip timeout works with no input. |

Put the first four in the fast tier (target total < 15 s wall), per the backlog item "Tier `check.sh`".

## 10. Open for later (not decided, not built)

- Chad Cornwell (the rival inside every boss suit, `characters.md` §7): Grandpa's boss lines get written with the boss port.
- Replay tutorial: not offered (T3). A new card if wanted.
- Lines for chapters 4–9 and their mechanics (harbor, vehicles, robbers, debate): written when each is ported, same rules.
- Localization: the 12-word rule is for English. Revisit if translating.
