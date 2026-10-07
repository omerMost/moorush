# Characters: the Moo Rush cast

**Status:** chosen by the user on 2026-10-07 (cards D1–D8 and Z1, answers verbatim below). Anything marked *provisional* was Claude's call and is open to change.
**Art direction:** code-drawn only (ADR 0005 G2, kept by ADR 0017). Every look below is built from the prototype primitives `rr` / `ell` / `circ` / lines / text plus the `drawPerson` body. No sprite files. Godot draws it in `paint.gd` with `draw_*` calls and bakes cached textures where ADR 0006 allows.
**Reference images (match these):** [`docs/design/characters/`](../../docs/design/characters/), one PNG per character group. The option sheets the user picked from are in `options/`. The generator is `cast-preview.html` (open it in a browser with `?card=F_player`, `F_zombies` and so on). Its functions (`person`, `hair`, `eyes`, `zface`, `cobBody`…) hold the exact numbers and can be ported line by line.
**Owners:** this file owns looks, personality and voice. `context/design/tutorial.md` owns when Grandpa talks while teaching, and it takes his voice from here.

## Decision cards (user's words, verbatim)

| ID | Question | Answer |
|---|---|---|
| D1 | Face style for every person | "c and change the zombie way" → C, dot eyes + brows + blush |
| Z1 | The new zombie look (asked after D1) | "A Grumpy (Recommended)" |
| D2 | Player, Farm Kid → President | "C Grows up" |
| D3 | Grandpa Bovine | "A Cow farmer" |
| D4 | Chad Cornwell | "B Corn-cob hair (Recommended)" |
| D5 | Joke zombies at phone size | "B Own shape + prop (Recommended)" |
| D6 | Helpers | "B Teen interns (Recommended)" |
| D7 | Bosses | "C Mascot suit (Recommended)" |
| D8 | New joke zombies (multi-select) | "Zombie Granny" |

Not picked, so not built: the googly faces (D1 A), the hair-growth ladder (D2 B), Florida grandpa (D3 C), Coupon Clipper, Tourist, Gym Bro and Mime (D8).

---

## 0. Shared rules (every character)

### Base body: `drawPerson`, unchanged geometry
Feet at `(x, y)`; `f` = facing ±1. At scale 1:
- shadow `ell(x, y, 13, 5)` `rgba(0,0,0,.18)`;
- legs 7×16 r3 at `x-8` and `x+1`, top `y-17`. Walk stride `sw = sin(walk)·4` lifts one leg;
- shoes 9×5 r2 `#3a2a20` at `x-9` and `x`, `y-4`;
- torso `rr(x-10, y-36, 20, 22, 7)`;
- hands `circ(x±11, y-22, 3.5)` in skin;
- head `circ(x, y-46, 10)`;
- hair `arc(x, y-47, 10.6, 1.05π → 1.95π)`.

The knobs used below are `bodyW` (torso width), `bodyH`, `legH`, `headR`, `neck` and `lean`. They default to 20 / 22 / 16 / 10 / 0 / 0, which reproduces today's body exactly. Hip = `y - legH`; torso top = `hip - bodyH + 2`; head centre = `top - headR - neck`.

### Face style C (D1): every human and every non-zombie
Let `ex = hx + f·3·s`, `ey = hy + s`, `s = headR/10`.
- **Eyes:** two dots r `1.3s` `#2b1d14` at `ex ± 2.6s` (as today).
- **Brows:** two strokes, width `1.8s`, `#2b1d14`. Left from `(ex-4.5s, ey-4.2s)` to `(ex-1s, ey-3.4s)`; the right one is its mirror.
- **Blush:** `rgba(255,110,120,.45)` ellipses 2.4s×1.5s at `(ex-5s, ey+3.5s)` and `(ex+5.5s, ey+3.5s)`.
- **Brow moods** (the main acting tool; rotate each brow about its outer end):
  - neutral 0°;
  - happy, outer ends up 10°;
  - angry, inner ends down 20°;
  - worried, inner ends up 20°;
  - shocked, both brows +2s higher.
- **Mouth:** none by default (as today). Add one only for a beat: `o` (ellipse 1.6s×2s) on surprise, a smile arc r2.6s on a sale, `yell` on anger.
- **Blink:** every 3–5 s (random), the eyes become 2.4s×0.8s lines for 0.12 s.

