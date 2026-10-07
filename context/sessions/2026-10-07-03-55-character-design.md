# Character design: the Moo Rush cast

**Session type:** design, docs only (ADR 0015: Codex builds, Claude reviews and designs). Worktree `claude/magical-meninsky-a5004b`.

## What happened
- Read the cast code in `prototype/index.html`: `PLAYER_LOOK`/`HELPER_LOOKS`/`SHIRTS` L431–433, `drawPerson` L1470, `playerLook` L1485, `drawCow`/`drawHen` L1500–1520, `drawRobber` L1766, `drawDog` L1788, `ZTYPES` L1152, `drawZombie` L1901, `drawBoss` L1921, `BOSSES` L1392, `HATS` L1314.
- Built a throwaway canvas generator that reuses the prototype primitives and the `drawPerson` geometry, with knobs added. Rendered the option sheets with headless Chrome, then showed them to the user in two rounds of decision cards plus a follow-up card for zombies.
- Wrote `context/design/characters.md`: per character, the look in numbers, personality, hook, catchphrases, phone-size rules and animation beats.
- Final reference PNGs are in `docs/design/characters/` (player, grandpa, chad, helpers, zombies, bosses, gary, support), the option sheets in `options/`, and the generator in `cast-preview.html`.
- ADR 0017: the code-drawn cast with brow faces (keeps ADR 0005 G2).
- Backlog: six Codex items (passes 1–2, Gary, Grandpa art, Chad, mascot bosses).
- Coordinated with the parallel tutorial session (`jovial-pascal`, its `design/tutorial.md` is uncommitted):
  - it defers Grandpa's look and voice to this file;
  - I designed its 56 px round HUD portrait and **Gary**, the practice zombie it needs (*provisional*, not carded).
- Left STATE.md alone: Codex owns it (ADR 0015) and nothing about the build surface changed.

## Provisional (Claude's calls)
- Gary's look.
- Zombie Granny's stats (speed ×0.7, HP +2, weight ~8, scarf hat).
- Boss suit shapes for chapters 3–9.
- The supporting-cast tweaks (§8).
- The player's scale numbers `0.88 + 0.038·i`.
- Brow-mood angles.
- Chad drawn at the player's next-chapter scale.

## Checks
- Every sheet was inspected visually after rendering. I fixed overlapping labels, the milk stack covering the helpers' faces, the coupon prop facing the wrong way, the mascot face hole, and the boss head flying off-canvas.
- Each option sheet and final image includes a 1× "phone size" row. All chosen looks stay distinct at 1×: Karen's bob, Lactose's round body, the ring light, the pole and the banner each break the outline.
- No game code touched (`git diff --stat` shows only `context/` and `docs/`). `check.sh` was not run: the change is docs only.

## Dialogue trace
- User: "another one for charchter design"
- Round 1 answers:
  - D1 faces: "c and change the zombie way";
  - D2 player: "C Grows up";
  - D3 Grandpa: "A Cow farmer";
  - D4 Chad: "B Corn-cob hair (Recommended)".
- "change the zombie way" → I rendered card Z1 with three zombie looks in the brows style.
- Round 2 answers:
  - Z1: "A Grumpy (Recommended)";
  - D5: "B Own shape + prop (Recommended)";
  - D6: "B Teen interns (Recommended)";
  - D7: "C Mascot suit (Recommended)".
- D8 (multi-select): "Zombie Granny".
