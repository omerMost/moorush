# Chapter 3 Baker port

## Changes
- Codex root extended persistent world/progression/navigation/save limits using STAGE_COUNT. Content specialist copied Baker's seven modules/twelve pads from the frozen HTML; view specialist added wheat/apple fields, four cached products, chapter labels/travel and rendered test; QA specialist extended natural careers, populated saves and navigation checks.
- Wheat→bread and apples→pies, four total conveyors, 13 local helper routes and six counters across three districts. Bakery gate opens Baker; supermarket gate ends this slice. Exact prototype tuning: bread 48, pie 88, supermarket 25,000.
- Older completed endpoints open the next implemented district without granting its upgrades. Keyed payments and old 10/22-pad array prefixes preserve partial payments. ADR 0010 supersedes ADR 0008's two-district limit; choices remain provisional pending Chapter 3 device playtest.
- Architecture/STATE/backlog/done updated. Farmer night taco content and night/combat remain queued; subsequent chapter scope is now 4–9.
- Signed Android 0.3.0 installed and opened on POCO, preserving existing app data and sound OFF preference. Slot 1 resumed in Farmer with 1,589 coins/capacity 14 and 34 payment entries; existing payments preserved, Baker upgrades unpaid. No money or progression injected into the real phone.

## Checks
- `./check.sh`: GREEN, eight suites plus import/boot. Farm gate 409.9 simulated seconds; full three-chapter gate 4,473.3s, plus 300s unattended production. All 34 pads bought naturally, four belts/13 routes/six selling counters checked; travel 0/1/2 works and 3 is refused.
- Populated three-slot round-trips/reset isolation, older farm/dairy completion migration, and exact partial-payment 10/22-pad arrays pass. Actual phone save backed up under ignored build/ and independently loaded before installation: wallet/capacity/prior payments/stable inventories preserved.
- All 34 incremental navigation masks match full rebuilds; upgrade camera stays steady. Touch HUD/audio/font checks pass at 1080×1920 and 1440×2560, including pointer-driven Baker travel and three-button menu fit.
- Natural rendered bakery bot PASS at 2,770.6s: bread stock 63/sales 37,488, pie stock 57/sales 440. Root inspected bread/pie ovens, wheat/apple fields and corrected v0.3.0 menu screenshots; old-farm travel passed.
- Export and APK signature verification pass (explicit JDK17 required by shell apksigner). Install Success, cold launch 629ms, Vulkan/Mali-G720 starts without Godot script errors. Phone menu/playing screenshots inspected; actual slot payments intact after resume, mute preference unchanged. Initial five-second engine window 72.6 FPS/p95 14.35ms/draw CPU 8.28ms; sustained performance and Chapter 3 subjective gameplay remain unverified.
- `git diff --check`: clean. No new dependencies or prototype edits; APK/logs/screens/save backups are ignored.

## Dialogue trace
- User: "what is next?"
- Root proposed Chapter 3 Baker followed by night/zombies.
- User: "ok".
- Root continued the approved Baker step, verified all production/progression/saves and installed/opened the update for Android testing. The player's current Farmer save will unlock Baker by buying its bakery gate.
