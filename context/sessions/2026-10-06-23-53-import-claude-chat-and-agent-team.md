# 2026-10-06 — Project created; claude.ai chat imported; own Root Orchestrator team

- **Created with noamcli:** `noamcli new moorush -s none --github private`. The repo is https://github.com/omerMost/moorush (private, `main`).
- **The game:** downloaded the artifact YFNZ2jPt6E6tRczYqF74EY (v9, 2,233 lines) into `prototype/index.html` unchanged.
  - Checked: the menu shows "Version 9 · aim · fever · bosses · hats", there are no console errors, and `window.__moo` is present.
  - The cloud save through `window.claude` is skipped standalone, and localStorage slots work.
- **History:** I read the chat "Creating a game from an ad" (38 messages, 2026-10-03 → 04) through Claude in Chrome and wrote 4 backdated session notes from its real timestamps.
- **Research:** the chat's two reports are condensed into `context/research/`, with what v9 built marked ✅.
  - Getting the full text out by sending it from Chrome to a localhost receiver was blocked by Chrome's local-network check. So the docs are condensed versions, and the full text stays in the chat.
- **Vault:**
  - STATE, tech-stack, system-design and data-flow are written.
  - Backlog Now: rebuild the test suite (the chat's bots weren't exported), the engine ADR, and the fun core (the 2-second loop versus the big world).
  - Next: offline font, the two untested v9 cases, the old artifact link.
- **This project's own Root Orchestrator** (`.claude/settings.json`), separate from Blast Ranger's, with `gameplay-engineer`, `economy-designer` and `qa-playtester`.
  - The user wanted this game "developed under a different root orchestrator."
  - No engine porter yet; that waits for the engine ADR.
- **Pending (asked in the Blast Ranger session):** whether to adopt the friend's methods from `~/Downloads/noamcontext`: Claude commits its own verified work, pushes after each step, and runs overnight with a morning page. Not applied here until the user answers.
