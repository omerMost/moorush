# Soak interruption validation and device follow-up

## Changes
- Continued the already-landed 0.3.5 lifecycle work (bed5f84). No Godot runtime change in this follow-up. Collector now records OS suspension markers and rejects brief app switches even when foreground checkpoints all appear true.
- Added reproducible stdlib CLI tests using fake ADB/clock: stable collection, a hidden mid-window suspension, transient USB recovery, changed app process. No device interaction in these tests.
- Updated STATE/architecture/ADR/playtest/backlog/done with current evidence. Existing 03:17 landing note remains unchanged.

## Checks
- Full current Godot runtime: ./check.sh GREEN, eleven suites plus import/boot (build/lifecycle-check.log); lifecycle suite has 22 real-scene assertions. No runtime code changed after this verified landing.
- Python syntax and four functional CLI tests pass (`python3 scripts/tests/test_android_soak.py`). The test was promoted from ignored QA output; adjusted its repository-root path and reran clean. git diff --check clean.
- Signed 0.3.5 export/signature verification/install Success. Slot 1 and sound settings byte-identical across install. Actual Home save stays unchanged while backgrounded; force-stop/cold menu retains exact bytes and resumed wallet/capacity/chapter/payment keys/held items/position match. Live screenshots reviewed; Android logs show suspend/resume with active slot and menu state retained.
- Same-process resumed capture: 600.3s wall, 73 gameplay windows, mean 57.13 engine FPS, mean window p95 18.37ms/draw CPU 10.98ms. Invalid uninterrupted run: another coloring app repeatedly takes the phone; recovery also estimated an earlier missing start epoch. Fresh capture: 14 windows, mean 57.06 FPS/p95 18.25ms/draw CPU 11.00ms, also interrupted by coloring app; stopped only root-owned collector at 184.0s. Neither establishes 10-minute continuous gameplay or thermal causality. No captured app errors.
- Read-only populated three-district idle diagnostic: all 34 pads/13 helpers/four belts/six counters, 1,200 simulated seconds, departure peak 9; every 300s checkpoint has zero empty queued/departure paths. All counters sell, including impatient cheese departures. No accumulation reproduced. Paint caches have finite bounds; speculative hotpaths do not justify runtime changes here.
- Logs, phone backups and diagnostic fixtures stay ignored. The active coloring app was not stopped, altered or messaged. Lock/wake and uninterrupted soak remain in backlog pending exclusive phone availability.

## Dialogue trace
- User: "what next ?", then "ok continue" after lifecycle and sustained Android testing were proposed.
- Root requested reconnect/unlock when USB disappeared and the screen was securely locked; the phone later became unlocked and real Home/cold-reopen checks completed.
- Root asked which game should use the phone after the coloring app interrupted the performance run. No answer in this turn. A fresh attempt after Moo Rush returned to foreground was interrupted again; root preserved partial evidence and stopped its collector instead of reporting a completed continuous test.
