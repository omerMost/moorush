# ADR 0015 — Codex builds, Claude reviews

**Status:** Superseded by [ADR 0025](0025-claude-builds-in-goal-mode-with-tester.md)
**Date:** 2026-10-07
**Supersedes:** _(none)_. It narrows the Claude Root Orchestrator's role in AGENTS.md while Codex is the active builder.

## Context

After the chapter-1 slice, the user continued development in Codex, in the main checkout (`/Users/omer/prod/moorush`). Claude and Codex both acted as "root" in the same folder. During Claude's review, Codex landed `bed5f84` and then `1bc63a1` in the middle of it. Claude's vault edits only avoided Codex's uncommitted files because it staged by path.

The user answered card C1: "Codex builds, Claude reviews".

## Decision

- **Codex is the builder.** It develops in the main checkout, owns `godot/`, `check.sh` and the work-in-progress vault files (STATE, playtest, its own session notes), and commits and pushes `main` (ADR 0003).
- **Claude is the reviewer.** It never edits game code or tests in the main checkout. It runs `check.sh` and the rendered bots on clean `git archive` exports, reads diffs, and writes:
  - review session notes;
  - backlog items that come out of a review;
  - ADRs for decisions the user makes in Claude's chat.
- Claude stages only its own new or edited files, by path, and never touches files Codex has left uncommitted.
- Decisions the user makes in Claude's chat (decision cards) go into the backlog and session notes, so Codex picks them up from the vault.

## Alternatives considered

- **Separate worktrees, both building.** Two builders mean merge races on STATE and the backlog, and on `sim.gd`. Not needed while Codex leads.
- **Claude takes over again.** The user prefers to keep developing in Codex.

## Consequences

- Claude's specialist agents (`gameplay-engineer`, `economy-designer`, `qa-playtester`) are dormant for game code. Claude can still use them in read-only mode inside its own scratch exports.
- To switch the builder back, or to let both build, write a new ADR.
