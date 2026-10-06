# Backlog

Active, actionable work. One bullet = one chunk you could pick up and finish in a session. **Cross items off and move them to `done.md` with the date in the same turn you finish them** — the backlog must reflect current reality.

## Now

_(Mid-flight or top-priority. Usually 1–3 items.)_

- [ ] **Rebuild the test suite in the repo (ADR 0002, the first milestone).** The chat's bots and feature tests weren't exported. Needed: a headless runner (Playwright or similar) that drives `window.__moo`, a full-career bot (Farm Kid → President), the "every counter sells unattended" test, the reachability test, save round-trip tests, the zombie chase test and the v9 feature tests. One command (`check.sh`) runs all of it.
- [ ] **Decide the native-app engine and write an ADR** (Godot 4 port, Capacitor, …). Blast Ranger's ADR 0002 is the reference.
- [ ] **The fun core:** the 2-second loop versus the one big world. Decide with the user (`research/fun-additions.md`, item #2 is unbuilt).
- [ ] Replace the placeholder icon mark in `scripts/generate-icons.js` when the brand exists, re-run it

## Next

_(Approved, ready to pick up, not started yet.)_

- [ ] Make it work offline: bundle the Baloo 2 font locally
- [ ] Test the two untested v9 cases: the debate timer running out, and MOO FEVER exactly doubling prices
- [ ] Decide on the old public artifact link (republish it from the repo or retire it)

## Later / stretch

_(Parking lot. Ideas, nice-to-haves, things you'd do if everything else were done.)_

- [ ] Research ideas not yet built (`research/`): one-thumb mode, a lunger zombie, safe zones, the dawn payout screen, secret characters, a cow-breed album, the Grandpa Bovine narrator and the rival Chad Cornwell, share cards, weekly mutators, Cow Cannon fast travel, the Tower of Babel stack
