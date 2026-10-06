extends SceneTree
## (1) Career bot: plays chapter 1 from a fresh save to buying the gate.
const DT := 1.0 / 30.0
const LIMIT := 3600.0

func _init() -> void:
	var sim := MooSim.new(1)
	sim.autosave = false
	var bot := MooBot.new(sim)
	var last_report := 0.0
	var bought := {}
	var t0 := Time.get_ticks_msec()
	while sim.T < LIMIT and not sim.S.done:
		bot.tick(DT)
		sim.update(DT)
		for p in sim.pads:
			if p.paid >= p.cost and not bought.has(p.name):
				bought[p.name] = sim.T
				print("  t=%6.1fs  bought %-14s ($%d)" % [sim.T, p.name, p.cost])
		if sim.T - last_report >= 120:
			last_report = sim.T
			print("  t=%6.1fs  money=%d stack=%s x=%d y=%d" % [sim.T, sim.S.money, str(sim.player.stack.n), sim.player.x, sim.player.y])
	var wall := (Time.get_ticks_msec() - t0) / 1000.0
	if sim.S.done:
		print("PASS bot_chapter1: gate bought at game time %.1fs (%.1f min), wall %.1fs" % [sim.T, sim.T / 60.0, wall])
		sim.dispose()
		quit(0)
	else:
		print("FAIL bot_chapter1: no gate after %.0fs; state=%s" % [sim.T, str(sim.state_summary())])
		sim.dispose()
		quit(1)
