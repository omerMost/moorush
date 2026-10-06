# Light holders, tray clearance and cheese options

## Changes
- Replaced navy/charcoal output trays with shallow light wooden crates using the same stock/pickup rectangles. View specialist added the shared crate drawing and a preview-only native cheese options renderer; production cheese awaits user selection.
- Root found the prior public mask protected crops but omitted output trays. The old lost-customer goal (counter origin minus 60) lies inside the neighboring tray. Public traffic now excludes active trays plus 25 units; spawn/lost exits use origin minus 8. Blocked public goals retain an empty cached route until destination/geometry changes, avoiding fallback movement/repeated A*.
- QA specialist extended customer suite for real milk/cheese queue and green departures, cross-tray detours, blocked-route cache and normal pickup/delivery. ADR 0012 records provisional choices. C1 decision card offers A classic wedge, B flat slice, C cut wheel; user choice remains pending.
- Android 0.3.2 installed and resumed on POCO. Saved wallet 1,589/capacity 14/chapter 1/all prior payments and sound OFF preference preserved. Backup-to-install JSON differs in time/production/reputation fields because the prior app kept running; no reset or money injection. Architecture/STATE/backlog/done/playtest updated.

## Checks
- `./check.sh` GREEN: nine suites plus import/boot. Farm gate 417.2 simulated seconds; full three-chapter gate 4,521.6s plus 300s unattended production; every upgrade purchased naturally, all counters/saves/old migrations/UI/audio pass.
- Real default-spawn served and green impatient customers at milk/cheese shops stay clear of every active holder plus its margin each frame and depart/remove. Left/right cross-holder detours arrive. Repeated blocked goals search once, remain still, and changing to a safe goal triggers one new route. Actual player pickup and milk-runner delivery pass.
- Both incremental masks match full rebuilds through all 34 upgrades/reset/legacy endpoints, with steady upgrade camera.
- Three cheese options render cleanly with enlarged designs, game-sized stock/carry stacks and actual shared wooden tray/milk example. Root reviewed `build/cheese-options.png`; variants remain preview-only. Natural dairy render PASS at 1,300.4s (cheese stock 60/sales 84); light wood milk/cheese holders inspected. Optional preview initially preloaded World before autoload registration; loading it deferred fixed compilation, final PASS clean.
- Signed export/APK verification pass, install Success, cold launch 768ms. Phone playing screenshot shows lighter holders, Vulkan/Mali startup has no Godot script errors. Initial five-second window 58.6 FPS/p95 16.67ms/draw CPU 10.65ms; sustained performance and subjective tray-route retest remain pending.
- `git diff --check` clean; no dependencies or prototype changes. APK/logs/screens/save backups ignored; preview generator committed for reproducibility.

## Dialogue trace
- User: "i still dont like the black board that holds the items like the milk , chees still not right give me option to pick from of the chees and zombies still get inside the board item holder".
- Root addressed item-holder styling/routing and presented three visual cheese options. Asked for A/B/C through the preference card; no answer at landing. Production cheese is not selected on the user's behalf.
