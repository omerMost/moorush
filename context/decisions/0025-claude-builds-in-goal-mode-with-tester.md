# ADR 0025 — Claude builds in goal mode, with a Claude tester session

**Status:** Accepted
**Date:** 2026-10-07
**Supersedes:** [ADR 0015](0015-codex-builds-claude-reviews.md) ("Codex builds, Claude reviews").

## Context

The user, verbatim: "continue to develop on a new session claude develop and do what needed while let the other fix moo rush to test the result of your new session, and continue this . give them to work on goal mode".

Codex has finished S0–S3 (the sim split, clock, night actors, hearts, weapons). The designs for the rest of chapters 1–3 are done:
- `design/fun-systems.md`;
- `design/chapter2.md`;
- `design/tutorial.md`;
- `design/characters.md`.

## Decision

- **Builder:** one Claude session ("Build Moo Rush chapters 1–3 in goal mode") owns all code changes in `godot/`, `check.sh` and the tests. It works autonomously toward the north star in `context/runs/2026-10-07-chapters-1-3-complete.md` (ADR 0004 style):
  - it works on branch `run/chapters-1-3`, in its own worktree;
  - it makes one commit per step and pushes the branch after each step.
- **Tester:** the existing Claude session "Fix Moo Rush Android performance drift" first lands its own fix. Then it becomes the tester. For every step the builder pushes, it:
  - runs `check.sh` and the rendered bots on a clean export;
  - checks the step against the design docs' numbers;
  - reports PASS or a numbered fix list to the builder.
  The builder fixes failures before moving on.
- **Codex** stops building in this repo while the run is active, to avoid merge races. The user pauses it. The Codex-driver session stands down.
- **Landing:**
  - The builder merges `origin/main` into the run branch before each step.
  - Every step the tester passes is fast-forwarded to `main` and pushed (ADR 0003).
  - At the end the builder writes `context/morning-page-<date>.md` for the user.
- **Blocked on a user decision:** the builder writes a decision card into the morning page and the backlog, then continues with the next step that doesn't depend on it.

## Alternatives considered

- **Keep Codex as the builder (ADR 0015).** The user asked for Claude to develop.
- **The builder lands on `main` without a tester.** The user explicitly wants the other session to test the results.
- **Builder and tester in one session.** That's weaker verification, and against "a report is a claim, not proof".

## Consequences

- There is one builder at a time, so there are no more overwritten vault edits.
- The Claude review session (the Root Orchestrator) keeps coordinating and reports to the user.
- To return to Codex, or to run both builders, write a new ADR.
