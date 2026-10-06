# Chapter 2 daytime dairy port

## Changes
- Codex root integrated two persistent districts/progression, navigation and old save migration. `chapter2_content` added exact Farmer/PM/TUNE content; `chapter2_view` added cached cheese, station drawing, chapter labels/travel and rendered dairy test; `chapter2_qa` added two-chapter bot and populated migration/save coverage.
- Daytime Farmer adds corn→milk→cheese, eggs, helpers and 12 pads. Cheese price 28, bakery gate 8,400. All 22 farm/dairy pads are playable. Old farm keeps producing and retains upgrades/inventories; helpers/conveyors resolve same-district IDs.
- Old Chapter 1 endpoint becomes Farmer ownership, not Chapter 2 completion. Existing keyed saves/ten-pad arrays supported. New navigation spans both districts and blocks the closed world. ADR 0008 records these provisional implementation choices.
- Deferred Farmer night taco module/two pads with night/combat; bakery gate ends this implemented slice until Chapter 3. Backlog/architecture/STATE updated.
- Signed Android 0.2.0 replaces 0.1.3 without app-data reset. Existing sound preference OFF preserved. Phone slot 1 loaded naturally and menu travel to Farmer exercised; migrated phone save has chapter=1, done=false, 2,301 coins, capacity 12 and 22 payment entries.

## Checks
- `./check.sh`: GREEN, six suites. Chapter 1 gate naturally 409.0s; both chapter gates 1,728.2s. All 22 upgrades purchased through real input/earnings; both districts sell unattended over another 300s, nine helper routes use correct inventories.
- Save snapshots round-trip all three slots, both districts/conveyors; old completion opens dairy without granting its upgrades. Test save directories now process-specific after concurrent checks exposed fixture collisions.
- Actual phone save backed up in ignored build/ and migration checked independently: original wallet/capacity/upgrades/stable inventories intact. Installed save reads chapter 1/22 pads after load. No fabricated gameplay progress or injected money.
- Rendered dairy bot naturally produces cheese; press/store/held stacks, customer bubbles, gate preview and menu reviewed. Real travel controls fit. Chapter 1 rendered test updated to stop at first gate and passes at 428.9s.
- Signed export/install Success; cold launch 525ms, Vulkan/Mali startup with no Godot script errors. First screenshot captured before initial frame was black; subsequent menu renders correctly. Chapter 2 subjective phone gameplay remains pending.
- `git diff --check`: clean. No new dependencies, no prototype edits. Build artifacts and save backups remain ignored.

## Dialogue trace
- User: "looks smooth and sound effect works continue".
- Root recorded prior-build smoothness/sound confirmation, continued the approved staged port into daytime Farmer, verified preserving the actual phone save, then installed/opened 0.2.0 for playtesting.
