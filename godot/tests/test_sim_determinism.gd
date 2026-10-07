extends SceneTree
## Pin current saves and keep the pre-S0 economy fingerprint as a separate guard.
const DT := 1.0 / 30.0
const TICKS := 36000 # 1,200 simulated seconds, using the chapter-1→3 guide driver.
const EXPECTED_HASH := 4198937285 # S1 adds persisted day/time/cn; economy hash below stays S0.
const S0_ECONOMY_HASH := 1337840505 # main at 0f1cb8f, before clock metadata.

func _init() -> void:
	var sim := MooSim.new(23)
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
	for key in ["day", "time", "cn"]: economy.erase(key)
	var economy_hash := hash(JSON.stringify(economy))
	var ok := fingerprint == EXPECTED_HASH and economy_hash == S0_ECONOMY_HASH
	print("  S0 economy fingerprint %d" % economy_hash)
	print(("PASS" if ok else "FAIL") + " determinism %d money=%d pads=%d T=%.1f" % [fingerprint, sim.S.money, bought, sim.T])
	sim.dispose()
	quit(0 if ok else 1)
