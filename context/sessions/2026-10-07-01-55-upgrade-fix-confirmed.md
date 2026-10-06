# Upgrade visual fix confirmed

## Changes
- User confirms the upgrade glitch is gone after Android 0.2.1.
- Updated STATE, playtest, ADR 0009 status/validation and backlog/done. Broader device layout/lifecycle/performance checks remain open.
- No code or APK changes.

## Checks
- Seven-suite `check.sh` GREEN for the unchanged implementation; documentation diff clean.
- User phone comparison is the evidence that the reported visual glitch is resolved.

## Dialogue trace
- Codex: "Try finishing another upgrade and tell me whether the glitch is gone."
- User: "yes".
