# 2026-10-07 — Claude builds in goal mode, with a tester session (ADR 0025)

- The user asked for a new Claude session to develop, with "the other fix moo rush" session testing its results, in goal mode.
- ADR 0025 supersedes ADR 0015.
- North star and step list: `context/runs/2026-10-07-chapters-1-3-complete.md`, S4a through S11.
- Builder: a new session (chip "Build Moo Rush chapters 1–3 in goal mode") on `run/chapters-1-3`.
- Tester: the perf session, after it lands its own fix. Its ADR renumbers to the next free number after 0025.
- The Codex-driver session was asked to stand down. The user pauses Codex in this repo.

## Checks
- Docs only.

## Dialogue trace
- User: "continue to develop on a new session claude develop and do what needed while let the other fix moo rush to test the result of your new session  , and continue this . give them to work on goal mode"
