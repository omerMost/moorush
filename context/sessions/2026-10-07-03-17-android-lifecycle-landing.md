# Android lifecycle verification and landing

## Changes
- Recorded and landed all pending Android 0.3.5 work: explicit OS focus/pause suspension independent of the slot menu; one entry save, frozen simulation, cleared touch/movement/events and stopped audio. Both callback orders resume correctly while preserving menu state. Implementation choice remains provisional in ADR 0014.
- Added real-scene lifecycle regression to check.sh and a bounded stdlib Android performance collector with interrupted-run recovery. Updated STATE, architecture, playtest, backlog and done records.
- Reviewed existing ignored device artifacts: Home-active/later save bytes match; Home and cold-reopen retain 1,589 coins, capacity 14 and Farmer progression. These observations supplement the earlier locked-device notes.
- Partial performance collection: 36 engine windows over approximately 180s, mean FPS 57.28, mean window p95 18.19ms, mean draw CPU 10.97ms; battery 32.3→33.2°C. Collection ended at 215.4s after adb process lookup failed, with no captured app errors. Full Home/lock/resume acceptance and an uninterrupted 10-minute run remain in backlog. No thermal diagnosis or completed sustained-performance acceptance claimed.

## Checks
- Fresh ./check.sh GREEN: import/boot and all eleven suites. Farm Kid gate 444.6s; three-chapter supermarket gate 4,632.2s, then 300s unattended production; all 34 upgrades purchased naturally.
- Save slots/migrations, phone-size touch HUD, audio, incremental navigation, customer routes, spatial transfers and real-scene suspension/disk reload checks passed.
- git diff --check clean; android_soak.py syntax and --help pass. Device evidence reviewed from prior artifacts; no new phone test performed during this commit request.
- Build outputs, screenshots, logs and phone backups remain ignored. Source, tests and vault files staged explicitly by path for commit and normal fast-forward landing to main.

## Dialogue trace
- Prior feedback recorded in the pending playtest note: user said "what next ?", then "ok continue" after background/lock saves and a 10-minute performance test were proposed.
- Current user: "commit and push all the changes into sessions".
- Root interpreted this as recording pending changes in the session vault and committing/pushing all pending tracked source and new source/test/documentation files. Full device acceptance remains pending; implementation decisions remain provisional.
