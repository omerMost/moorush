# 2026-10-03 — v3 published, cheat codes, v4 solid world, v5 main menu

> **Imported** from claude.ai chat "Creating a game from an ad" (https://claude.ai/chat/645c8425-a2a0-41fb-9c03-2908bc0973e1, shared copy https://claude.ai/share/619469d2-2ba6-44c5-bf35-61d6c89a62d0). The work happened before this repo existed, and the times are the chat's real message times (local +03:00). The code lived in the claude.ai artifact https://claude.ai/artifact/YFNZ2jPt6E6tRczYqF74EY and is now `prototype/index.html`.

## What happened
- **v3 published** ("Version 3 · one big world").
- **Cheat codes:** the user asked "where can i put the cheat code to gain the money." Tap the coin counter 5×, then enter `MOOLAH` (+1k), `RICH` (+100k), `BILLIONAIRE` (+10M), `VOTES` (+10k) or `NEXT` (skip a chapter). A **version label** was added under Play.
- **v4 "solid world":** the user said "trees blocked your way and you can't get inside them and none of the things i have asked."
  - Trees, ponds, pens, counters, trucks and the White House are now solid, and clouds act as walls.
  - Workers path around obstacles. v3 saves migrate, and a player saved inside an obstacle gets pushed out.
  - A bot reached President, after fixes for 3 loops: only pick up what something needs, the arrow points at coins when your hands are full, and parked trucks can be walked around.
- **v5 main menu:** the user said "no main form… play, save slots, settings, levels."
  - Menu items: Continue, New game, **3 save slots** (delete needs two taps), **Levels** (jump to unlocked chapters), **Settings** (sound, vibration, guide arrow, camera Close/Normal/Far, cheat box, Save now), How to play. In-game ☰ saves and opens the menu. Added SFX.

## Lessons
- **"I don't see the changes" came up repeatedly.** The claude.ai app showed cached old copies. Fixes: the version label on the menu, and telling the user to open the link in a phone browser.
