# Nearest pickup and smooth Toss

## Changes
- Root replaces end-slot tray pickup with nearest arrived exposed item selection. Stable sparse tray IDs keep survivors still; production reserves the first free hole. Crop harvesting selects nearest ripe tile within existing range. QA specialist adds dedicated spatial/concurrency suite.
- Carried incoming transfers use pending tokens and current visible stack height; Toss/drop/conveyors consume arrived goods only. Shared sway-aware stack positions prevent mismatched launch origins. Toss follows a fixed mouth target over a 0.32s eased arc, then shrinks/fades. Timing/presentation choices are provisional (ADR 0013).
- Optional visible `bx.tp` tray positions persist without losing holes. Count-only legacy saves reconstruct contiguous stock. Existing omission of in-flight goods/helper cargo remains.
- Signed Android 0.3.4 (code 11) installed/opened on POCO. Slot 1 wallet 1,589/capacity 14/chapter 1/all prior payments/held cheese 14 and sound OFF match the pre-install backup. No progression injection. STATE/architecture/playtest/backlog/done updated.

## Checks
- `./check.sh` GREEN: ten suites plus import/boot. Natural farm gate 444.6s, supermarket gate 4,632.2s plus 300s unattended production. Saves, older migrations, audio, touch HUD, all 34 incremental upgrade masks and customer crop/tray routes pass.
- Transfer suite: nearest left/right/above and exposed layer pickup, stable holes, nearest ripe crop, first-free output reservation, actual sparse disk save/legacy count restore and incoming-only rejection. Concurrent Toss maintains nonnegative counts, rebases arrival targets and fully settles with no ghost goods. Shared flight poses verify exact start/end, easing, arc, shrink/fade.
- View specialist's isolated native renderer PASS; root inspected `build/transfer-contact-sheet.png` and individual frames. Left/right surviving stock stays fixed; Toss visibly rises then shrinks/fades into mouth. Initial test fixture mistakenly set action accumulator to 999, triggering thousands of actions; corrected to zero before each bounded substep. Contact-sheet Node visibility error also fixed. Final run clean; no runtime changes arose from these test corrections.
- APK export/signature verification/install Success; cold launch 501ms. Phone menu shows 0.3.4; resumed playing screenshot reviewed. Current-PID logs have no Godot script errors/crashes; startup samples 57.2/54.2 FPS (p95 18.06/20.00ms), not sustained performance acceptance.
- `git diff --check` clean. No dependencies/prototype changes. APK/screens/logs/phone backups ignored; optional renderer committed for reproducibility.

## Dialogue trace
- User: "the picking of items algorithm is not right , it just takes from the end and not what close to my chachter".
- User: "also when throwing to the toss bin items its not smooth".
- Root found end-index removal and premature incoming-item disposal/fixed-index arrivals, implemented and verified fixes, installed on phone. Subjective phone feel retest remains pending.
