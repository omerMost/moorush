extends SceneTree
## Fixed-seed current night/economy snapshot regression. S0/S1 hashes are in sessions.
const DT := 1.0 / 30.0
const TICKS := 36000 # 1,200 simulated seconds, using the chapter-1→3 guide driver.
const EXPECTED_HASH := 3667160503 # S2 health/checkpoint save metadata; seed 23, 1,200s.
const ECONOMY_HASH := 1588353440 # Exact S1 projection without the new S2 fields.

func _init() -> void:
	var sim := MooEconomySim.new(23)
	sim.autosave = false
	var bot := MooBot.new(sim)
	for i in range(TICKS):
		bot.tick(DT)
		sim.update(DT)
	var snapshot := sim.snapshot()
	# Save metadata uses wall-clock milliseconds; exclude it from simulation identity.
	snapshot.t = 0
	var fingerprint := hash(JSON.stringify(snapshot))
	var bought := sim.pads.filter(func(p): return p.paid >= p.cost).size()
	var economy := snapshot.duplicate(true)
	for key in ["hearts", "inv_t", "faint", "checkpoints", "stats", "hats", "rng", "helper_cargo"]: economy.erase(key)
	var ok := fingerprint == EXPECTED_HASH and hash(JSON.stringify(economy)) == ECONOMY_HASH
	print(("PASS" if ok else "FAIL") + " determinism %d money=%d pads=%d T=%.1f" % [fingerprint, sim.S.money, bought, sim.T])
	sim.dispose()
	quit(0 if ok else 1)
