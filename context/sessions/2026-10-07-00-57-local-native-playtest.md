# Local native Chapter 1 playtest

**Agent:** Codex root, no subagents.

## What changed
- Launched native game on this Mac. Desktop automation initially selected Godot Project Manager; a disposable locally signed app copy under ignored build/ allowed direct game menu interaction.
- Exercised fresh New Game, menu/save and Resume through the native UI. Brief keyboard/drag automation did not visibly confirm player movement; no product bug inferred from that tooling limitation.
- Added optional windowed career test under godot/tests/: main scene + real movement guide bot, isolated test storage, rendered captures at 90s/240s/completion. Output under ignored build/.
- Updated README, STATE and architecture to document this reusable display-dependent check. No game behavior changed.

## Checks
- ./check.sh GREEN: import/boot and four headless suites (gate 430.9s; unattended milk/egg sales; complete persisted save/slot coverage; phone-sized touch/menu).
- Windowed career PASS: gate at 421.7 simulated seconds; rendered 90s, 240s and completion screenshots inspected; no engine errors in build/windowed-playtest.log.
- No Android test performed; no new design/fun claim. Native game still has the documented provisional audio/combat/later-chapter exclusions.

## Dialogue trace
- User: "play it on hear and test it"
- User after interruption: "ok continue"