### Phone-size readability (the bar for every character)
- **Silhouette test.** Fill the character solid black at 1× (about 60 px tall). It must still be identifiable. Identity comes from **one signature shape that breaks the body outline by ≥ 6 px**: hair, a prop or a body shape. Faces are flavour, never identity.
- **Height cap:** 100 px including props at 1×, so carried stacks and the HUD stay visible. Banners and poles may lean outside the cap; heads may not.
- **One accent colour per character** that no neighbour shares. Zombie skin `#7fb04a` is reserved: no green shirts on zombies, and no `#7fb04a`-ish skin on humans.
- **Text on bodies** (name tags, sashes, bibs) is decoration. It must not be needed to identify anyone.

### Animation beats (shared; per-character extras below)
| Beat | Spec |
|---|---|
| Idle | 1 px breathing bob at 0.5 Hz, blink, brows neutral |
| Walk | today's stride (`sin(walk)·4`), plus a 1 px body bob at stride peaks |
| Carry | stack anchored at `(x + f·12·scale, y - 22·scale)` (as today); brows worried when the stack is ≥ 80% of capacity |
| React | sale: brows happy + 4 px hop (0.2 s). Robbed or bitten: brows shocked + mouth `o` + 2 px shake (0.3 s). Upgrade bought: brows happy + smile for 1 s |

---

## 1. The player: Farm Kid → President (D2 = C, "grows up")

Image: `player.png`.

**Personality:** an earnest overachiever who takes every job dead seriously, from milking to world leader. They never speak; Grandpa and Chad do the talking. The comedy is the kid in a hard hat and the gradually taller politician.

**Hook:** "Started with three cows. Ended with three Secret Service agents."

**Growth (draw scale only):**
- `scale = 0.88 + 0.038·i`, with i = 0 for chapter 1 up to i = 9 for President: 0.88, 0.918 … 1.22;
- chapters 1–2 also use `headR 11` for kid proportions;
- the collision radius, hitbox and stack capacity **do not change**, only the drawing does;
- the stack anchor, hands and hat scale with the body.

**Constants:** orange hair `#e0702a` with the bun (`circ(hx-f·8, hy-7, 5.5)`), skin `#f6cfa8`. The bun is the player's signature shape in every chapter. Hats sit on top of it and never hide it.

| i | Chapter | Shirt | Pants | Over-layer | Hat / extra |
|---|---|---|---|---|---|
| 0 | Farm Kid | `#fbfbf7` | `#4a6fa5` | red vest `#d23b2e` (6 px side panels) | — |
| 1 | Farmer | `#c0504d` | `#4a6fa5` | denim overalls `#4a6fa5`: bib from 45% torso height, 3 px straps, `#f2c230` buttons r1.3 | straw hat `#e9c46a` (brim ell 1.75hr×.45hr, crown .95hr×.6hr), band `#c0392b` |
| 2 | Baker | `#fbfbf7` | `#5b4636` | white apron with two flour dots `rgba(230,200,150,.8)` | chef toque (3 puffs, 1.6hr wide) |
| 3 | Store Owner | `#c0392b` | `#3d3d5c` | white name tag "BOSS" | cap `#f2c230` |
| 4 | Tycoon | `#2f3b55` | `#2f3b55` | hi-vis vest `#f28c28`, tie `#c0392b` | hard hat `#f2c230`, ridge `#d9a21b` |
| 5 | Mayor | `#2f3b55` | `#2f3b55` | tie `#c0392b`, white sash (6 px diagonal) "MAYOR" | — |
| 6 | Governor | `#3a3f4b` | `#3a3f4b` | tie `#2f6fd6`, white sash "GOV" | sunglasses `#111` |
| 7 | Senator | `#2f3b55` | `#2f3b55` | tie `#c0392b`, flag pin | briefcase `#6b4423` 12×9 in the front hand |
| 8 | Candidate | `#2f3b55` | `#2f3b55` | tie `#c0392b`, blue rosette `#2f6fd6` / white / red | — |
| 9 | President | `#1b1b2b` | `#1b1b2b` | tie `#c0392b`, gold sash `#e0b13a` | top hat `#1b1b2b` with a `#c0392b` band (the existing `tophat` art at 0.8) |

- A wardrobe hat (`SET.hat`) replaces the chapter hat when one is worn.
- This table **replaces** the prototype's `playerLook()` mapping (which only changed shirt colours from chapter 3 on).

**Extra beats:**
- On a chapter promotion, a 0.6 s "costume spin": the old outfit, a white puff, the new outfit, and 0.05 more height.
- From chapter 6 on, the idle pose holds a wave (front hand raised 6 px) every ~8 s. Politicians wave at nobody.

