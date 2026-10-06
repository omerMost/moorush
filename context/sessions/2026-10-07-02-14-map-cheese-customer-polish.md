# Cheese, map scenery and customer routes

## Changes
- User-reported Android visuals addressed: cheese now a clearly pointed wedge with a broad triangular face and larger holes, retaining the baked cache. Restored frozen HTML seeded trees/ponds in unused cells, solid circular tree and rectangular pond collisions, depth-sorted trees and clear walking lanes.
- Customers now use cached A* routes for queues and departures. Public traffic adds a crop-bed exclusion mask; player/farm helpers retain harvesting access. Incremental geometry refresh updates both masks and invalidates customer/helper paths. ADR 0011 records the provisional choice; night combat remains separate.
- View specialist owns paint/world and rendered scenery comparison; QA specialist owns customer/scenery and dual-grid tests; root integrated simulation, version/export/check and vault.
- Android 0.3.1 installed and resumed on connected POCO. Real slot backed up; pre/post-install JSON and sound preference identical, 1,589 coins/capacity 14 retained. No progression injection.

## Checks
- `./check.sh` GREEN: nine suites plus import/boot. Natural first gate 409.9s; full three-chapter career 4,650.8s plus 300s unattended production. Populated saves/old prefixes/migrations, audio and phone HUD checks pass.
- Actual queue/purchase/departure and lost-customer routes tested each frame against crop beds; forced routes around both sides of a bed arrive. Tree/pond centers block and real player collision pushes clear; scenery is independent of gameplay RNG and stable across resets. Normal field navigation remains open, public mask blocks it, real corn helper still produces milk.
- Both incremental navigation masks equal full rebuilds for all 34 payment completions/reset/older endpoints; steady upgrade camera preserved.
- Rendered dairy PASS with natural cheese stock/sales; revised wedge reviewed in tray/shop/carry. Scenery render PASS at 1,766.0s on naturally opened Baker land. Root reviewed settled tree/pond scene and old/new cached cheese comparison. Initial optional render bound 1,800s missed pond land on a rerun; raised bound to 3,500s and added diagnostics/fog settling; final clean PASS.
- APK export/signature verification pass, install Success, cold launch 650ms. Phone menu version/playing captures inspected; Vulkan/Mali startup has no Godot script errors. Initial five-second window 60.2 FPS/p95 16.67ms/draw CPU 10.30ms; this is a startup sample, not sustained performance evidence. Subjective cheese/scenery/routing retest remains pending.
- `git diff --check` clean. No dependencies or prototype changes; build outputs/backups ignored. Architecture/STATE/backlog/done/playtest updated.

## Dialogue trace
- User: "cheese looks off and zombies walk inside the garden , also i use to have trees over the map".
- User clarified location: "Android app".
- Root found omitted scenery and straight customer traffic. Native waiting customers already turn green visually; combat remains unported. Implemented the requested garden avoidance for the existing characters and restored scenery; installed the updated build for visual retest.
