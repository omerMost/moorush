# Chapter 2 redesign, map tidy-up and the discovery moment

**Status:** decided by the user on 2026-10-07 (cards G1–G6, answers verbatim in §1). Anything marked *provisional* is Claude's call and can be changed after a playtest.
**Direction:** ADR 0024. **Builder:** Codex; Claude reviews (ADR 0015).
**Related:**
- `design/fun-systems.md` (night, weapons, bosses: the Egg launcher and The Big Cheese stay in ch2);
- `design/tutorial.md` (Grandpa's lines, Gary, the armory arrow);
- `design/characters.md` (the Big Cheese mascot);
- backlog "No repeated farm in later chapters" (card N2, settled here for ch2).

## 0. The problem (the user's words)

> "i want to remove most of chapter 2 , its mostly repeted chapter 1 insted of reopening corn cow and chiken field make in chepter 2 the filed fro, chepter 1 bigger . and i want to organize the map, and also i want to add animation when new field is discover move the camera to zoom there and tell the tutorial grandpa be there and say whets new . there are too many fields type at the moment and it remove the game intrest from the fun part , also the water part are cool but also needs to orgenize"

Earlier, for the backlog: "i want you to add to tasks to change things so there will not be another corn field and cow barn or farm because its making the field to complex to track".

**Today in Godot** (`godot/scripts/data.gd`):
- Ch2 "Farmer" has its own Corn field, Dairy barn, Big coop and Egg stand. These are copies of ch1's corn field, cow barn, chicken coop and egg stand.
- Its only new things are the Cheese press and the Cheese shop.
- Ch1 spends 3 of its 9 cells on shops (vehicle shop, bank, armory). The vehicle shop and bank only say "coming soon" in ch1–3.

## 1. Decision log (verbatim)

| Card | Question | User's answer |
|---|---|---|
| G1 | What is ch2 once it stops repeating ch1? | "Ch1 farm grows + cheese (Recommended)" |
| G2 | How do we cut the number of field types? | "Up to two per chapter" |
| G3 | The discovery moment | "Glide + zoom + Grandpa (Recommended)" |
| G4 | The water (Harbor) | "Its own chapter, later (Recommended)" |
| G5 | Map layout | "Keep the 3×3 grid" |
| G6 | Vehicle shop, armory and bank in ch1 | "Appear only when useful (Recommended)" |

**N2** (how ch2 gets milk for the Cheese press) is settled by G1: **A, the ch1 barn feeds it**, via a helper and a new "Milk pipeline" belt across the district gap.

## 2. The rules

1. **One of each production type in the whole game.** There's one corn field, one cow barn and one chicken coop. No chapter repeats a module type+item from an earlier chapter.
2. **At most two products per chapter** (G2):
   - ch1: milk and eggs;
   - ch2: cheese (plus the night taco stand from `fun-systems.md`);
   - ch3: bread and pies (unchanged).
   - Later chapters and the Harbor follow the same rule when they're ported. The ch6–9 repeats stay as a backlog item.
3. **"Growing" means more and faster, in the same place.** Ch2 pads upgrade the ch1 corn field, barn and coop where they already stand: more plots, more cows, more hens. Their cells and fences don't move.
4. **The 3×3 grid stays** (G5): `DPOS` and the cell sizes don't change, and ch2 keeps its own block next to ch1. That block now holds only what's new.
5. **Shops appear when they have something to sell** (G6).

## 3. Chapter 1 block (district 0) after the change

| Cell | Today | After |
|---|---|---|
| (0,0) | Egg stand | Egg stand (same) |
| (1,0) | Chicken coop | Chicken coop (same) |
| (2,0) | Bank | **Empty grass and trees** until the bank is needed (not in ch1–3) |
| (0,1) | Corn field | Corn field (same; grows in ch2) |
| (1,1) | Cow barn | Cow barn (same; grows in ch2) |
| (2,1) | Gate "Buy the dairy" | same |
| (0,2) | Milk stand | same |
| (1,2) | Vehicle shop | **Empty** until vehicles are ported |
| (2,2) | Farm armory | **Hidden until the first dusk.** It appears with the discovery moment (§6) together with Gary and the T9 arrow (`tutorial.md` §7) |

## 4. Chapter 2 block (district 1): "The Dairy"

The new block has no corn field, barn, coop or egg stand. *Provisional* layout, chosen to keep press → shop within one cell of each other:

| Cell | Module |
|---|---|
| (0,1) | **Cheese press** (milk → cheese, station, 1 press, period 3.0 s). The cell nearest ch1's barn |
| (1,1) | **Cheese shop** (cheese, price 14) |
| (0,0) | Armory (the Egg launcher and its upgrades, already built in ADR 0023) |
| (1,2) | **Night taco stand** (night only, v9's `supply` truck; `fun-systems.md` §3.3) |
| (2,1) | Gate "Open a bakery" |
| the rest | grass, trees and a pond (scenery, ADR 0011) |

**Ch2 pads** (12, as today; base costs before the `TUNE × PM` scaling the code already does; all *provisional*, and the career bot proves them):

| # | Pad | Target | Effect | Base cost |
|---|---|---|---|---|
| 1 | Bigger corn field | ch1 Corn field (d0 A) | **new `grow` effect:** plots ×1.5 (rounded up), regrow time ×0.8 | 150 |
| 2 | Stronger arms | player | capacity 14 | 200 |
| 3 | Dairy hand | helper d0 B → d1 C | carries milk from the ch1 barn to the press | 300 |
| 4 | Second press | d1 C | +1 press | 350 |
| 5 | +2 cows | **d0 B** (the ch1 barn) | +2 cows | 450 |
| 6 | +2 hens | **d0 D** (the ch1 coop) | +2 hens | 450 |
| 7 | Free-range eggs | d0 E (ch1 egg stand) | price ×1.5 | 250 |
| 8 | Milk pipeline | conveyor d0 B → d1 C | a belt across the gap | 400 |
| 9 | Shop clerk | helper d1 C → d1 D | | 500 |
| 10 | Aged cheese | d1 D | price ×1.5 | 600 |
| 11 | Night taco stand | unlock d1 taco | (`fun-systems.md`) | 700 |
| 12 | Open a bakery | gate | | 3,000 |

- **Cross-district targets are new.** Pads, helpers and belts must be able to point at another district's module (for example `"m":"0:B"`), resolved by district plus module ID (ADR 0008's district-qualified keys).
- **What gets bigger is visible:** more corn plots in the field, more cows and hens in their pens, drawn denser inside the same cell.
- **Economy check:** the economy designer and career bot prove that the ch2 gate is reached in natural play, and that the Egg launcher is still affordable by ch2 night 2 and its upgrades by night 6 (ADR 0023). Report the new chapter time against today's.

## 5. Old saves (migration)

Rule: **nobody loses progress** (the price-rescale rule). *Provisional* mapping for saves with district 1 pads:

| Old ch2 pad or module | New |
|---|---|
| +2 cows (d1 B) | → +2 cows on d0 B, paid |
| Big coop unlock (d1 E) | → +2 hens on d0 D, paid |
| Egg stand unlock (d1 F) | → Free-range eggs, paid |
| Corn conveyor (d1 B) | → Bigger corn field, paid |
| Dairy hand (d1 B → C) | → Dairy hand (d0 B → d1 C), paid |
| Stronger arms, Second press, Shop clerk, Aged cheese, the gate | kept as they are (same names) |
| Corn picker (d1), Egg runner (d1), and any part-payment on a removed pad | **refund the paid amount** into the wallet |
| Stock held in removed modules (d1 corn, milk, eggs) | refunded at the base sale price per unit (corn at 1) |
| `dusk` and `chapter_start` checkpoints (ADR 0022) | migrated the same way |

Plus: a toast and a Grandpa line on the first load after migration: "I tidied up the dairy. You're welcome." (once per slot).

## 6. The discovery moment (G3)

**When it plays:**
- a module unlock pad completes (coop, egg stand, taco stand, apple orchard, pie ovens, pie counter);
- the armory appears at the first dusk;
- a gate opens a new chapter (glide to that chapter's first new module).

**Not** for ordinary pads. ADR 0009 removed temporary focus and shake from upgrades because the user saw "a glitch not nice to the eye"; that stays.

**The sequence** (*provisional* numbers):
1. Input pauses; the joystick and fire release.
2. The camera glides to the module's center in **0.6 s** (ease-in-out) and zooms **1.0 → 1.2**.
3. Grandpa's bubble says the module's line (below) and holds for **2.0 s**.
4. The camera glides back to the player in **0.5 s** and zooms back to 1.0. Input returns.

**Rules:**
- **A tap skips:** the camera returns in 0.2 s.
- **No shake. The total is at most 3.1 s.**
- **Several moments at once** queue up, and each plays in turn.
- **At night with zombies alive:** no camera move; only Grandpa's line plays (*provisional*, so the camera never leaves a fight).
- **Smoothness:** the unlock's navigation update (ADR 0009, incremental) runs **before** the glide. During the glide, frame-time p95 stays at or below the gameplay baseline.

**Grandpa's lines** (≤ 12 words; one per module, once per slot; they replace the generic `f_unlock` in `tutorial.md` §5. Chapter starts keep `f_ch2` and `f_ch3`):

| Module | Line |
|---|---|
| Chicken coop | "Chickens! They lay eggs and judge you. Mostly judge." |
| Egg stand | "An egg stand. Sell the eggs. Don't juggle them." |
| Armory (first dusk) | the tutorial's T9 and Gary lines (`tutorial.md` §7) |
| Cheese press (ch2 start) | `f_ch2`: "Farmer now! Milk makes cheese. Cheese makes money. Science!" |
| Night taco stand | "Tacos at midnight. Zombies love tacos. So do I." |
| Wheat field (ch3 start) | `f_ch3` |
| Apple orchard | "Apples! Grandma's pie recipe finally gets used." |
| Pie ovens | "Pie ovens. Hot. Don't touch. I touched." |
| Pie counter | "Pie counter! People line up for pie. And gossip." |

## 7. The water (G4)

- The Harbor **doesn't open with chapter 2** any more (v9 `HARBOR.openAt: 1`).
- It becomes **its own chapter later**, on the lake strip under the grid (G5 keeps it there):
  - one chain (fishing → fish market → sushi bar → sushi boat), within the "two products" rule;
  - the boat as its new tool;
  - its own boss.
- Pearl reef and Jewelry island are cut.
- *Open:* which chapter number it becomes. That's a card before it's ported (backlog).

## 8. Done checks (headless, in `check.sh`)

| Test | Proves |
|---|---|
| `test_no_repeat_types` | No two chapters (0–2) share a production module type+item. Ch2 has no corn field, cow barn, coop or egg stand |
| `test_ch2_cross_district` | +2 cows adds cows in d0 B. The Dairy hand and Milk pipeline move milk from d0 B to d1 C. Cheese sells at d1 D unattended |
| `test_grow_field` | "Bigger corn field" gives ⌈1.5×⌉ plots and ×0.8 regrow. It survives a save round-trip |
| `test_ch2_migration` | A populated old ch2 save (every old pad paid, plus stock in d1 corn/milk/egg): the mapped pads are paid; the wallet rises by exactly the refunds; ch1/ch3 bytes are unchanged; checkpoints are migrated; slot 2 is unaffected |
| `test_shops_hidden` | The bank and vehicle shop aren't drawn and have no pads in ch1–3. The armory is absent before the first dusk and present after it (and on any save with `S.gun ≥ 1`) |
| `test_discovery_moment` | An unlock triggers glide/zoom/hold/return within 3.1 s; a tap skips it; two unlocks queue; an ordinary pad triggers nothing; at night with zombies alive there's no camera move; the nav update finishes before the glide starts |
| Career bot ch1–3 | Reaches the ch3 gate in natural play. Reports the ch2 duration against today's 35 min, and when the Egg launcher becomes affordable |
| Rendered review | Screenshots of the ch1 block (empty bank/garage cells), the ch2 block, and one discovery moment mid-zoom |