---

## 2. Grandpa Bovine, narrator (D3 = A, "Cow farmer")

Image: `grandpa.png` (full body, the 56 px round HUD portrait, the dialog portrait).

**Who:** your grandfather, who is a cow. Nobody in town finds this strange. He "left you a corn patch and three cows" (the chapter-1 intro) and now narrates from the corner of the screen. He tells tall tales and is proud of you in a backhanded way. Cow puns, but at most one per three lines.

**Hook:** "Back in my day we milked by HAND. Well. By hoof."

**Catchphrases** (tutorial.md picks the teaching lines; these set the voice):
- "Moo-ve it, kiddo."
- "In my day, corn was taller and money was money."
- "That's not how I'd do it. That's better than how I'd do it."
- "Your grandma would be proud. Of me, for teaching you."

**Look** (`person()` with `headFn`; the body at default proportions):
- shirt `#f4f1e6`, denim overalls `#4a6fa5` (as chapter-1 Farmer above), pants `#4a6fa5`, shoes `#3a2a20`, hands `#fbfbfb` (hooves, white);
- **cow head** (the `drawCow` head, standing upright) at the head centre:
  - horns `#f3e3c3`: triangles `(±5,−8) (±9,−16) (±1,−9)`;
  - ears `#fbfbfb`: ell 5×2.6 at `(±11, −4)`, rotated ±0.4;
  - skull ell 11×11 `#fbfbfb`; patch `#2b2b2b` ell 5×4 at `(−f·4, −5)`;
  - muzzle `#f4a3b4` ell 8×5.5 at `(f·2, +6)`; nostrils `#b05a6a` r1.2;
  - eyes r1.5 `#2b1d14` at `(f·2 ± 3.5, −1)`;
- **white mustache** `#f4f4f4`: two ell 5.5×2.4 at `(f·2 ± 5, +3.5)`, tilted ±0.3;
- **round glasses**: two circles r3.4, 1.3 px `#2b1d14`;
- **straw hat**, the same art as the Farmer chapter, 6 px higher;
- **cane** `#6b4423`, 2.5 px, a straight shaft at `x + f·14` from the feet to the hook (r4 arc at the top).

**Silhouette:** the horns plus the hat brim plus the cane. He reads as "old cow farmer" in solid black.

**Portraits:**
- HUD bubble (tutorial.md §3): a 56 px circle, white ring 3 px plus a `#6b4423` 3 px stroke, background `#bfe3a8`, bust at 2.6× cropped to hat-to-chest.
- Dialog/newspaper cards: a 240×150 frame, 4 px `#6b4423`, bust at 3×.

**Beats:**
- Talking: the mustache wiggles (scaleY 1 ↔ 0.85 at 8 Hz) and the portrait wobbles ±3° per blip.
- Proud: the glasses flash white for 0.15 s.
- Disapproving: brows angry; the cane taps (portrait dips 2 px twice).
- Idle in the world (if he ever visits the farm): leans on the cane and chews (the muzzle bobs 1 px at 2 Hz).

---

## 3. Chad Cornwell, the rival (D4 = B, "Corn-cob hair")

Image: `chad.png`.

**Who:** the kid from the next farm over who is always exactly one step ahead and never lets you forget it. His dad bought him everything. He grows up alongside you, from farm brat to your opponent for President. He is smug, fragile and secretly jealous. The running gag: **he is inside every boss mascot suit** (§7).

**Hook:** "Corn-gratulations, loser."

**Catchphrases:**
- "My dad has TWO dairies."
- "Nice farm. For a starter farm."
- "I'm not jealous. You're jealous."
- (unmasked after a boss) "...this was Dad's idea."
- (debate, chapter 9) "My opponent can't even spell 'corn'."

**Look:**
- skin `#ffdbac`, purple suit `#8e44ad` (kid) / `#6c2d91` (grown-up), pants `#2f3b55`, tie `#f2c230`; grown-up adds a gold lapel pin `#f2c230` r2.4;
- face style C with a **smug mouth**: polyline `(ex-3s, ey+5.2s) → (ex+1s, same) → (ex+3.5s, ey+3.2s)`, 1.3 px. Brows default to "smug" (one brow raised 2s).
- **Corn-cob hair** (the signature):
  - husk sideburns `#3d8b37`: quadratic curves from `(hx±hr, hy+3)` sweeping up to the cob base;
  - cob ell `rx 0.8·hr`, `ry 1.35·hr`, `#f2c230`, centred at `(hx − f, hy − hr − 7s)`;
  - kernels `#d9a21b` r1.1s, a 3×7 grid at 4s × 3.6s spacing;
  - yellow cap of hair `arc(hx, hy−1, hr+.6, 1.05π → 1.95π)`.
