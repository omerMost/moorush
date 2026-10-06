# 2026-10-03 (night) — v1 Moo Rush → v2 Corn to Capitol → v3 one big world

> **Imported** from claude.ai chat "Creating a game from an ad" (https://claude.ai/chat/645c8425-a2a0-41fb-9c03-2908bc0973e1, shared copy https://claude.ai/share/619469d2-2ba6-44c5-bf35-61d6c89a62d0). The work happened before this repo existed, and the times are the chat's real message times (local +03:00). The code lived in the claude.ai artifact https://claude.ai/artifact/YFNZ2jPt6E6tRczYqF74EY and is now `prototype/index.html`.

## What happened
- **v1:** from screenshots of an ad (a Township-style game the user received; "the game is not real lets create it"), I built **Moo Rush** with its own name and look. Drag to walk, harvest corn, feed the cows, carry milk to the counter, serve the customer queue, collect coins, and buy upgrades on green pads. 7 upgrades. Verified by a bot that bought every upgrade.
- **v2 "Corn to Capitol":** the user said "a lot lot more longer… until you are the president of the usa." **9 chapters**: Farm Kid → Farmer → Baker → Store Owner → Tycoon → Mayor → Governor → Senator → Candidate (270 electoral votes). 7–12 upgrades each, with a gold gate pad per chapter (votes in the political chapters), outfit changes, and a crown and fireworks at the end. A perfect bot took about 2 h to reach President.
- **v3 (built, published in the next session):** the user said "not working physically… everything is too tight… one level… save should work… world keeps getting bigger as you advance."
  - **One connected world** of about 4,500 × 4,000, with fog clouds that clear as you buy upgrades.
  - **Real conveyors**: a worker picks from the field onto a belt into the trough. **Trucks** drive in and unload.
  - **A full-state save** to localStorage, plus to the claude.ai account (window.claude db/user).
  - "Toss" bins.
  - Tests: every corn conveyed was matched to a picked plant (88/88), every part was reachable, a 12-minute save reloaded exactly, and a bot reached President in about 2 h (3 stuck spots fixed).

## Lessons
- **Build runs ran out of steps before publishing** (twice in this chat). The user saw old builds and thought nothing had changed. Hence the version label added later.
