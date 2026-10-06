extends SceneTree
## Fresh career to dairy/bakery gate using real movement, production and payments.
const DT := 1.0 / 30.0
const LIMIT := 7200.0
var ok := true

func expect(condition: bool, description: String) -> void:
	print("  %s %s" % ["ok" if condition else "BAD", description])
	ok = condition and ok

func _init() -> void:
	var sim := MooSim.new(7)
	sim.autosave = false
	var bot := MooBot.new(sim)
	var last_report := 0.0
	var bought := {}
	var first_gate_time := -1.0
	var t0 := Time.get_ticks_msec()
	while sim.T < LIMIT and not sim.S.done:
		bot.tick(DT)
		sim.update(DT)
		if sim.S.ch == 1 and first_gate_time < 0:
			first_gate_time = sim.T
		for p in sim.pads:
			var key: String = str(p.d) + ":" + p.name
			if p.paid >= p.cost and not bought.has(key):
				bought[key] = sim.T
				print("  t=%6.1fs bought %s ($%d)" % [sim.T, key, p.cost])
		if sim.T - last_report >= 300:
			last_report = sim.T
			print("  t=%6.1fs ch=%d money=%d stack=%s at=(%d,%d)" % [sim.T, sim.S.ch, sim.S.money, str(sim.player.stack), sim.player.x, sim.player.y])
	expect(first_gate_time > 0, "first gate opens dairy through natural play")
	expect(sim.S.ch == 1 and sim.S.done, "bakery gate completes supported career within %.0fs" % LIMIT)
	expect(sim.pads.all(func(p): return p.paid >= p.cost), "both districts' complete upgrade chains purchased")
	if sim.S.done:
		var cheese = sim.mod_by("D", 1)
		var eggs = sim.mod_by("F", 1)
		expect(cheese.sold > 0 and eggs.sold > 0, "dairy cheese and eggs sold to real customers")
		for h in sim.helpers:
			var src = sim.mod_by(h.src_id, h.d)
			var dst = sim.mod_by(h.dst_id, h.d)
			var source_matches: bool = h.field == src if src.type == "field" else h.from == src.tray
			var target_matches: bool = h.belt.m == dst if h.belt != null else h.to == (dst.hopper if dst.type == "machine" else dst.box)
			expect(source_matches and target_matches, "helper route %d:%s -> %d:%s uses district-local inventories" % [h.d, h.src_id, h.d, h.dst_id])
		# Remove player input after earning upgrades; prove complete helper chain.
		var before := {}
		for m in sim.live():
			if m.type == "counter": before[m.key] = m.sold
		sim.test_in = Vector2.ZERO
		for i in range(9000): sim.update(DT)
		for m in sim.live():
			if m.type == "counter":
				var sold: int = m.sold - before[m.key]
				expect(sold > 0, "%s sells %d unattended in 300s" % [m.key, sold])
		var ch_before: int = sim.S.ch
		var done_before: bool = sim.S.done
		expect(sim.travel_to(0), "travel back to original farm")
		expect(sim.mod_by("B", 0).n == 5, "original cows and upgrades retained")
		expect(sim.S.ch == ch_before and sim.S.done == done_before, "travel preserves career progress")
		expect(sim.travel_to(1), "travel back to purchased dairy")
		expect(not sim.travel_to(2), "unsupported bakery cannot be entered")
	else:
		print("  stalled state=%s" % str(sim.state_summary()))
	var wall := (Time.get_ticks_msec() - t0) / 1000.0
	print(("PASS" if ok else "FAIL") + " bot_chapter2: game %.1fs, wall %.1fs" % [sim.T, wall])
	sim.dispose()
	quit(0 if ok else 1)