- **Growth:** Chad is always drawn at the player's *next* chapter scale (`0.88 + 0.038·(i+1)`). He is literally a bit taller than you.
- Shares the existing `kind:'rival'` robber's purple/blond palette, so when politics chapters spawn the rival robber, it is Chad (keep the "ME!" sign).

**Beats:**
- Brag: a hair flick (the cob tilts 15° and springs back over 0.3 s).
- Loses: the cob droops (rotates 25° forward) and the brows go worried.
- Walks with a 2° backward lean (`lean -2`): too cool.

**Where he appears:**
- chapter-intro newspaper cards ("CORNWELL BUYS SECOND DAIRY");
- the rival robber kind;
- inside every boss suit;
- the chapter-9 debate opponent.

---

## 4. Helpers: teen interns (D6 = B)

Image: `helpers.png`.

**Who:** summer interns who were promised "exposure". Helpful, underpaid, frequently asleep.

**Hook:** "TRAINEE. Since 2019."

**Look:**
- keep `HELPER_LOOKS` (shirts `#3e8e5a` / `#e0a030` / `#6a4c93`, the same pants, skin and hair) with face style C;
- cap in their colour (`#2f6fd6` / `#c0392b` / `#2e8b57`) with **"MOO"** in white 7 px on the crown;
- white name tag 11×6 at `(x−9, top+4)`, text 4.5 px `#2f6fd6`: "TRAINEE", "NEW!", "???" (by helper index mod 3).

**Beats:**
- **Nap:** any helper idle ≥ 4 s (nothing to fetch) falls asleep:
  - eyelids: the skin colour covers the top half of each eye, plus a 1 px line;
  - mouth `o`;
  - a floating "z" (10 px) and "Z" (13 px), white with a `#3a2412` outline, drifting up and fading over 1.5 s on loop.
- **Wake-up:** the moment work appears, a "!" pops, the brows go shocked, and they hop 3 px before moving.
- Carry: as today. Brows worried at a full stack.
- Delivery: a tiny fist pump (front hand +5 px for 0.2 s).

**Later idea (not chosen now):** cured zombies hired as clumsy staff (D6 C). Revisit after night ships.

---

## 5. Zombies (Z1 = A, "Grumpy")

Image: `zombies.png`.

**Base zombie:**
- skin `#7fb04a`, random `SHIRTS` minus greens, pants `#3d3d5c`;
- arms forward (`zombieArms`, as today);
- **torn hem**: the bottom 3.5 px of the shirt is a zigzag of 4 teeth, 5 px wide (draw it as the torso polygon, not ground-coloured triangles).

**Grumpy face** (replaces the ✕ eyes), with `ex, ey, s` as in §0:
- eye bags `rgba(70,30,90,.45)` ell 2.6s×1.4s at `(ex±2.8s, ey+2.2s)`;
- eye whites r1.9s at `(ex±2.8s, ey)`;
- red pupils `#c0392b` r0.9s;
- **angry brows** 1.9s wide: from `(ex−5s, ey−4.6s)` to `(ex−1s, ey−2.6s)`, mirrored;
- mouth: a dark ellipse 3s×2s at `(ex, ey+6s)` with two white buck teeth 1.4s×1.6s.

**Beats:**
- Shamble at today's walk × 0.6, with a 2° side-to-side head tilt.
- Bite windup: shake (as today) plus mouth open wider (ellipse 3s×3s) plus "!".
- Hit: white flash (as today) plus brows shocked.
- **Cured:** zombie skin blends back to human over 0.4 s, brows go from angry to worried, and they say a confused line ("Why do I want brains?").

**Customers turning** (`drawTurning`): the skin blends toward `#7fb04a` as today, and the brows move from neutral to worried (t > 0.4) to angry (t > 0.75). You can read their mood before they turn.

### Joke zombies (D5 = B: own body shape + bigger prop)
Each has a unique **body shape** *and* a prop. Lines as in `ZTYPES`.

| Type | Body knobs | Colours | Signature prop / shape | Extra beat |
|---|---|---|---|---|
| **Karen** | legH 19, bodyH 25, bodyW 18 (tall, thin) | shirt `#8e44ad`, hair `#e8c050` | **giant asymmetric bob** at 1.35× today's: ell(hx−f·8.1, hy−12.2, 20.3×13.5) + ell(hx+f·8.1, hy−18.9, 14.9×10.8) + side lock ell 5×12.2; sunglasses pushed onto her face; red handbag `#c0392b` 9×8 at the hip | mouth `yell` while saying a line; the finger points at you (front arm 4 px higher) |
| **Lactose** | round torso ell 15×13 (bodyW 30, bodyH 24), legH 11, headR 9.5 | shirt `#f4f1e6` | **🥛 with a red slash** (`#e23b3b`, 3 px) above the head; a tummy spiral `#5a8a30`; sweat drop `#9fd6ff` | frown; arms 4 px lower (clutching the belly); recoils 6 px from milk |
| **Influencer** | bodyW 15, neck 6, legH 18 (skinny, long neck) | shirt `#ff5ea8` | **selfie stick + ring light**: stick `#444` 2 px from the hand to `(x+f·26, top−26)`; glow `#fff7c0` r9 plus a white ring r11 2.5 px; phone `#222` 6×10; backwards cap `#111` | duck lips `#ff5ea8`; the ring light pulses (r9 ↔ 10.5, 2 Hz); a camera-flash frame when saying a line |
| **Vaulter** | legH 25, bodyW 17, lean +4 (long legs, leaning forward) | shirt `#f28c28` | **long pole** `#c99a2e` 4 px from `(x+f·26, y−4)` to `(x−f·30, y−70)`; white headband 3.5 px; bib "7" (white 10×9, red text) | the pole vault arc (existing) |
| **Flag** | default body, mouth `grin` | shirt `#5b4636` | **big banner** `#e23b3b` 80×30 on a `#6b4423` pole 3 px, 96 px tall; "BRAINS & SAMPLES" white 8.6 px | the banner waves (skewY ±4° at 1.5 Hz) |
| **Zombie Granny** (new, D8) | default body | shirt `#c77dbb`, hair `#e8e8e8` plus bun | **knitting**: needles `#aaa` 1.5 px crossing toward the front, a red yarn ball `#e23b3b` r5; round glasses over the grumpy face | see below |

**Zombie Granny** (D8; the rules are *provisional* and need the economy designer's sign-off):
- Gag: she's terrifying and also wants to feed you.
- Lines: "You look hungry, dear." / "Eat your vegetables. Then BRAINS." / "I knitted you a scarf!" / "Back in my day, zombies had manners."
- Rule twist: walk speed ×0.7, HP +2, `ZTYPES` weight ~8 (taken from `normal`).
- Cured: she hands you a scarf. A new wardrobe hat, "Granny's scarf" (a red scarf drawn around the neck), unlocks the first time. This is separate from the existing granny-race wig.
- Silhouette: the bun plus the yarn ball and needles. It must not be confused with the daytime Granny racer, who rides a scooter and has no needles.

---

## 6. Gary, the practice zombie (*provisional*, for the tutorial)

Image: `gary.png`. Needed by `tutorial.md` (the first-night beat). Not on a card. Claude designed him from the tutorial's brief ("a scarecrow in a cheap zombie costume").

- **Body:**
  - burlap skin `#d9b77a`, so his hands are burlap too;
  - plaid shirt `#c0504d` with `#8a3a30` 1.5 px grid lines and a yellow patch `#e9c46a` 6×6;
  - jeans `#5b7aa5`, boots `#6b4423`;
  - straw tufts `#e9c46a` poke out of the sleeves (three 5 px spikes each side) and the head (seven spikes).
- **The cheap mask:** a too-small green rubber mask `#7fb04a` covers only the top 60% of the head; a black elastic (0.8 px) runs across it; it has grumpy-zombie eyes and brows printed on. Below it, his stitched burlap smile (an arc plus five 0.8 px stitches) shows. He is happy to be here.
- **Beats:**
  - waves while waiting (zombie arms bob 3 px at 1 Hz);
  - **hit: he bursts into straw**: 18 straw sticks 8×1.6 fly out radially, the mask flies off, the shirt and jeans lie flat, and the burlap head smiles;
  - trip (tutorial step 5): he falls forward and plays the same burst.
- **Hook:** "Practice zombie. He's corn."

---

## 7. Bosses: mascot suits (D7 = C)

Image: `bosses.png` (Cornelius, The Big Cheese, and the defeat beat).

**Concept:** every blood-moon boss is **a guy in a foam mascot suit** of the chapter's product. Sneakers show at the bottom, and a sweaty human face shows through a hole. When beaten, **the head pops off: it's Chad Cornwell** (sabotaging you again, on Dad's orders).

**Suit construction** (scale 1 = the preview's 1.7× drawing at 1×, about 110 px tall; the height cap is waived for bosses):
- **Legs:** two navy `#3d3d5c` 8×14 stubs plus white sneakers 12×6 with a red `#e23b3b` 1.5 px stripe.
- **Foam body:** the product, code-drawn, with printed eyes (white r ~7 with pupils, 1 px outline; googly is fine here because it's a costume) and thick printed angry brows (4 px `#2b1d14`). Arms are the product's natural flaps (corn husks; foam stubs on the cheese).
- **Face hole:** a `#3a2412` ell 10×11 rim, a human face `#ffdbac` r8 inside, dot eyes, a flat 1 px mouth and a sweat drop `#9fd6ff` 1.6×2.6. The hole sits low on the costume (in the "chest"), like a real mascot suit.
- **Zipper:** a dashed 1.5 px `#888` line down one side.
- **Phone readability:** the product shape is the silhouette. The blood-moon red glow ring (today's `rgba(255,60,80,.35)`) stays behind it.

| Ch | Boss (`BOSSES`) | Suit shape (code-drawn) |
|---|---|---|
| 1 | Cornelius the Kaiju Cob | cob ell 22×46 `#f2c230` with a `#d9a21b` kernel grid; husks `#3d8b37` as arms (see `cobBody`) |
| 2 | The Big Cheese | wedge polygon `(−40,−8) (40,−8) (40,−50) (−40,−86)` `#ffcf3f`, holes `#e6a91a` (see `cheeseBody`) |
| 3 | The Sourdough Starter | a loaf dome (ell 40×30 `#c8873a`) with three score marks and a bubbling top *(provisional)* |
| 4 | Mega Raccoon Mech | a grey box robot with the raccoon mask stripe; antenna *(provisional)* |
| 5 | The Rust Golem | brown-grey stacked rounded rects, a bolt on the head *(provisional)* |
| 6 | The Attack-Ad Blimp | a horizontal ellipse blimp with "VOTE NO" text; tiny fins *(provisional)* |
| 7 | The Spin Doctor | a TV box with a spiral screen *(provisional)* |
| 8 | The Filibuster | a giant scroll, unrolling at the bottom *(provisional)* |
| 9 | The Alien Ambassador | a green dome head with antennae (reuse the `antenna` hat art) *(provisional)* |

**Defeat beat** (about 1.4 s):
1. The suit head flies off in an arc: 0.6 s, one full spin, landing on its side.
2. Chad stands in the suit's bottom half, with brows shocked and mouth `o`.
3. Speech bubble with a per-chapter line (first: "...this was Dad's idea." Others: "I can explain." / "This is a rental." / "Don't tell the press.").
4. Chad runs off at 2× speed; the trophy drops as today.

From chapter 6 on, the bubble can reference the campaign ("Off the record?").

---

## 8. Supporting cast (*provisional*: no card asked; minimal change)

Image: `support.png`.

| Who | Look | Change |
|---|---|---|
| **Customers** | today's random `SHIRTS` / pants / skins / hairs, 40% straw hat | face style C; brow moods while waiting (§5 "Customers turning") |
| **Granny racer** | `#c77dbb` shirt, `#e8e8e8` bun, scooter | face style C, mouth `grin`; she trash-talks ("Eat my dust, sweetie!") |
| **Bandit robber** | black shirt with white stripes, mask, loot bag | face style C under the mask (brows only; they show above it) |
| **Taxman** | grey suit `#5b6472`, blue tie, top hat, briefcase | face style C, permanently "disappointed" brows (inner ends up 10°) |
| **Raccoon** | today's | angry 1.6 px brows over the mask |
| **Rival robber** | = Chad (§3) | — |
| **Cow** | today's Holstein | adds a cowbell `#e0b13a` (a trapezoid 8→10×6 under the chin); dot eyes plus one 1 px brow while eating (the "content" brow) |
| **Hen** | today's | one 1 px brow (angry); a feather puff when startled |
| **Dog** | today's | + a 1.3 px eye; tail wag 15 Hz (as today) |
| **Courier** | today's | face style C |

---

## Backlog hooks (for Codex; see `tasks/backlog.md`)
These are build items. Night and zombie art lands with the night port (the Now item). Other pieces land whenever their system is ported.
